//
//  KangarooTableGenerator.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 07.11.2024.
//

import Combine
import BigInt
import AsyncAlgorithms

fileprivate struct DistinguishedDot {
    let publicKey: BigUInt
    let privateKey: BigUInt
}

actor KangarooTableGenerator {
    private var kangarooTable: Dictionary<BigUInt, BigUInt> = .init()
    private var taskGroup: Set<Task<(), any Error>> = .init()

    func run(
        W: BigUInt,
        n: Int,
        secretSize: Int,
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () throws -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        workersCount: Int
    ) async -> Dictionary<BigUInt, BigUInt> {
        let channel = AsyncChannel<DistinguishedDot>()

        for i in 0..<workersCount {
            startWorkerTask(
                W: W,
                distinguishedRule: distinguishedRule,
                keypairGenerationRule: keypairGenerationRule,
                hashRule: hashRule,
                slog: slog,
                s: s,
                channel: channel,
                workerIndex: i
            )
        }

        for await value in channel {
            kangarooTable[value.publicKey] = value.privateKey

            logger.info("Received distinguashed element, current table size: \(self.kangarooTable.count)")

            if kangarooTable.count >= n {
                logger.info("[KangarooTableGenerator] finishing table generation..")
                channel.finish()
                taskGroup.forEach { $0.cancel() }
            }
        }

        logger.info(
            "[KangarooTablegenerator] finished table generation, the table size: \(self.kangarooTable.count)"
        )

        return kangarooTable
    }

    private func startWorkerTask(
        W: BigUInt,
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () throws -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        channel: AsyncChannel<DistinguishedDot>,
        workerIndex: Int
    ) {
        logger.info("[TableGenerationWorker] started")

        let workerTask = Task {
            try await startWorker(
                W: W,
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
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () throws -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        channel: AsyncChannel<DistinguishedDot>,
        workerIndex: Int
    ) async throws {
        while true {
            var (wlog, w) = try keypairGenerationRule()
            if Task.isCancelled {
                logger.info("[TableGenerationWorker \(workerIndex)] Stopped")
                return
            }

            for _ in 0..<8*W {
                if Task.isCancelled {
                    logger.info("[TableGenerationWorker \(workerIndex)] Stopped")
                    return
                }

                if distinguishedRule(w) {
                    let privateKey = await self.kangarooTable[w]

                    if privateKey == nil {
                        logger.info("[TableGenerationWorker \(workerIndex)] found distinguashed element")

                        await channel.send(
                            DistinguishedDot(publicKey: w, privateKey: wlog)
                        )
                    }

                    break
                }

                let h = hashRule(w)
                wlog = wlog + slog[h]

                do { w = try Ed25519Wrapper.addPoints(w, s[h]) }
                catch {
                    logger.critical("[TableGenerationWorker \(workerIndex)] find add points failure, error: \(error.localizedDescription)")
                    break
                }
            }

            logger.info("[TableGenerationWorker \(workerIndex)] no distinguashed element found")
        }
    }
}
