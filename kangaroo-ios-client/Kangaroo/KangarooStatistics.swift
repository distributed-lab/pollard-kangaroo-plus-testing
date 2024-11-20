//
//  KangarooStatistics.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 15.11.2024.
//

class KangarooStatistics: CustomStringConvertible {
    fileprivate var opEd25519AddPoints: Int = 0
    fileprivate var opEd25519ScalarMul: Int = 0
    fileprivate var opEd25519ScalarAdd: Int = 0
    fileprivate var opEd25519ScalarSub: Int = 0

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

    func ed25519MainOpsCount() -> Int {
        opEd25519AddPoints + opEd25519ScalarMul
    }

    func ed25519FullOpsCount() -> Int {
        opEd25519AddPoints + opEd25519ScalarMul + opEd25519ScalarAdd + opEd25519ScalarSub
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

    static func +=(lhs: inout KangarooStatistics, rhs: KangarooStatistics) {
        lhs.opEd25519AddPoints += rhs.opEd25519AddPoints
        lhs.opEd25519ScalarMul += rhs.opEd25519ScalarMul
        lhs.opEd25519ScalarAdd += rhs.opEd25519ScalarAdd
        lhs.opEd25519ScalarSub += rhs.opEd25519ScalarSub
    }
}
