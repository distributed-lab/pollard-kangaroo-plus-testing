import BigInt
import AsyncAlgorithms
import Foundation

struct KangarooDLPSolverReport {
    let result: String
    let statistics: KangarooStatistics
    let time: TimeInterval
}

actor KangarooDLPSolver {
    private let statistics: KangarooStatistics = KangarooStatistics()
    private var taskGroup: Set<Task<(), any Error>> = .init()

    func solve(
        table: Dictionary<String, String>,
        W: BigUInt,
        pubKey: String,
        distinguishedRule: @escaping (String) -> Bool,
        keypairGenerationRule: @escaping () throws -> (String, String),
        hashRule: @escaping (String) -> Int,
        slog: [String],
        s: [String],
        workersCount: Int
    ) async -> KangarooDLPSolverReport {
        let channel = AsyncChannel<String>()
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
                table: table,
                workerIndex: i
            )
        }

        var privateKey = String()
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
        pubKey: String,
        distinguishedRule: @escaping (String) -> Bool,
        keypairGenerationRule: @escaping () throws -> (String, String),
        hashRule: @escaping (String) -> Int,
        slog: [String],
        s: [String],
        channel: AsyncChannel<String>,
        table: Dictionary<String, String>,
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
                table: table,
                workerIndex: workerIndex
            )
        }

        self.taskGroup.insert(workerTask)
    }

    nonisolated private func startWorker(
        W: BigUInt,
        pubKey: String,
        distinguishedRule: @escaping (String) -> Bool,
        keypairGenerationRule: @escaping () throws -> (String, String),
        hashRule: @escaping (String) -> Int,
        slog: [String],
        s: [String],
        channel: AsyncChannel<String>,
        table: Dictionary<String, String>,        workerIndex: Int
    ) async throws {
        while true {
            var (wdist, w) = try keypairGenerationRule()
//            await statistics.trackOpEd25519ScalarMul()
//            await statistics.trackOpEd25519AddPointsCount()

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

                    if let privateKey = table[w] {
                        wdist = try Ed25519.scalarSub(privateKey, wdist)
                        await statistics.trackOpEd25519ScalarSub()
                    }

                    break
                }

                let h = hashRule(w)

                wdist = try Ed25519.scalarAdd(wdist, slog[h])
//                await statistics.trackOpEd25519ScalarAdd()

                do {
                    w = try Ed25519.addPoints(w, s[h])
                }
                catch {
                    logger.critical("[DLPSolverWorker \(workerIndex)] find add points failure, error: \(error.localizedDescription)")
                    break
                }
            }

//            await statistics.trackOpEd25519ScalarMul()
            let searchedPubKey = try Ed25519.pointFromScalarNoclamp(wdist)
            if searchedPubKey == pubKey {
                logger.info("[DLPSolverWorker \(workerIndex)] Found private key")
                await channel.send(wdist)
                logger.info("[DLPSolverWorker \(workerIndex)] Stopped")
                return
            }
        }
    }
}
