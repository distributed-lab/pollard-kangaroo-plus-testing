//
//  Kangaroo.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 01.11.2024.
//

import CryptoKit
import BigInt

public enum Ed25519Params {
    /// Field module
    static let p = BigInt("7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed", radix: 16)!
}

/// The ED25519 kangaroo algorithm implementation
open class Kangaroo {
    /// Table size after the preprocessing stage (amount of the key values which satisfy some specific rule)
    /// This rule was described in `func isDistinguished()`
    private let n: Int

    /// Rounds per generated pub_key
    private let w: BigInt // 4096 or 2048

    /// All avaliable private key length with `n` bits. It is calculated like: `2**n`
    private let l: BigInt

    /// Length of the generated arrays of s and slogs
    private let r: BigInt

    /// Generated public keys with the array length is equal to the `r`.
    /// In fact it is just random values for the further DLP  solving.
    private var s: [BigInt]

    /// Generated private keys with the array length is equal to the `r`.
    /// In fact it is just random points for the further DLP  solving.
    private var slog: [BigInt]

    /// Amount of randomly generated bits of some secret. All the other bits are `zeros` to 32 bytes because of eliptic curve context.
    private let secretSize: Int

    /// Generated table after preprocessing stage. There are relation like key: public_key -> value: private_key
    private var table: Dictionary<BigInt, BigInt>

    private var kangarooTableGenerator: KangarooTableGenerator

    init(n: Int, w: BigInt, secretSize: Int) throws {
        self.n = n
        self.w = w
        self.secretSize = secretSize
        let initialL = BigInt(integerLiteral: 2)
        self.l = initialL.power(secretSize)
        // TODO: - Make configurable
        self.r = 128
        self.slog = []
        self.s = []
        self.table = .init()

        // TODO: - Make configurable
        self.kangarooTableGenerator = .init(workersCount: 1)

        try self.generateRandomValues()
    }

    func generateTableParalized() async throws {
        let generatedTable = await kangarooTableGenerator
            .run(
                W: w,
                n: n,
                secretSize: secretSize,
                distinguishedRule: { [unowned self] pubKey in self.isDistinguished(pubKey: pubKey) },
                keypairGenerationRule: { [unowned self] in (BigInt(), BigInt()) },
                hashRule: { [unowned self] pubKey in self.hash(pubKey: pubKey) },
                slog: slog,
                s: s
            )

        table = generatedTable
    }

    private func hash(pubKey: BigInt) -> Int {
        return Int(pubKey & (self.r - 1))
    }

    private func isDistinguished(pubKey: BigInt) -> Bool {
        return ((pubKey & (w - 1)) == 0)
    }

    private func generateRandomValues() throws {
        for i in 0..<self.r {
            let slog = BigInt.random(limit: BigInt.random(bits: secretSize - 2) ?? 0 / w)
            let slogZerosPaddedData = KangarooHelpers.padWithZerosEnd(input: slog.magnitude.serialize(), length: 32)
            let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: slogZerosPaddedData)
            let s = BigInt(privateKey.publicKey.rawRepresentation)

            self.slog.insert(
                BigInt(
                    sign: slog.sign,
                    magnitude: BigUInt(slogZerosPaddedData)
                ),
                at: Int(i)
            )
            self.s.insert(s, at: Int(i))
        }
    }
}
