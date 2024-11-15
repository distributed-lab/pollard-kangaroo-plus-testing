//
//  KangarooStatistics.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 15.11.2024.
//

class KangarooStatistics: CustomStringConvertible {
    private var opEd25519AddPoints: Int = 0
    private var opEd25519ScalarMul: Int = 0
    private var opEd25519ScalarAdd: Int = 0
    private var opEd25519ScalarSub: Int = 0

    func trackOpEd25519AddPointsCount() {
        opEd25519AddPoints += 1
    }

    func trackOpEd25519ScalarMul() {
        opEd25519ScalarMul += 1
    }

    func trackOpEd25519ScalarAdd() {
        opEd25519ScalarAdd += 1
    }

    func trackOpEd25519ScalarSub() {
        opEd25519ScalarSub += 1
    }

    var description: String {
    """
    Statistics: 
    opEd25519AddPoints: \(opEd25519AddPoints)
    opEd25519ScalarMul: \(opEd25519ScalarMul) 
    opEd25519ScalarAdd: \(opEd25519ScalarAdd) 
    opEd25519ScalarSub: \(opEd25519ScalarSub) 
    """
    }
}
