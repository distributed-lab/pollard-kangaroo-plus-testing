//
//  kangaroo_ios_clientTests.swift
//  kangaroo-ios-clientTests
//
//  Created by Yevhenii Serdiukov on 31.10.2024.
//

import Testing
import Foundation
import BigInt
@testable import kangaroo_ios_client

struct kangaroo_ios_clientTests {
    private var w: BigUInt { .init(integerLiteral: 1024) }
    private var secretSize: Int { 32 }

    @Test func preprocessingRandomValuesGeneration() async throws {
        for _ in 0..<1000 {
            let slog = generateSlog(secretSize: secretSize)
            print(slog.bytes(), slog.count)

            assert(slog.count == 32)
        }
    }

    /// https://asecuritysite.com/curve25519/ed?n=4
    @Test func pointAddition() async throws {
        /// 3 * G
        let p = BigUInt(
            "d4b4f5784868c3020403246717ec169ff79e26608ea126a1ab69ee77d1b16712",
            radix: 16
        )!

        /// 2 * G
        let q = BigUInt(
            "c9a3f86aae465f0e56513864510f3997561fa2c9e85ea21dc2292309f3cd6022",
            radix: 16
        )!

        let r = try Ed25519Wrapper.addPoints(p: p, q: q)
        let expectedR = "edc876d6831fd2105d0b4389ca2e283166469289146e2ce06faefe98b22548df"

        assert(expectedR == r.serialize().hexEncodedString())
    }

    private func generateSlog(secretSize: Int) -> Data {
        let zbits = BigUInt.random(bits: secretSize - 2)!
        print("zbits:", zbits.serialize().bytes())

        let limit = zbits / w
        print("limit:", limit.magnitude.serialize().bytes())

        let slog = BigUInt.random(limit: limit)
        print("slog:", slog.serialize())

        let paddedSlog = Kangaroo.KangarooHelpers.padWithZerosEnd(input: slog.serialize(), length: 32)

        return paddedSlog
    }
}
