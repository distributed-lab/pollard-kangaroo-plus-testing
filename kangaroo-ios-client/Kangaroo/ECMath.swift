//
//  ECMath.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 07.11.2024.
//

import Foundation
import BigInt

struct Point2 {
    let x: BigInt
    let y: BigInt
}

protocol EcdsaMath {
    func addPoints(_ p1: Point2, _ p2: Point2) -> Point2
    func doublePoint(_ point: Point2) -> Point2
    func mulPoint(_ point: Point2, scalar: BigInt) -> Point2
}

class Ed25519: EcdsaMath {
    let a: BigInt = BigInt("7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec", radix: 16)!
    let p: BigInt = BigInt("7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed", radix: 16)!

    static let shared = Ed25519()

    func addPoints(_ p1: Point2, _ p2: Point2) -> Point2 {
        if p1.x == p2.x && p1.y == p2.y {
            return doublePoint(p1)
        }

        let slope = ((p1.y - p2.y) * (p1.x - p2.x).inverse(p)!) % p

        let x = (slope * slope - p1.x - p2.x) % p
        let y = (slope * (p1.x - x) - p1.y) % p

        return Point2(x: x, y: y)
    }

    func doublePoint(_ point: Point2) -> Point2 {
        let slope = ((3 * point.x.power(2) + a) * (2 * point.y).inverse(p)!) % p

        let x = (slope * slope - 2 * point.x) % p
        let y = (slope * (point.x - x) - point.y) % p

        return Point2(x: x, y: y)
    }

    func mulPoint(_ point: Point2, scalar: BigInt) -> Point2 {
        var currentPoint = point
        let binaryRepresentation = scalar.toBits()

        for bit in binaryRepresentation.dropFirst() {
            currentPoint = doublePoint(currentPoint)

            if bit == 1 {
                currentPoint = addPoints(currentPoint, point)
            }
        }

        return currentPoint
    }
}
