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
    let publicKey: BigInt
    let privateKey: BigInt
}

actor KangarooTableGenerator {
    private var kangarooTable: Dictionary<BigInt, BigInt> = .init()
    private var workersCount: Int
    private var taskGroup: Set<Task<Void, Never>> = .init()
    private var currentTableSize: Int = 0
    private var processingWorkers: Int = 0

    init(workersCount: Int = 16) {
        self.workersCount = workersCount
    }

    func run(
        W: BigInt,
        n: Int,
        secretSize: Int,
        distinguishedRule: @escaping (BigInt) -> Bool,
        keypairGenerationRule: @escaping () -> (BigInt, BigInt),
        hashRule: @escaping (BigInt) -> Int,
        slog: [BigInt],
        s: [BigInt]
    ) async -> Dictionary<BigInt, BigInt> {
        let channel = AsyncChannel<DistinguishedDot>()

        for i in 0..<workersCount {
            processingWorkers += 1

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
            processingWorkers -= 1
            print("Worker found a distinguashed point")

            if currentTableSize < currentTableSize {
                processingWorkers += 1

                startWorkerTask(
                    W: W,
                    distinguishedRule: distinguishedRule,
                    keypairGenerationRule: keypairGenerationRule,
                    hashRule: hashRule,
                    slog: slog,
                    s: s,
                    channel: channel
                )
            } else {
                channel.finish()
                taskGroup.forEach { $0.cancel() }
            }
        }

        return kangarooTable

    }

    private func startWorkerTask(
        W: BigInt,
        distinguishedRule: @escaping (BigInt) -> Bool,
        keypairGenerationRule: @escaping () -> (BigInt, BigInt),
        hashRule: @escaping (BigInt) -> Int,
        slog: [BigInt],
        s: [BigInt],
        channel: AsyncChannel<DistinguishedDot>
    ) {
        print("Starting a new worker")

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
        W: BigInt,
        distinguishedRule: @escaping (BigInt) -> Bool,
        keypairGenerationRule: @escaping () -> (BigInt, BigInt),
        hashRule: @escaping (BigInt) -> Int,
        slog: [BigInt],
        s: [BigInt],
        channel: AsyncChannel<DistinguishedDot>
    ) async {
        var (wlog, w) = keypairGenerationRule()

        for i in 0..<8*W {
            if Task.isCancelled { return }

            if distinguishedRule(w) {
                if let privateKey = await self.kangarooTable[w] {
                    await channel.send(
                        DistinguishedDot(publicKey: w, privateKey: wlog)
                    )
                }

                return
            }

            let wHashed = hashRule(w)
            wlog = wlog + slog[wHashed]
//            w = Ed25519.shared.addPoints(w, s[wHashed])
        }
    }
}
