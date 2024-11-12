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
    private var w: BigInt { .init(integerLiteral: 1024) }
    private var secretSize: Int { 32 }

    @Test func preprocessingRandomValuesGeneration() async throws {
        for _ in 0..<1000 {
            let slog = generateSlog(secretSize: secretSize)
            print(slog.bytes(), slog.count)

            assert(slog.count == 32)
        }
    }

    @Test func retrievePublicKey() async throws {
        let privateKey = Data(hex: "737415c49909403104e84fe6bcc81a8ce24e1f5e3e2a7621d2ade2da049f3ce0")!

        let publicKey = try Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: privateKey)

        print(publicKey.hexEncodedString())

//        assert(
//            publicKey
//                .hexEncodedString().lowercased() == "CCF0E1935AA16C127F3077C7B0DB7F8CE8915FFAD007C05028755A39B4805802"
//                .lowercased()
//        )
    }

    private func generateSlog(secretSize: Int) -> Data {
        let zbits = BigInt.random(bits: secretSize - 2)!
        print("zbits:", zbits.magnitude.serialize().bytes())

        let limit = zbits / w
        print("limit:", limit.magnitude.serialize().bytes())

        let slog = BigInt.random(limit: limit)
        print("slog:", slog.magnitude.serialize())

        let paddedSlog = Kangaroo.KangarooHelpers.padWithZerosEnd(input: slog.magnitude.serialize(), length: 32)

        return paddedSlog
    }
}
