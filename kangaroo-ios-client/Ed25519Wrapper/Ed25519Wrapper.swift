//
//  Ed25519Wrapper.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 12.11.2024.
//

import Foundation

enum Ed25519WrapperError: LocalizedError {
    case badPrivateKeyLength
    case failedToRetrivePubKey

//    var errorDescription: String? {
//        switch self {
//        case .badPrivateKeyLength:
//            return "Bad private key length"
//        }
//    }
}

enum Ed25519Wrapper {
    static func publicKeyFromPrivateKey(privateKey: Data) throws -> Data {
        if privateKey.count != 32 {
            throw Ed25519WrapperError.badPrivateKeyLength
        }
        var pointA = ge_p3()

        ge_scalarmult_base(&pointA, privateKey.bytes())

        var publicKey = [UInt8](repeating: 0, count: 32)
        ge_p3_tobytes(&publicKey, &pointA)


        if publicKey.count != 32 {
            throw Ed25519WrapperError.failedToRetrivePubKey
        }

        return Data(publicKey)
    }
}
