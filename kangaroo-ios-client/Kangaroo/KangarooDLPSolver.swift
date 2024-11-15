import BigInt
import AsyncAlgorithms
import Foundation

struct KangarooDLPSolverReport {
    let result: BigUInt
    let statistics: KangarooStatistics
    let time: TimeInterval
}

actor KangarooDLPSolver {
    private var table: Dictionary<BigUInt, BigUInt> = .init()
    private let statistics: KangarooStatistics = KangarooStatistics()
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
    ) async -> KangarooDLPSolverReport {
        let channel = AsyncChannel<BigUInt>()
        self.table = table
        let startTime = Date.now.timeIntervalSince1970

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

        let solvingDuration = Date.now.timeIntervalSince1970 - startTime

        let report = KangarooDLPSolverReport(
            result: privateKey,
            statistics: statistics,
            time: solvingDuration
        )

        return report
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
            await statistics.trackOpEd25519ScalarMul()
            await statistics.trackOpEd25519AddPointsCount()

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
                        await statistics.trackOpEd25519ScalarSub()
                    }

                    break
                }

                let h = hashRule(w)
                wdist = Ed25519Wrapper.scalarAdd(wdist, slog[h])
                await statistics.trackOpEd25519ScalarAdd()

                do { w = try Ed25519Wrapper.addPoints(w, s[h]) }
                catch {
                    logger.critical("[DLPSolverWorker \(workerIndex)] find add points failure, error: \(error.localizedDescription)")
                    break
                }
            }

            await statistics.trackOpEd25519ScalarMul()
            if let searchedPubKey = try? Ed25519Wrapper.pointFromScalarNoclamp(scalar: wdist), searchedPubKey == pubKey {
                logger.info("[DLPSolverWorker \(workerIndex)] Found private key")
                await channel.send(wdist)
                logger.info("[DLPSolverWorker \(workerIndex)] Stopped")
                return
            }
        }
    }
}
