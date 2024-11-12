//
//  BigInt+Bits.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 07.11.2024.
//

import BigInt
import Foundation

extension BigInt {
    func toBits() -> [UInt8] {
        let byteArray = self.serialize()

        var bits: [UInt8] = []
        for byte in byteArray {
            for i in 0..<8 {
                let bit = (byte >> (7 - i)) & 1
                bits.append(bit)
            }
        }
        return bits
    }

    static func random(bits: Int) -> BigInt? {
        guard bits > 0 else { return nil }
        let byteCount = (bits + 7) / 8
        var randomBytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &randomBytes)
        guard status == errSecSuccess else { return nil }
        return BigInt(sign: .plus, magnitude: BigUInt(Data(randomBytes)))
    }

    static func random(limit: BigInt) -> BigInt {
        return (0..<limit).randomElement()!
    }
}
