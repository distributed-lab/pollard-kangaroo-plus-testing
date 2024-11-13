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
    private var workersCount: Int
    private var taskGroup: Set<Task<Void, Never>> = .init()

    init(workersCount: Int) {
        self.workersCount = workersCount
    }

    func run(
        W: BigUInt,
        n: Int,
        secretSize: Int,
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt]
    ) async -> Dictionary<BigUInt, BigUInt> {
        let channel = AsyncChannel<DistinguishedDot>()

        for _ in 0..<workersCount {
            startWorkerTask(
                W: W,
                distinguishedRule: distinguishedRule,
                keypairGenerationRule: keypairGenerationRule,
                hashRule: hashRule,
                slog: slog,
                s: s,
                channel: channel
            )
        }

        for await value in channel {
            kangarooTable[value.publicKey] = value.privateKey

            logger.info("kangarooTable.count: \(self.kangarooTable.count)")

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
        keypairGenerationRule: @escaping () -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        channel: AsyncChannel<DistinguishedDot>
    ) {
        logger.info("[Worker] started")

        let workerTask = Task {
            await startWorker(
                W: W,
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
        distinguishedRule: @escaping (BigUInt) -> Bool,
        keypairGenerationRule: @escaping () -> (BigUInt, BigUInt),
        hashRule: @escaping (BigUInt) -> Int,
        slog: [BigUInt],
        s: [BigUInt],
        channel: AsyncChannel<DistinguishedDot>
    ) async {
        while true {
            var (wlog, w) = keypairGenerationRule()
            if Task.isCancelled {
                logger.info("[Worker] Stopped")
                return
            }

            for _ in 0..<8*W {
                if Task.isCancelled {
                    logger.info("[Worker] Stopped")
                    return
                }

                if distinguishedRule(w) {
                    let privateKey = await self.kangarooTable[w]

                    logger.info("\(privateKey ?? BigUInt())")

                    if privateKey == nil {
                        logger.info("[Worker] found distinguashed element")

                        await channel.send(
                            DistinguishedDot(publicKey: w, privateKey: wlog)
                        )
                    }

                    break
                }

                let wHashed = hashRule(w)
                wlog = wlog + slog[wHashed]

                w = (try? Ed25519Wrapper.addPoints(w, s[wHashed])) ?? 0
                logger.info("\(w)")
//                do {
//                     }
//                catch {
//                    logger.critical("[Worker] find add points failure")
//                    break
//                }
            }

            logger.info("[Worker] no distinguashed element found")
        }
    }
}
