//
//  Ed25519Wrapper.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 12.11.2024.
//

import Foundation
import BigInt
import Clibsodium

enum Ed25519WrapperError: LocalizedError {
    case invalidPointLenth(length: [Int])
    case ed25519InvalidPoint

    var errorDescription: String? {
        switch self {
        case .invalidPointLenth(let debugLength):
            return "Point bytes count required to be 32, but received: \(debugLength)"
        case .ed25519InvalidPoint:
            return "Received point that is not contains in Ed25519"
        }
    }
}

enum Ed25519Wrapper {
    static func publicKeyFromPrivateKey(privateKey: BigUInt) throws -> BigUInt {
        var privateKeyBytes = Array(privateKey.serialize().bytes().reversed())

        padEndZerosIfNeeded(elem: &privateKeyBytes)

        var q = [UInt8](repeating: 0, count: 32)
        crypto_scalarmult_ed25519_base_noclamp(&q, privateKeyBytes)

        if q.count != 32 {
            throw Ed25519WrapperError.invalidPointLenth(length: [q.count])
        }

        if crypto_core_ed25519_is_valid_point(q) != 1 {
            throw Ed25519WrapperError.ed25519InvalidPoint
        }

        return BigUInt(Data(q.reversed()))
    }

    static func scalarSub(_ x: BigUInt, _ y: BigUInt) -> BigUInt {
        var xBytes = Array(x.serialize().bytes().reversed())
        var yBytes = Array(y.serialize().bytes().reversed())

        padEndZerosIfNeeded(elem: &xBytes)
        padEndZerosIfNeeded(elem: &yBytes)

        var zBytes = [UInt8](repeating: 0, count: 32)
        crypto_core_ed25519_scalar_sub(&zBytes, xBytes, yBytes)

        return BigUInt(Data(zBytes.reversed()))
    }

    static func isPointOnCurve(dot: BigUInt) -> Bool {
        var dotBytes = Array(dot.serialize().bytes().reversed())
        padEndZerosIfNeeded(elem: &dotBytes)
        return crypto_core_ed25519_is_valid_point(dotBytes) == 1
    }

    static func addPoints(_ p: BigUInt, _ q: BigUInt) throws -> BigUInt {
        var pBytes = Array(p.serialize().bytes().reversed())
        var qBytes = Array(q.serialize().bytes().reversed())

        padEndZerosIfNeeded(elem: &pBytes)
        padEndZerosIfNeeded(elem: &qBytes)

        if pBytes.count != 32 || qBytes.count != 32 {
            throw Ed25519WrapperError.invalidPointLenth(length: [pBytes.count, qBytes.count])
        }

        var rBytes = [UInt8].init(repeating: 0, count: 32)
        crypto_core_ed25519_add(&rBytes, pBytes, qBytes)

        if rBytes.count != 32 {
            throw Ed25519WrapperError.invalidPointLenth(length: [rBytes.count])
        }

        if crypto_core_ed25519_is_valid_point(rBytes) != 1 {
            throw Ed25519WrapperError.ed25519InvalidPoint
        }

        return BigUInt(Data(rBytes.reversed()))
    }

    static func eq(_ p: BigUInt, _ q: BigUInt) -> Bool {
        var pBytes = Array(p.serialize().bytes().reversed())
        var qBytes = Array(q.serialize().bytes().reversed())

        padEndZerosIfNeeded(elem: &pBytes)
        padEndZerosIfNeeded(elem: &qBytes)

        return pBytes == qBytes || pBytes == qBytes.reversed()
    }

    static private func padEndZerosIfNeeded(elem: inout [UInt8]) {
        while elem.count < 32 {
            elem.append(0)
        }
    }
}
