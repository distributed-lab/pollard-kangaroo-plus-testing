//
//  KangarooProcessingScreen.swift
//  kangaroo-ios-client
//
//  Created by Yevhenii Serdiukov on 15.11.2024.
//

import SwiftUI
import BigInt

@MainActor
class KangarooProcessingScreenViewModel: ObservableObject {
    private let tableSize: Int
    private let w: BigUInt
    private let secretSize: Int
    private let r: BigUInt
    private let privateKey: BigUInt
    private let generateTableWorkersCount: Int
    private let solveDLPWorkersCount: Int
    private var kangaroo: Kangaroo?

    @Published var report: KangarooDLPSolverReport?
    @Published var showProcessing: Bool = false

    init(
        tableSize: Int,
        w: BigUInt,
        secretSize: Int,
        r: BigUInt,
        privateKey: BigUInt,
        generateTableWorkersCount: Int,
        solveDLPWorkersCount: Int,
        kangaroo: Kangaroo? = nil
    ) {
        self.tableSize = tableSize
        self.w = w
        self.secretSize = secretSize
        self.r = r
        self.privateKey = privateKey
        self.generateTableWorkersCount = generateTableWorkersCount
        self.solveDLPWorkersCount = solveDLPWorkersCount
        self.kangaroo = kangaroo
    }

    func processing() {
        showProcessing = true
        do {
            kangaroo = try Kangaroo(n: tableSize, w: w, secretSize: secretSize, r: r)
        } catch {
            print(error.localizedDescription)
            processing()
        }

        Task { @MainActor in
            let publicKey = try Ed25519Wrapper.pointFromScalarNoclamp(scalar: privateKey)

            try await kangaroo?.generateTableParalized(
                workersCount: generateTableWorkersCount
            )

            let report = try await kangaroo?.solveDLP(
                publicKey: publicKey,
                workersCount: solveDLPWorkersCount
            )

            self.report = report

            showProcessing = false
        }
    }
}

struct KangarooProcessingScreenView: View {
    @ObservedObject private var viewModel: KangarooProcessingScreenViewModel

    init(viewModel: KangarooProcessingScreenViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            if let report = viewModel.report {
                VStack(alignment: .leading) {
                    Text("Private key: \(report.result)")
                    Text("DLP \(report.statistics.description)")
                    Text("Time duration in seconds: \(report.time)")
                }

                Spacer()
            }

            Button {
                viewModel.processing()
            } label: {
                Text("Start DLP Solve")
            }

        }
        .overlay {
            if viewModel.showProcessing {
                ProgressView().scaleEffect(5)
            }
        }
    }
}

#Preview {
    KangarooProcessingScreenView(
        viewModel: .init(
            tableSize: 250,
            w: 2048,
            secretSize: 1,
            r: 1,
            privateKey: 1,
            generateTableWorkersCount: 1,
            solveDLPWorkersCount: 1
        )
    )
}
