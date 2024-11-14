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
    private var w: BigUInt { .init(integerLiteral: 1024) }
    private var secretSize: Int { 32 }

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

        let r = try Ed25519Wrapper.addPoints(p, q)

        let result = Data(r.serialize().reversed()).hexEncodedString()
        let expectedResult = "edc876d6831fd2105d0b4389ca2e283166469289146e2ce06faefe98b22548df"

        assert(expectedResult == result)
    }

    @Test func Gtest() async throws {
        let scalar = BigUInt("0000000000000000000000000000000000000000000000000000000000000002", radix: 16)!

        print(scalar.serialize().bytes())
        print(scalar.serialize().bytes().count)

        let basePoint = try Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: scalar)

        let result = Data(basePoint.serialize().reversed()).hexEncodedString()
        let expectedResult = "c9a3f86aae465f0e56513864510f3997561fa2c9e85ea21dc2292309f3cd6022"

        assert(expectedResult == result)
    }

    @Test func coreScalarTest() async throws {
        for _ in 0...1000 {
            var bytes = [UInt8].init(repeating: 0, count: 32)
            crypto_core_ed25519_scalar_random(&bytes)

            var q = [UInt8](repeating: 0, count: 32)
            assert(crypto_scalarmult_ed25519_base_noclamp(&q, bytes) == 0)
            assert(crypto_core_ed25519_is_valid_point(q) == 1)
        }
    }

    @Test func test31BytesLittleEndianPointFailure() async throws {
        let point: [UInt8] = [
            204,
            177,
            191,
            154,
            144,
            197,
            227,
            95,
            62,
            215,
            212,
            79,
            174,
            205,
            7,
            251,
            188,
            185,
            169,
            182,
            208,
            120,
            93,
            189,
            139,
            127,
            238,
            79,
            255,
            178,
            55
        ].reversed()

        assert(crypto_core_ed25519_is_valid_point(point) == 0)
    }

    @Test func testRandomValueGeneration() async throws {
        let kangaroo = try! Kangaroo.init(n: 400, w: BigUInt(integerLiteral: 63572), secretSize: 32)

        for _ in 0...10000 {
            let slog = BigUInt.random(limit: BigUInt.random(bits: 32 - 2)! / w)

            let s = try Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: slog)

            assert(Ed25519Wrapper.isPointOnCurve(dot: s) == true)
        }
    }
}
