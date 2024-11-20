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
        let publicKey = "abbfc9ba9888735ae30f830196c16e51fdae386ec7b49bc76087bdd7dbe2cfce"
        let kangaroo = try! Kangaroo(outputFileName: "output_2048_1600_32_64")
        Task {
            let report = try await kangaroo.solveDLP(publicKey: publicKey, workersCount: 6, enableStatistics: false)
            print(report.statistics)
            print("time duration: \(report.time) seconds")
        }
    }
}

