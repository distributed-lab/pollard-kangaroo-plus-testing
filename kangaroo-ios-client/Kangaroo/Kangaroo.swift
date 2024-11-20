//
//  Kangaroo.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 01.11.2024.
//

import BigInt
import Foundation

private let wIndex = 1
private let nIndex = 2
private let secretSizeIndex = 3
private let rIndex = 4

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

    init(n: Int, w: BigUInt, secretSize: Int, r: BigUInt) throws {
        self.n = n
        self.w = w
        self.secretSize = secretSize
        // TODO: - Make configurable
        self.r = r
        self.slog = []
        self.s = []
        self.table = .init()

        // TODO: - Make configurable
        self.kangarooTableGenerator = .init()
        self.kangarooDLPSolver = .init()

        try self.generateKeypairs()
    }

    init(outputFileName: String) throws {
        let fileURL = Bundle.main.url(forResource: outputFileName, withExtension: "json")!
        let parameters = fileURL.relativePath.split(separator: "_").map { String($0) }
        let jsonData = try! Data(contentsOf: fileURL)
        let dictionary = (try JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] ?? [:]

        self.table = .init()
        self.kangarooTableGenerator = .init()
        self.kangarooDLPSolver = .init()
        self.w = BigUInt(parameters[wIndex], radix: 10)!
        self.n = Int(parameters[nIndex], radix: 10)!
        self.secretSize = Int(parameters[secretSizeIndex], radix: 10)!
        self.r = BigUInt(parameters[rIndex].split(separator: ".")[0], radix: 10)!

        self.s = (dictionary["s"] as! [String]).map {
            let value = BigUInt($0, radix: 16)!
            return KangarooHelpers.reverseBytes(value, count: 32)
        }

        self.slog = (dictionary["slog"] as! [String]).map {
            let value = BigUInt($0, radix: 16)!
            return value
        }

        (dictionary["table"] as! [[String: String]]).forEach { [unowned self] in
            let key = BigUInt($0["point"]!, radix: 16)!
            let value = BigUInt($0["value"]!, radix: 16)!
            let bigEndianKey = KangarooHelpers.reverseBytes(key, count: 32)

            print(bigEndianKey.serialize().bytes())

            table[bigEndianKey] = value
        }

//        table.keys.forEach {
//            print($0.serialize().count)
//        }
//
//
//        print("r:", r)
//        print("secretSize:", secretSize)
//        print("n:", n)
//        print("w:", w)
//        print("slog:", slog)
//        print("s:", s)
//        print("table:", table)
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
                    let w = try Ed25519Wrapper.pointFromScalarNoclamp(scalar: wlog)
                    return (wlog, w)
                },
                hashRule: hash(pubKey:),
                slog: slog,
                s: s,
                workersCount: workersCount
            )

        table = generatedTable
    }

    func solveDLP(publicKey: BigUInt, workersCount: Int) async throws -> KangarooDLPSolverReport {
        let privateKey = await kangarooDLPSolver
            .solve(
                table: table,
                W: w,
                pubKey: publicKey,
                distinguishedRule: isDistinguished(pubKey:),
                keypairGenerationRule: { [unowned self] in
                    let wdist = BigUInt.random(bits: secretSize - 8)
//                    let wdist = BigUInt("e4eae8", radix: 16)!
                    let q = try Ed25519Wrapper.pointFromScalarNoclamp(scalar: wdist)
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
        let reversed = BigUInt(Data(pubKey.serialize().reversed()))
        return Int(reversed & (self.r - 1))
    }

    private func isDistinguished(pubKey: BigUInt) -> Bool {
//        let reversed = BigUInt(Data(pubKey.serialize().reversed()))
//        return ((reversed & (w - 1)) == 0)
        return ((pubKey & (w - 1)) == 0)
    }

    private func generateKeypairs() throws {
        for i in 0..<self.r {
            let slog = BigUInt.random(limit: BigUInt.random(bits: secretSize - 2) / w)
            let s = try Ed25519Wrapper.pointFromScalarNoclamp(scalar: slog)

            self.slog.insert(slog, at: Int(i))
            self.s.insert(s, at: Int(i))
        }
    }

}
