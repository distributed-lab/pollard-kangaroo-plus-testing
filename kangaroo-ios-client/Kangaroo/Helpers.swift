//
//  Helpers.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 01.11.2024.
//

import BigInt
import Foundation

extension Kangaroo {
    enum KangarooHelpers {
        static func generateRandomBigInt(bitSize: Int) -> BigInt {
            let byteCount = (bitSize + 7) / 8
            var randomBytes = [UInt8](repeating: 0, count: byteCount)

            for i in 0..<byteCount {
                randomBytes[i] = UInt8.random(in: 0...255)
            }

            let bigUInt = BigUInt(Data(randomBytes))
            return BigInt(bigUInt)
        }

        static func padWithZerosEnd(input: Data, length: Int) -> Data {
            var input = input
            if input.count >= length {
                return input
            }
            let zerosPadding = Array<UInt8>.init(repeating: UInt8(0), count: length - input.count)
            input.append(contentsOf: zerosPadding)
            return input
        }

        static func padWithZerosBeginning(input: String, length: Int) -> String {
            if input.count >= length {
                return input
            }
            return String(repeating: "0", count: length - input.count) + input
        }
    }
}
