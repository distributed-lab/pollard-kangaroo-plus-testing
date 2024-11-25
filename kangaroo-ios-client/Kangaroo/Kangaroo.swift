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
    private var s: [[UInt8]]

    /// Generated private keys with the array length is equal to the `r`.
    /// In fact it is just random points for the further DLP  solving.
    private var slog: [[UInt8]]

    /// Amount of randomly generated bits of some secret. All the other bits are `zeros` to 32 bytes because of eliptic curve context.
    private let secretSize: Int

    /// Generated table after preprocessing stage. There are relation like key: public_key -> value: private_key
    private var table: Dictionary<[UInt8], [UInt8]>

    /// Kangaroo table generator
    private var kangarooTableGenerator: KangarooTableGenerator

    /// Kangaroo table solver
    private var kangarooDLPSolver: KangarooDLPSolver

    init(n: Int, w: BigUInt, secretSize: Int, r: BigUInt) throws {
        self.n = n
        self.w = w
        self.secretSize = secretSize
        self.r = r
        self.slog = []
        self.s = []
        self.table = .init()

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

        self.s = (dictionary["s"] as! [String]).map { Data(hex:$0)!.bytes() }
        self.slog = (dictionary["slog"] as! [String]).map { Array(Data(hex:$0)!.bytes().reversed()) }

        (dictionary["table"] as! [[String: String]]).forEach { [unowned self] in
            table[Data(hex: $0["point"]!)!.bytes()] = Array(Data(hex: $0["value"]!)!.bytes().reversed())
        }
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
                    let wlogBytes = wlog.serialize().bytes()
                    let w = try Ed25519.Core.pointFromScalarNoclamp(scalar: wlogBytes)
                    return (wlogBytes, w)
                },
                hashRule: hash(pubKey:),
                slog: slog,
                s: s,
                workersCount: workersCount
            )

        table = generatedTable
    }

    func solveDLP(publicKey: String, workersCount: Int, enableStatistics: Bool = true) async throws -> KangarooDLPSolverReport {
        let pubkeyBytes = Data(hex: publicKey)!.bytes()

        let privateKey = try await kangarooDLPSolver
            .solve(
                table: table,
                W: w,
                pubKey: pubkeyBytes,
                distinguishedRule: isDistinguished(pubKey:),
                keypairGenerationRule: { [unowned self] in
                    let wdist = BigUInt.random(bits: secretSize - 8)
                    let wdistBytes = Array(wdist.serialize().bytes().reversed())
                    let q = try Ed25519.Core.pointFromScalarNoclamp(scalar: wdistBytes)
                    let w = try Ed25519.Core.addPoints(pubkeyBytes, q)
                    return (wdistBytes, w)
                },
                hashRule: hash(pubKey:),
                slog: slog,
                s: s,
                workersCount: workersCount,
                enableStatistics: enableStatistics
            )

        return privateKey
    }

    private func hash(pubKey: [UInt8]) -> Int {
        let pubKey = BigUInt(Data(pubKey))
        return Int(pubKey & (self.r - 1))
    }

    private func isDistinguished(pubKey: [UInt8]) -> Bool {
        let pubKey = BigUInt(Data(pubKey))
        return ((pubKey & (w - 1)) == 0)
    }

    private func generateKeypairs() throws {
        for i in 0..<self.r {
            let slog = BigUInt.random(limit: BigUInt.random(bits: secretSize - 2) / w)
            let slogBytes = Array(slog.serialize().bytes().reversed())
            let s = try Ed25519.Core.pointFromScalarNoclamp(scalar: slogBytes)

            self.slog.insert(slogBytes, at: Int(i))
            self.s.insert(s, at: Int(i))
        }
    }

}
