import BigInt
import AsyncAlgorithms
import Foundation

struct KangarooDLPSolverReport {
    let result: String
    let statistics: KangarooStatistics
    let time: TimeInterval
}

enum KangarooDLPSolverWorkerReport {
    case privateKey(String, KangarooStatistics?)
    case stats(KangarooStatistics?)
}

class KangarooDLPSolver {
    func solve(
        table: Dictionary<String, String>,
        W: BigUInt,
        pubKey: String,
        distinguishedRule: @escaping (String) -> Bool,
        keypairGenerationRule: @escaping () throws -> (String, String),
        hashRule: @escaping (String) -> Int,
        slog: [String],
        s: [String],
        workersCount: Int,
        enableStatistics: Bool
    ) async throws -> KangarooDLPSolverReport {
        let channel = AsyncChannel<KangarooDLPSolverWorkerReport>()

        let report = try await withThrowingTaskGroup(
            of: KangarooDLPSolverWorkerReport?.self,
            returning: KangarooDLPSolverReport.self
        ) { taskGroup in
            let startTime = Date.now.timeIntervalSince1970

            for i in 0..<workersCount {
                taskGroup.addTask { [weak self] in
                    logger.log("[KangarooDLPSolverWorker \(i)] Started")
                    let result = try await self?.startWorker(
                        W: W,
                        pubKey: pubKey,
                        distinguishedRule: distinguishedRule,
                        keypairGenerationRule: keypairGenerationRule,
                        hashRule: hashRule,
                        slog: slog,
                        s: s,
                        channel: channel,
                        table: table,
                        workerIndex: i,
                        enableStatistics: enableStatistics
                    )
                    logger.log("[KangarooDLPSolverWorker \(i)] Finished execution")
                    return result
                }
            }

            var privateKey = String()
            var statistics = KangarooStatistics()
            for try await value in taskGroup {
                if case let .privateKey(sk, stat)  = value {
                    privateKey = sk
                    if let stat = stat {
                        statistics += stat
                    }
                    taskGroup.cancelAll()
                }

                if case let .stats(stat) = value {
                    if let stat = stat {
                        statistics += stat
                    }
                }
            }

            let solvingDuration = Date.now.timeIntervalSince1970 - startTime

            return KangarooDLPSolverReport(
                result: privateKey,
                statistics: statistics,
                time: solvingDuration
            )
        }

        return report
    }

    private func startWorker(
        W: BigUInt,
        pubKey: String,
        distinguishedRule: @escaping (String) -> Bool,
        keypairGenerationRule: @escaping () throws -> (String, String),
        hashRule: @escaping (String) -> Int,
        slog: [String],
        s: [String],
        channel: AsyncChannel<KangarooDLPSolverWorkerReport>,
        table: Dictionary<String, String>,
        workerIndex: Int,
        enableStatistics: Bool
    ) async throws -> KangarooDLPSolverWorkerReport {
        let statistics: KangarooStatistics? = enableStatistics ? KangarooStatistics() : nil

        while true {
            var (wdist, w) = try keypairGenerationRule()
            statistics?.trackOpEd25519ScalarMul()
            statistics?.trackOpEd25519AddPointsCount()

            for _ in 0..<8*W {
                if Task.isCancelled {
                    return .stats(statistics)
                }

                if distinguishedRule(w) {
                    logger.info("[DLPSolverWorker \(workerIndex)] Find distinguashed element")

                    if let privateKey = table[w] {
                        wdist = try Ed25519.scalarSub(privateKey, wdist)
                        statistics?.trackOpEd25519ScalarSub()
                    }

                    break
                }

                let h = hashRule(w)
                wdist = try Ed25519.scalarAdd(wdist, slog[h])
                statistics?.trackOpEd25519ScalarAdd()

                w = try Ed25519.addPoints(w, s[h])
                statistics?.trackOpEd25519AddPointsCount()
            }

            let searchedPubKey = try Ed25519.pointFromScalarNoclamp(wdist)
            statistics?.trackOpEd25519ScalarMul()

            if searchedPubKey == pubKey {
                logger.info("[DLPSolverWorker \(workerIndex)] Found private key")
                return .privateKey(wdist, statistics)
            }
        }
    }
}
