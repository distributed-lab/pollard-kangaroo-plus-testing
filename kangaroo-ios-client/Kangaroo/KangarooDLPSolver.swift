import BigInt
import AsyncAlgorithms

actor KangarooDLPSolver {
    private var table: Dictionary<BigUInt, BigUInt> = .init()
    private var taskGroup: Set<Task<Void, Never>> = .init()

    func solve(
        table: Dictionary<BigUInt, BigUInt>,
        W: BigUInt,
        pubKey: BigUInt,
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        workersCount: Int
    ) async -> BigUInt {
        let channel = AsyncChannel<BigUInt>()
        self.table = table

        for _ in 0..<workersCount {
            startWorkerTask(
                W: W,
                pubKey: pubKey,
                distinguishedRule: distinguishedRule,
                keypairGenerationRule: keypairGenerationRule,
                hashRule: hashRule,
                slog: slog,
                s: s,
                channel: channel
            )
        }

        var privateKey = BigUInt()
        for await value in channel {
            logger.info("[KangarooDLPSolver] Received found private key, finishing workers...")
            taskGroup.forEach { $0.cancel() }
            channel.finish()
            privateKey = value
        }

        return privateKey
    }

    private func startWorkerTask(
        W: BigUInt,
        pubKey: BigUInt,
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        channel: AsyncChannel<BigUInt>
    ) {
        logger.info("[DLPSolverWorker] Started")

        let workerTask = Task {
            await startWorker(
                W: W,
                pubKey: pubKey,
                distinguishedRule: distinguishedRule,
                keypairGenerationRule: keypairGenerationRule,
                hashRule: hashRule,
                slog: slog,
                s: s,
                channel: channel
            )
        }

        self.taskGroup.insert(workerTask)
    }

    nonisolated private func startWorker(
        W: BigUInt,
        pubKey: BigUInt,
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        channel: AsyncChannel<BigUInt>
    ) async {
        while true {
            var (wdist, w) = keypairGenerationRule()

            if Task.isCancelled {
                logger.info("[DLPSolverWorker] Stopped")
                return
            }

            for _ in 0..<8*W {
                if Task.isCancelled {
                    logger.info("[DLPSolverWorker] Stopped")
                    return
                }

                if distinguishedRule(w) {
                    logger.info("[DLPSolverWorker] Find distinguashed element")

                    if let privateKey = await table[w] {
                        wdist = Ed25519Wrapper.scalarSub(privateKey, wdist)
                    }

                    break
                }

                let h = hashRule(w)
                wdist = wdist + slog[h]

                do { w = try Ed25519Wrapper.addPoints(w, s[h]) }
                catch {
                    logger.critical("[DLPSolverWorker] find add points failure, error: \(error.localizedDescription)")
                    break
                }
            }

            if let searchedPubKey = try? Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: wdist), searchedPubKey == pubKey {
                logger.info("[DLPSolverWorker] Found private key")
                await channel.send(wdist)
            }
        }
    }
}
