//
//  BigInt+Bits.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 07.11.2024.
//

import BigInt

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
}
