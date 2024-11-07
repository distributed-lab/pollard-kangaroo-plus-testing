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
        self.kangarooTableGenerator = .init(workersCount: 16)

        try self.generateRandomValues()
    }

    func generateTableParalized() async throws {
        let generatedTable = await kangarooTableGenerator
            .run(
                W: w,
                n: n,
                secretSize: secretSize,
                distinguishedRule: { [unowned self] _ in self.isDistinguished() },
                keypairGenerationRule: { [unowned self] in try! generateKeypair(secretSize: secretSize) },
                hashRule: { [unowned self] _ in self.hash() },
                slog: slog,
                s: s
            )

        table = generatedTable
    }

    private func hash() -> Int {
        return 1
    }

    private func isDistinguished() -> Bool {
        true
    }

    private func generateRandomValues() throws {
        for i in 0..<self.r {
            let (slog, s) = try generateKeypair(secretSize: self.secretSize - 2)
            self.slog.insert(BigInt(slog), at: Int(i))
            self.s.insert(s, at: Int(i))
        }
    }

    private func generateKeypair(secretSize: Int) throws -> (privateKey: BigInt, publicKey: BigInt) {
        let slog = KangarooHelpers.generateRandomBigInt(bitSize: secretSize - 2) / w
        let slogZerosPadded = KangarooHelpers.padWithZerosEnd(input: slog.serialize(), length: 32)
        let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: slogZerosPadded)
        let s = BigInt(privateKey.publicKey.rawRepresentation)
        return (BigInt(slogZerosPadded), s)
    }
}
