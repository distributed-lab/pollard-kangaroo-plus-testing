//
//  Kangaroo.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 01.11.2024.
//

import BigInt

/// The ED25519 kangaroo algorithm implementation
open class Kangaroo {
    /// Table size after the preprocessing stage (amount of the key values which satisfy some specific rule)
    /// This rule was described in `func isDistinguished()`
    private let n: Int

    /// Rounds per generated pub_key
    private let w: BigUInt // 4096 or 2048

    /// All avaliable private key length with `n` bits. It is calculated like: `2**n`
    private let l: BigUInt

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
        let initialL = BigUInt(integerLiteral: 2)
        self.l = initialL.power(secretSize)
        // TODO: - Make configurable
        self.r = 128
        self.slog = []
        self.s = []
        self.table = .init()

        // TODO: - Make configurable
        self.kangarooTableGenerator = .init(workersCount: 4)
        self.kangarooDLPSolver = .init()

        try self.generateRandomValues()
    }

    func generateTableParalized() async throws {
        let generatedTable = await kangarooTableGenerator
            .run(
                W: w,
                n: n,
                secretSize: secretSize,
                distinguishedRule: { [unowned self] pubKey in self.isDistinguished(pubKey: pubKey) },
                keypairGenerationRule: { [unowned self] in
                    let wlogRandomBytes = BigUInt.random(bits: secretSize) ?? 0
                    let wlogZerosPaddedData = KangarooHelpers.padWithZerosEnd(
                        input: wlogRandomBytes.serialize(),
                        length: 32
                    )
                    let wlog = BigUInt(wlogZerosPaddedData)

                    let w = (try? Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: wlog)) ?? BigUInt()
                    return (wlog, w)
                },
                hashRule: { [unowned self] pubKey in self.hash(pubKey: pubKey) },
                slog: slog,
                s: s
            )

        table = generatedTable
    }

    func solveDLP(publicKey: BigUInt) async throws -> BigUInt {
        let privateKey = await kangarooDLPSolver
            .solve(
                table: table,
                W: w,
                pubKey: publicKey,
                distinguishedRule: { [unowned self] pubKey in self.isDistinguished(pubKey: pubKey) },
                keypairGenerationRule: { [unowned self] in
                    let wdistSecureBytes = BigUInt.random(bits: secretSize) ?? 0
                    let wlogZerosPaddedData = KangarooHelpers.padWithZerosEnd(
                        input: wdistSecureBytes.serialize(),
                        length: 32
                    )
                    let wdist = BigUInt(wlogZerosPaddedData)
                    let q = (try? Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: wdist)) ?? 0
                    let w = (try? Ed25519Wrapper.addPoints(publicKey, q)) ?? 0

                    return (wdist, w)
                },
                hashRule: { [unowned self] pubKey in self.hash(pubKey: pubKey) },
                slog: slog,
                s: s,
                workersCount: 4
            )

        return privateKey
    }

    private func hash(pubKey: BigUInt) -> Int {
        return Int(pubKey & (self.r - 1))
    }

    private func isDistinguished(pubKey: BigUInt) -> Bool {
        return ((pubKey & (w - 1)) == 0)
    }

    private func generateRandomValues() throws {
        for i in 0..<self.r {
            let slogRandomBytes = BigUInt.random(limit: BigUInt.random(bits: secretSize - 2) ?? 0 / w)
            let slogZerosPaddedData = KangarooHelpers.padWithZerosEnd(
                input: slogRandomBytes.serialize(),
                length: 32
            )

            let slog = BigUInt(slogZerosPaddedData)
            let s = try Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: slog)

            self.slog.insert(slog, at: Int(i))
            self.s.insert(s, at: Int(i))
        }
    }
}
