//
//  ViewController.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 31.10.2024.
//

import UIKit
import BigInt
import OSLog

let logger = Logger()

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let kangaroo = try! Kangaroo.init(n: 400, w: BigUInt(integerLiteral: 63572), secretSize: 32)
        let sk = BigUInt("F122E56B", radix: 16)!

        let paddedSk = BigUInt(Kangaroo.KangarooHelpers.padWithZerosEnd(input: sk.serialize(), length: 32))
        let publicKey = try! Ed25519Wrapper.publicKeyFromPrivateKey(privateKey: paddedSk)

        Task {
            try await kangaroo.generateTableParalized()

            let foundPrivateKey = try await kangaroo.solveDLP(publicKey: publicKey)

            logger
                .info(
                    "foundPrivateKey: \(foundPrivateKey), privateKey: \(paddedSk), isEqual: \(foundPrivateKey == paddedSk)"
                )
        }
    }
}

