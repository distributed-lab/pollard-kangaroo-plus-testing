//
//  ViewController.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 31.10.2024.
//

import UIKit
import BigInt

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let kangaroo = try! Kangaroo.init(n: 150, w: BigUInt(integerLiteral: 1024), secretSize: 16)


        Task {
            try await kangaroo.generateTableParalized()
        }
    }
}

