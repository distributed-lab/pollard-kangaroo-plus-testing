//
//  BigInt+Bits.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 07.11.2024.
//

import BigInt
import Foundation

extension BigUInt {
    static func random(bits: Int) -> BigUInt? {
        guard bits > 0 else { return nil }
        let byteCount = (bits + 7) / 8
        var randomBytes = [UInt8](repeating: 0, count: byteCount)

        for i in 0..<byteCount {
            randomBytes[i] = UInt8.random(in: 1...UInt8.max)
        }

        return BigUInt(Data(randomBytes))
    }

    static func random(limit: BigUInt) -> BigUInt {
        return (1..<limit).randomElement()!
    }
}
