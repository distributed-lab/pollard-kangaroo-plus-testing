import BigInt
import AsyncAlgorithms

actor KangarooDLPSolver {
    private var table: Dictionary<BigUInt, BigUInt> = .init()
    private var taskGroup: Set<Task<(), any Error>> = .init()

    func solve(
        table: Dictionary<BigUInt, BigUInt>,
        W: BigUInt,
        pubKey: BigUInt,
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () throws -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        workersCount: Int
    ) async -> BigUInt {
        let channel = AsyncChannel<BigUInt>()
        self.table = table

        for i in 0..<workersCount {
            startWorkerTask(
                W: W,
                pubKey: pubKey,
                distinguishedRule: distinguishedRule,
                keypairGenerationRule: keypairGenerationRule,
                hashRule: hashRule,
                slog: slog,
                s: s,
                channel: channel,
                workerIndex: i
            )
        }

        var privateKey = BigUInt()
        for await value in channel {
            logger.info("[KangarooDLPSolver] Received found private key, finishing workers...")
            privateKey = value
            taskGroup.forEach { $0.cancel() }
            channel.finish()
            break
        }

        return privateKey
    }

    private func startWorkerTask(
        W: BigUInt,
        pubKey: BigUInt,
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () throws -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        channel: AsyncChannel<BigUInt>,
        workerIndex: Int
    ) {
        logger.info("[DLPSolverWorker] Started")

        let workerTask = Task {
            try await startWorker(
                W: W,
                pubKey: pubKey,
                distinguishedRule: distinguishedRule,
                keypairGenerationRule: keypairGenerationRule,
                hashRule: hashRule,
                slog: slog,
                s: s,
                channel: channel,
                workerIndex: workerIndex
            )
        }

        self.taskGroup.insert(workerTask)
    }

    nonisolated private func startWorker(
        W: BigUInt,
        pubKey: BigUInt,
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () throws -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        channel: AsyncChannel<BigUInt>,
        workerIndex: Int
    ) async throws {
        while true {
            var (wdist, w) = try keypairGenerationRule()

            if Task.isCancelled {
                logger.info("[DLPSolverWorker \(workerIndex)] Stopped")
                return
            }

            for _ in 0..<8*W {
                if Task.isCancelled {
                    logger.info("[DLPSolverWorker \(workerIndex)] Stopped")
                    return
                }

                if distinguishedRule(w) {
                    logger.info("[DLPSolverWorker \(workerIndex)] Find distinguashed element")

                    if let privateKey = await table[w] {
                        wdist = Ed25519Wrapper.scalarSub(privateKey, wdist)
                    }

                    break
                }

                let h = hashRule(w)
                wdist = Ed25519Wrapper.scalarAdd(wdist, slog[h])

                do { w = try Ed25519Wrapper.addPoints(w, s[h]) }
                catch {
                    logger.critical("[DLPSolverWorker \(workerIndex)] find add points failure, error: \(error.localizedDescription)")
                    break
                }
            }

            if let searchedPubKey = try? Ed25519Wrapper.pointFromScalarNoclamp(scalar: wdist), searchedPubKey == pubKey {
                logger.info("[DLPSolverWorker \(workerIndex)] Found private key")
                await channel.send(wdist)
                logger.info("[DLPSolverWorker \(workerIndex)] Stopped")
                return
            }
        }
    }
}
