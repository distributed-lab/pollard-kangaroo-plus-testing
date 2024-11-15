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
    private lazy var kangaroo = try! Kangaroo.init(n: 400, w: BigUInt(integerLiteral: 63572), secretSize: 32)

    override func viewDidLoad() {
        super.viewDidLoad()

        let sk = BigUInt("313249263", radix: 10)!
        let publicKey = try! Ed25519Wrapper.pointFromScalarNoclamp(scalar: sk)

        Task {
            let time = Date().timeIntervalSince1970
            try await kangaroo.generateTableParalized(workersCount: 6)
            let foundPrivateKey = try await kangaroo.solveDLP(publicKey: publicKey, workersCount: 6)
            logger.info("Private key was found: \(foundPrivateKey) for: \(Date().timeIntervalSince1970 - time) seconds")
        }
    }
}

