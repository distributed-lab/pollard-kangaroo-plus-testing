//
//  Data+Bytes.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 12.11.2024.
//

import Foundation

extension Data {
    init?(hex: String) {
        var hex = hex
        if hex.count % 2 != 0 { hex = "0" + hex }

        self.init(capacity: hex.count / 2)

        var index = hex.startIndex
        for _ in 0..<hex.count / 2 {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            self.append(byte)
            index = nextIndex
        }
    }

    func bytes() -> [UInt8] { self.map { $0 } }

    func hexEncodedString() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}
