//
//  kangaroo_ios_clientTests.swift
//  kangaroo-ios-clientTests
//
//  Created by Yevhenii Serdiukov on 31.10.2024.
//

import Testing
import Foundation
import BigInt
import Clibsodium

@testable import kangaroo_ios_client

struct kangaroo_ios_clientTests {
    @Test func basePointScalarMulNoclamp() async throws {
        let scalar = "b4333fee"
        let expected = "b4e635be6264a7ffd41598d9175835bc695da844c9c563beed23f9d7f9088000"
        let result = try Ed25519.pointFromScalarNoclamp(scalar)

        assert(result == expected)
    }

    @Test func pointAddition() async throws {
        let p = "c9a3f86aae465f0e56513864510f3997561fa2c9e85ea21dc2292309f3cd6022"
        let q = "5866666666666666666666666666666666666666666666666666666666666666"
        let expectedResult = "d4b4f5784868c3020403246717ec169ff79e26608ea126a1ab69ee77d1b16712"

        let result = try Ed25519.addPoints(p, q)
        assert(result == expectedResult)
    }

    @Test func output_w512_n1600_secret32_r64() async throws {
        var reports = [KangarooDLPSolverReport]()

        let secretSize = 48
        let workersCount = ProcessInfo.processInfo.processorCount

        for _ in 0..<300 {
            let publicKey = try getPublicKey(secretSize: secretSize)
            let kangaroo = try Kangaroo(outputFileName: "output_512_1600_32_64")
            let report = try await kangaroo.solveDLP(
                publicKey: publicKey,
                workersCount: workersCount,
                enableStatistics: true
            )

            reports.append(report)
        }

        printReport(
            reports: reports,
            name: "output_w512_n1600_secret32_r64",
            secretSize: secretSize,
            workersCount: workersCount
        )
    }

    @Test func output_w1024_n1600_secret32_r64() async throws {
        var reports = [KangarooDLPSolverReport]()

        let secretSize = 32
        let workersCount = ProcessInfo.processInfo.processorCount

        for _ in 0..<300 {
            let publicKey = try getPublicKey(secretSize: secretSize)
            let kangaroo = try Kangaroo(outputFileName: "output_1024_1600_32_64")
            let report = try await kangaroo.solveDLP(
                publicKey: publicKey,
                workersCount: workersCount,
                enableStatistics: true
            )

            reports.append(report)
        }

        printReport(
            reports: reports,
            name: "output_1024_1600_32_64",
            secretSize: secretSize,
            workersCount: workersCount
        )
    }

    @Test func output_w2048_n1600_secret32_r64() async throws {
        var reports = [KangarooDLPSolverReport]()

        let secretSize = 32
        let workersCount = ProcessInfo.processInfo.processorCount

        for _ in 0..<300 {
            let publicKey = try getPublicKey(secretSize: secretSize)
            let kangaroo = try Kangaroo(outputFileName: "output_2048_1600_32_64")
            let report = try await kangaroo.solveDLP(
                publicKey: publicKey,
                workersCount: workersCount,
                enableStatistics: true
            )

            reports.append(report)
        }

        printReport(
            reports: reports,
            name: "output_w2048_n1600_secret32_r64",
            secretSize: secretSize,
            workersCount: workersCount
        )
    }

    @Test func output_w2048_n4000_secret32_r64() async throws {
        var reports = [KangarooDLPSolverReport]()

        let secretSize = 32
        let workersCount = ProcessInfo.processInfo.processorCount

        for _ in 0..<100 {
            let publicKey = try getPublicKey(secretSize: secretSize)
            let kangaroo = try Kangaroo(outputFileName: "output_2048_4000_32_64")
            let report = try await kangaroo.solveDLP(
                publicKey: publicKey,
                workersCount: workersCount,
                enableStatistics: true
            )

            reports.append(report)
        }

        printReport(
            reports: reports,
            name: "output_w2048_n4000_secret32_r64",
            secretSize: secretSize,
            workersCount: workersCount
        )
    }

    @Test func output_w4096_n1600_secret32_r64() async throws {
        var reports = [KangarooDLPSolverReport]()

        let secretSize = 32
        let workersCount = ProcessInfo.processInfo.processorCount

        for _ in 0..<300 {
            let publicKey = try getPublicKey(secretSize: secretSize)
            let kangaroo = try Kangaroo(outputFileName: "output_4096_1600_32_64")
            let report = try await kangaroo.solveDLP(
                publicKey: publicKey,
                workersCount: workersCount,
                enableStatistics: true
            )

            reports.append(report)
        }

        printReport(
            reports: reports,
            name: "output_w4096_n1600_secret32_r64",
            secretSize: secretSize,
            workersCount: workersCount
        )
    }

