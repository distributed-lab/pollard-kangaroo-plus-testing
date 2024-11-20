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
//    private lazy var kangaroo = try! Kangaroo.init(n: 1600, w: BigUInt(integerLiteral: 2048), secretSize: 32, r: 128)

    override func viewDidLoad() {
        super.viewDidLoad()

//        let sk = BigUInt("2686214879", radix: 10)!
//        let publicKey = try! Ed25519Wrapper.pointFromScalarNoclamp(scalar: sk)

//        let publicKeyLittleEndian = BigUInt("abbfc9ba9888735ae30f830196c16e51fdae386ec7b49bc76087bdd7dbe2cfce", radix: 16)!
//        let publicKey = BigUInt(Data(Array(publicKeyLittleEndian.serialize().bytes().reversed())))
////
//        let kangaroo = try! Kangaroo(outputFileName: "output_4096_1600_32_64")
//        Task {
//            let report = try await kangaroo.solveDLP(publicKey: publicKey, workersCount: 6)
//            print(report.statistics)
//            print("time duration: \(report.time) seconds")
//        }


//        Task {
//            let time = Date().timeIntervalSince1970
//            try await kangaroo.generateTableParalized(workersCount: 12)
//            let report = try await kangaroo.solveDLP(publicKey: publicKey, workersCount: 6)
//            logger
//                .info(
//                    "Private key was found: \(report.result) for: \(Date().timeIntervalSince1970 - time) seconds"
//                )
//            print(report.statistics)
//            print("time duration: \(report.time) seconds")
//        }
    }
}

