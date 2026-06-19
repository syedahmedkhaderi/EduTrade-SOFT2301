import SwiftUI

/// Rate transaction screen (spec §4.5, §12.15).
struct RateTransactionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = RateTransactionViewModel()
    let transaction: Transaction

    @State private var hasChecked = false
    @State private var alreadyRated = false

    var body: some View {
        Form {
            if alreadyRated {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.success)
                        Text("You've already rated this transaction.").foregroundStyle(Theme.mutedText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            } else {
                Section("Rate your experience") {
                    VStack(spacing: 16) {
                        StarPicker(stars: $vm.stars)
                        Text(vm.stars == 5 ? "Excellent!" :
                             vm.stars == 4 ? "Very Good" :
                             vm.stars == 3 ? "Good" :
                             vm.stars == 2 ? "Fair" : "Poor")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }

                Section("Comment (optional)") {
                    TextEditor(text: $vm.comment)
                        .frame(minHeight: 100)
                }

                if let error = vm.errorMessage {
                    Section { ErrorBanner(message: error) }
                        .listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                }

                Section {
                    Button {
                        Task {
                            if await vm.submit(transaction: transaction) {
                                alreadyRated = true
                            }
                        }
                    } label: {
                        HStack {
                            if vm.isSubmitting { ProgressView().tint(.white) }
                            Text("Submit Rating").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Theme.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(vm.isSubmitting)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Rate Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !hasChecked {
                alreadyRated = await vm.hasAlreadyRated(transaction: transaction)
                hasChecked = true
            }
        }
    }
}

/// Interactive star picker.
struct StarPicker: View {
    @Binding var stars: Int

    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= stars ? "star.fill" : "star")
                    .font(.system(size: 34))
                    .foregroundStyle(star <= stars ? .orange : .gray.opacity(0.4))
                    .onTapGesture { stars = star }
                    .accessibilityLabel("\(star) star\(star > 1 ? "s" : "")")
            }
        }
    }
}