    @Test func output_w8192_n1600_secret32_r64() async throws {
        var reports = [KangarooDLPSolverReport]()

        let secretSize = 32
        let workersCount = ProcessInfo.processInfo.processorCount

        for _ in 0..<300 {
            let publicKey = try getPublicKey(secretSize: secretSize)
            let kangaroo = try Kangaroo(outputFileName: "output_8192_1600_32_64")
            let report = try await kangaroo.solveDLP(
                publicKey: publicKey,
                workersCount: workersCount,
                enableStatistics: true
            )

            reports.append(report)
        }

        printReport(
            reports: reports,
            name: "output_w8192_n1600_secret32_r64",
            secretSize: secretSize,
            workersCount: workersCount
        )
    }

    @Test func output_w32768_n100_secret32_r64() async throws {
        var reports = [KangarooDLPSolverReport]()

        let secretSize = 32
        let workersCount = ProcessInfo.processInfo.processorCount

        for _ in 0..<20 {
            let publicKey = try getPublicKey(secretSize: secretSize)
            let kangaroo = try Kangaroo(outputFileName: "output_32768_100_32_64")
            let report = try await kangaroo.solveDLP(
                publicKey: publicKey,
                workersCount: workersCount,
                enableStatistics: true
            )

            reports.append(report)
        }

        printReport(
            reports: reports,
            name: "output_w32768_n100_secret32_r64",
            secretSize: secretSize,
            workersCount: workersCount
        )
    }

    @Test func output_w65536_n40000_secret48_r128() async throws {
        var reports = [KangarooDLPSolverReport]()

        let secretSize = 48
        let workersCount = ProcessInfo.processInfo.processorCount

        for _ in 0..<20 {
            let publicKey = try getPublicKey(secretSize: secretSize)
            let kangaroo = try Kangaroo(outputFileName: "output_65536_40000_48_128")
            let report = try await kangaroo.solveDLP(
                publicKey: publicKey,
                workersCount: workersCount,
                enableStatistics: true
            )

            reports.append(report)
        }

        printReport(
            reports: reports,
            name: "output_w65536_n40000_secret48_r128",
            secretSize: secretSize,
            workersCount: workersCount
        )
    }

    @Test func output_w262144_n40000_secret48_r128() async throws {
        var reports = [KangarooDLPSolverReport]()

        let secretSize = 48
        let workersCount = ProcessInfo.processInfo.processorCount

        for _ in 0..<20 {
            let publicKey = try getPublicKey(secretSize: secretSize)
            let kangaroo = try Kangaroo(outputFileName: "output_262144_40000_48_128")
            let report = try await kangaroo.solveDLP(
                publicKey: publicKey,
                workersCount: workersCount,
                enableStatistics: true
            )

            reports.append(report)
        }

        printReport(
            reports: reports,
            name: "output_w262144_n40000_secret48_r128",
            secretSize: secretSize,
            workersCount: workersCount
        )
    }

    private func getPublicKey(secretSize: Int) throws -> String {
        let privateKey = BigUInt.random(bits: secretSize)
        let hexPrivateKey = privateKey.serialize().hexEncodedString()
        let publicKey = try Ed25519.pointFromScalarNoclamp(hexPrivateKey)

        return publicKey
    }

    private func printReport(reports: [KangarooDLPSolverReport], name: String, secretSize: Int, workersCount: Int) {
        print("--BEGIN-- \(name)")
        print("Itterations count: \(reports.count)")
        print("Secret size: \(secretSize)")
        print("Workers count: \(workersCount)")
        print("The lower dlp solving time:", reports.map { $0.time }.min()!)
        print("The higher dlp solving time:", reports.map { $0.time }.max()!)
        print("An Avarage dlp solving time:", reports.map { $0.time }.reduce(0,+) / Double(reports.count))
        print("Avarage main EC operations count:", reports.map { Double($0.statistics.ed25519MainOpsCount()) }.reduce(0,+) / Double(reports.count))
        print("Avarage full EC operations count:", reports.map { Double($0.statistics.ed25519FullOpsCount()) }.reduce(0,+) / Double(reports.count))
        print("--END-- \(name)")
    }

}
