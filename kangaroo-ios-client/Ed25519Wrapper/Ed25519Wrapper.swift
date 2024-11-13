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
    case invalidPointLenth
}

enum Ed25519Wrapper {
    static func publicKeyFromPrivateKey(privateKey: BigUInt) throws -> BigUInt {
        let privateKeyBytes = privateKey.serialize()

        if privateKeyBytes.count != 32 {
            throw Ed25519WrapperError.invalidPointLenth
        }

        var q = [UInt8](repeating: 0, count: 32)
        crypto_scalarmult_ed25519_base_noclamp(&q, privateKeyBytes.bytes())

        if q.count != 32 {
            throw Ed25519WrapperError.invalidPointLenth
        }

        return BigUInt(Data(q))
    }

    static func addPoints(_ p: BigUInt, _ q: BigUInt) throws -> BigUInt {
        let pBytes = p.serialize().bytes()
        let qBytes = q.serialize().bytes()

        if pBytes.count != 32 || qBytes.count != 32 {
            throw Ed25519WrapperError.invalidPointLenth
        }

        var rBytes = [UInt8].init(repeating: 0, count: 32)
        crypto_core_ed25519_add(&rBytes, pBytes, qBytes)

        return BigUInt(Data(rBytes))
    }
}
