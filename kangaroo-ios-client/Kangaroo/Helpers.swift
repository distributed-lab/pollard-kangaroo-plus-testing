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
        static func padWithZerosEnd(input: [UInt8], length: Int) -> [UInt8] {
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
