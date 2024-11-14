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
        let max = (BigUInt(1) << bits) - 1
        return BigUInt.randomInteger(lessThan: max + 1)
    }

    static func random(limit: BigUInt) -> BigUInt {
        return BigUInt.randomInteger(lessThan: limit)
    }
}
