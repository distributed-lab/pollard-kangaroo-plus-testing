//
//  Kangaroo.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 01.11.2024.
//

import BigInt
import Foundation

/// The ED25519 kangaroo algorithm implementation
open class Kangaroo {
    /// Table size after the preprocessing stage (amount of the key values which satisfy some specific rule)
    /// This rule was described in `func isDistinguished()`
    private let n: Int

    /// Rounds per generated pub_key
    private let w: BigUInt

    /// Length of the generated arrays of s and slogs
    private let r: BigUInt

    /// Generated public keys with the array length is equal to the `r`.
    /// In fact it is just random values for the further DLP  solving.
    private var s: [BigUInt]

    /// Generated private keys with the array length is equal to the `r`.
    /// In fact it is just random points for the further DLP  solving.
    private var slog: [BigUInt]

    /// Amount of randomly generated bits of some secret. All the other bits are `zeros` to 32 bytes because of eliptic curve context.
    private let secretSize: Int

    /// Generated table after preprocessing stage. There are relation like key: public_key -> value: private_key
    private var table: Dictionary<BigUInt, BigUInt>

    /// Kangaroo table generator
    private var kangarooTableGenerator: KangarooTableGenerator

    private var kangarooDLPSolver: KangarooDLPSolver

    init(n: Int, w: BigUInt, secretSize: Int) throws {
        self.n = n
        self.w = w
        self.secretSize = secretSize
        // TODO: - Make configurable
        self.r = 128
        self.slog = []
        self.s = []
        self.table = .init()

        // TODO: - Make configurable
        self.kangarooTableGenerator = .init()
        self.kangarooDLPSolver = .init()

        try self.generateKeypairs()
    }

    func generateTableParalized(workersCount: Int) async throws {
        let generatedTable = await kangarooTableGenerator
            .run(
                W: w,
                n: n,
                secretSize: secretSize,
                distinguishedRule: isDistinguished(pubKey:),
                keypairGenerationRule: { [unowned self] in
                    let wlog = BigUInt.random(bits: secretSize)
                    let w = try! Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: wlog)
                    return (wlog, w)
                },
                hashRule: hash(pubKey:),
                slog: slog,
                s: s,
                workersCount: workersCount
            )

        table = generatedTable
    }

    func solveDLP(publicKey: BigUInt, workersCount: Int) async throws -> BigUInt {
        let privateKey = await kangarooDLPSolver
            .solve(
                table: table,
                W: w,
                pubKey: publicKey,
                distinguishedRule: isDistinguished(pubKey:),
                keypairGenerationRule: { [unowned self] in
                    let wdist = BigUInt.random(bits: secretSize - 8)
                    let q = try Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: wdist)
                    let w = try Ed25519Wrapper.addPoints(publicKey, q)
                    return (wdist, w)
                },
                hashRule: hash(pubKey:),
                slog: slog,
                s: s,
                workersCount: workersCount
            )

        return privateKey
    }

    private func hash(pubKey: BigUInt) -> Int {
        return Int(pubKey & (self.r - 1))
    }

    private func isDistinguished(pubKey: BigUInt) -> Bool {
        return ((pubKey & (w - 1)) == 0)
    }

    private func generateKeypairs() throws {
        for i in 0..<self.r {
            let slog = BigUInt.random(limit: BigUInt.random(bits: secretSize - 2) / w)
            let s = try Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: slog)

            self.slog.insert(slog, at: Int(i))
            self.s.insert(s, at: Int(i))
        }
    }

}
