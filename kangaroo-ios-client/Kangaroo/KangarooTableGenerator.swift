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
    let publicKey: String
    let privateKey: String
}

actor KangarooTableGenerator {
    private var kangarooTable: Dictionary<String, String> = .init()
    private var taskGroup: Set<Task<(), any Error>> = .init()

    func run(
        W: BigUInt,
        n: Int,
        secretSize: Int,
        distinguishedRule: @escaping (String) -> Bool,
        keypairGenerationRule: @escaping () throws -> (String, String),
        hashRule: @escaping (String) -> Int,
        slog: [String],
        s: [String],
        workersCount: Int
    ) async -> Dictionary<String, String> {
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
        distinguishedRule: @escaping (String) -> Bool,
        keypairGenerationRule: @escaping () throws -> (String, String),
        hashRule: @escaping (String) -> Int,
        slog: [String],
        s: [String],
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
        distinguishedRule: @escaping (String) -> Bool,
        keypairGenerationRule: @escaping () throws -> (String, String),
        hashRule: @escaping (String) -> Int,
        slog: [String],
        s: [String],
        channel: AsyncChannel<DistinguishedDot>,
        workerIndex: Int
    ) async throws {
        while true {
            var (wlog, w) = try keypairGenerationRule()

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
                wlog = try Ed25519.scalarAdd(wlog, slog[h])
                w = try Ed25519.addPoints(w, s[h])
            }
        }
    }
}
