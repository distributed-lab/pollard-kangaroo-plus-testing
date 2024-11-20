import SwiftUI
import BigInt

@MainActor
class KangarooConfigurationScreenViewModel: ObservableObject {
    @Published var tableSizeSelection = 0
    let tableSizes: [Int] = [400, 1600]
    @Published var roundKeypairSelection = 0
    let roundsKeypair: [Int] = [63572, 65536]
    @Published var secretSize: String = "32"
    @Published var rLength: String = "128"
    @Published var privateKey = "313249263"
    @Published var generateTableWorkersCount = "6"
    @Published var solveDLPWorkersCount = "6"

    func confirm() {
        if secretSize.isEmpty || rLength.isEmpty || privateKey.isEmpty {
            return
        }

        let viewModel = KangarooProcessingScreenViewModel(
            tableSize: tableSizes[tableSizeSelection],
            w: BigUInt(roundsKeypair[roundKeypairSelection]),
            secretSize: Int.init(secretSize, radix: 10)!,
            r: BigUInt(rLength, radix: 10)!,
            privateKey: BigUInt(privateKey, radix: 10)!,
            generateTableWorkersCount: Int.init(generateTableWorkersCount, radix: 10)!,
            solveDLPWorkersCount: Int.init(solveDLPWorkersCount, radix: 10)!
        )

        NavigationManager.shared.pushView(
            KangarooProcessingScreenView(viewModel: viewModel)
        )
    }
}

struct KangarooConfigurationScreen: View {
    @StateObject
    private var viewModel = KangarooConfigurationScreenViewModel()

    @FocusState
    var isFocused: Bool


    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScrollView {
                Spacer()
                    .frame(height: 10)

                HStack {
                    Text("Table size:")
                    Picker("Table size", selection: $viewModel.tableSizeSelection) {
                        ForEach(0..<viewModel.tableSizes.count, id: \.self) {
                            Text(String(viewModel.tableSizes[$0])).tag($0)
                        }
                    }.pickerStyle(.menu)
                }

                HStack {
                    Text("Rounds per keypair:")
                    Picker("Table size", selection: $viewModel.roundKeypairSelection) {
                        ForEach(0..<viewModel.roundsKeypair.count, id: \.self) {
                            Text(String(viewModel.roundsKeypair[$0])).tag($0)
                        }
                    }.pickerStyle(.menu)
                }

                VStack(alignment: .leading) {
                    Text("Secret size bits")
                    TextField("Please enter secret size", text: $viewModel.secretSize)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 8)
                        .frame(height: 50)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke()
                        }
                }

                VStack(alignment: .leading) {
                    Text("The length of the helpers values for table")
                    TextField("Please enter", text: $viewModel.rLength)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .padding(.horizontal, 8)
                        .frame(height: 50)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke()
                        }
                }

                VStack(alignment: .leading) {
                    Text("Private key (Big-Endian)")
                    TextField("Please enter", text: $viewModel.privateKey)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .padding(.horizontal, 8)
                        .frame(height: 50)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke()
                        }
                }

                VStack(alignment: .leading) {
                    Text("Generate table workers count")
                    TextField("Please enter", text: $viewModel.generateTableWorkersCount)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .padding(.horizontal, 8)
                        .frame(height: 50)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke()
                        }
                }

                VStack(alignment: .leading) {
                    Text("Solve DLP workers count")
                    TextField("Please enter", text: $viewModel.solveDLPWorkersCount)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .padding(.horizontal, 8)
                        .frame(height: 50)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke()
                        }
                }

                Spacer().frame(height: 24)

                Button {
                    viewModel.confirm()
                } label: {
                    Rectangle().overlay {
                        Text("Start")
                            .foregroundStyle(.white)
                    }

                }
                .cornerRadius(8)
                .frame(height: 50)
//                .frame(width: .greatestFiniteMagnitude)
            }
        }
        .padding(.horizontal, 16)
        .onTapGesture {
            isFocused = false
        }
    }
}

#Preview {
    KangarooConfigurationScreen()
}
