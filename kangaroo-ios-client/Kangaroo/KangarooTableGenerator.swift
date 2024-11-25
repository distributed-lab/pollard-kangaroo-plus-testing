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
    let publicKey: [UInt8]
    let privateKey: [UInt8]
}

actor KangarooTableGenerator {
    private var kangarooTable: Dictionary<[UInt8], [UInt8]> = .init()
    private var taskGroup: Set<Task<(), any Error>> = .init()

    func run(
        W: BigUInt,
        n: Int,
        secretSize: Int,
        distinguishedRule: @escaping ([UInt8]) -> Bool,
        keypairGenerationRule: @escaping () throws -> ([UInt8], [UInt8]),
        hashRule: @escaping ([UInt8]) -> Int,
        slog: [[UInt8]],
        s: [[UInt8]],
        workersCount: Int
    ) async -> Dictionary<[UInt8], [UInt8]> {
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
        distinguishedRule: @escaping ([UInt8]) -> Bool,
        keypairGenerationRule: @escaping () throws -> ([UInt8], [UInt8]),
        hashRule: @escaping ([UInt8]) -> Int,
        slog: [[UInt8]],
        s: [[UInt8]],
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
        distinguishedRule: @escaping ([UInt8]) -> Bool,
        keypairGenerationRule: @escaping () throws -> ([UInt8], [UInt8]),
        hashRule: @escaping ([UInt8]) -> Int,
        slog: [[UInt8]],
        s: [[UInt8]],
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
                wlog = Ed25519.Core.scalarAdd(wlog, slog[h])
                w = try Ed25519.Core.addPoints(w, s[h])
            }
        }
    }
}
