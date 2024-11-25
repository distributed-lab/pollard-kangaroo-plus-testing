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
    case failedToDecodeHex

    var errorDescription: String? {
        switch self {
        case .invalidPointLenth(let debugLength):
            return "Point bytes count required to be 32, but received: \(debugLength)"
        case .ed25519InvalidPoint:
            return "Received point that is not contains in Ed25519"
        case .failedToDecodeHex:
            return "Failed"
        }
    }
}

enum Ed25519 {
    static func pointFromScalarNoclamp(_ scalar: String) throws -> String {
        guard let scalarBytes = Data(hex: scalar)?.bytes().reversed() else {
            throw Ed25519WrapperError.failedToDecodeHex
        }

        let q = try Core.pointFromScalarNoclamp(scalar: Array(scalarBytes))
        return Data(q).hexEncodedString()
    }

    static func addPoints(_ p: String, _ q: String) throws -> String {
        guard let pBytes = Data(hex: p)?.bytes(), let qBytes = Data(hex: q)?.bytes() else {
            throw Ed25519WrapperError.failedToDecodeHex
        }

        let rBytes = try Core.addPoints(pBytes, qBytes)
        return Data(rBytes).hexEncodedString()
    }

    static func scalarAdd(_ x: String, _ y: String) throws -> String {
        guard let xBytes = Data(hex: x)?.bytes().reversed(), let yBytes = Data(hex: y)?.bytes().reversed() else {
            throw Ed25519WrapperError.failedToDecodeHex
        }

        let result = Core.scalarAdd(Array(xBytes), Array(yBytes))
        return Data(Array(result.reversed())).hexEncodedString()
    }

    static func scalarSub(_ x: String, _ y: String) throws -> String {
        guard let xBytes = Data(hex: x)?.bytes().reversed(), let yBytes = Data(hex: y)?.bytes().reversed() else {
            throw Ed25519WrapperError.failedToDecodeHex
        }

        let result = Core.scalarSub(Array(xBytes), Array(yBytes))
        return Data(Array(result.reversed())).hexEncodedString()
    }

    enum Core {
        static func pointFromScalarNoclamp(scalar: [UInt8]) throws -> [UInt8] {
            var scalar = scalar
            padEndZerosIfNeeded(elem: &scalar)

            var q = [UInt8](repeating: 0, count: 32)
            crypto_scalarmult_ed25519_base_noclamp(&q, scalar)

            if q.count != 32 {
                throw Ed25519WrapperError.invalidPointLenth(length: [q.count])
            }

            if crypto_core_ed25519_is_valid_point(q) != 1 {
                throw Ed25519WrapperError.ed25519InvalidPoint
            }

            return q
        }

        static func scalarSub(_ x: [UInt8], _ y: [UInt8]) -> [UInt8] {
            var x = x
            var y = y

            padEndZerosIfNeeded(elem: &x)
            padEndZerosIfNeeded(elem: &y)

            var z = [UInt8](repeating: 0, count: 32)
            crypto_core_ed25519_scalar_sub(&z, x, y)

            return z
        }

        static func scalarAdd(_ x: [UInt8], _ y: [UInt8]) -> [UInt8] {
            var x = x
            var y = y

            padEndZerosIfNeeded(elem: &x)
            padEndZerosIfNeeded(elem: &y)

            var z = [UInt8](repeating: 0, count: 32)
            crypto_core_ed25519_scalar_add(&z, x, y)

            return z
        }

        static func addPoints(_ p: [UInt8], _ q: [UInt8]) throws -> [UInt8] {
            var p = p
            var q = q

            padEndZerosIfNeeded(elem: &p)
            padEndZerosIfNeeded(elem: &q)

            if p.count != 32 || q.count != 32 {
                throw Ed25519WrapperError.invalidPointLenth(length: [p.count, q.count])
            }

            var r = [UInt8].init(repeating: 0, count: 32)
            crypto_core_ed25519_add(&r, p, q)

            if r.count != 32 {
                throw Ed25519WrapperError.invalidPointLenth(length: [r.count])
            }

            if crypto_core_ed25519_is_valid_point(r) != 1 {
                throw Ed25519WrapperError.ed25519InvalidPoint
            }

            return r
        }

        static private func padEndZerosIfNeeded(elem: inout [UInt8]) {
            while elem.count < 32 {
                elem.append(0)
            }
        }
    }
}
