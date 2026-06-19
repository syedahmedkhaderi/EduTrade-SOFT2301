import SwiftUI

/// Checkout screen (spec §4.6, §12.10).
struct CheckoutView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = CheckoutViewModel()
    let listingID: String

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let preview = vm.preview {
                    // Item summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order Summary").font(.headline)
                        HStack(spacing: 12) {
                            ListingImage(imageKey: preview.listing.imageURLs.first, title: preview.listing.title, cornerRadius: 8)
                                .frame(width: 60, height: 60)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preview.listing.title).font(.subheadline.bold()).lineLimit(2)
                                Text(preview.listing.courseCode).font(.caption).foregroundStyle(Theme.mutedText)
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))

                    // Price breakdown
                    VStack(spacing: 12) {
                        priceRow(label: "Item Price", value: preview.itemPrice)
                        priceRow(label: "Platform Fee (10%)", value: preview.commissionAmount, color: .orange)
                        Divider()
                        priceRow(label: "Total Charge", value: preview.totalCharge, bold: true)
                    }
                    .padding()
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))

                    // Stripe payment card placeholder (mock)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Payment Method", systemImage: "creditcard.fill").font(.headline)
                        HStack {
                            Image(systemName: "creditcard").font(.title2).foregroundStyle(Theme.mutedText)
                            VStack(alignment: .leading) {
                                Text("Test Card (Mock)").font(.subheadline)
                                Text("•••• •••• •••• 4242").font(.caption).foregroundStyle(Theme.mutedText)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success)
                        }
                    }
                    .padding()
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))

                    Text("In production this screen uses the Stripe PaymentSheet. In demo mode the payment completes instantly.")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                        .multilineTextAlignment(.center)
                } else if vm.isLoading {
                    ProgressView().padding(.top, 60)
                } else if let error = vm.errorMessage {
                    EmptyStateView(symbol: "exclamationmark.triangle", title: "Checkout Error", subtitle: error)
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if vm.preview != nil && !vm.paymentSucceeded {
                PrimaryButton(
                    title: "Pay \(Formatters.currency(vm.preview?.totalCharge ?? 0))",
                    systemImage: "lock.fill",
                    isLoading: vm.isProcessing,
                    isEnabled: vm.preview != nil
                ) {
                    Task { _ = await vm.pay(listingID: listingID) }
                }
                .padding()
                .background(.bar)
            }
        }
        .navigationDestination(isPresented: $vm.paymentSucceeded) {
            if let tx = vm.transaction {
                PaymentConfirmationView(transaction: tx)
            }
        }
        .task { await vm.load(listingID: listingID) }
    }

    private func priceRow(label: String, value: Double, color: Color = .primary, bold: Bool = false) -> some View {
        HStack {
            Text(label).font(bold ? .headline : .subheadline)
            Spacer()
            Text(Formatters.currency(value))
                .font(bold ? .headline : .subheadline)
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(color)
        }
    }
}

/// Payment confirmation screen (spec §12.11).
struct PaymentConfirmationView: View {
    let transaction: Transaction
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.success)
            Text("Payment Successful!").font(.title2.bold())
            Text("The seller has been notified and will prepare your item.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.mutedText)
                .padding(.horizontal, 32)

            VStack(spacing: 8) {
                confirmationRow(label: "Transaction ID", value: String(transaction.id.prefix(12)))
                confirmationRow(label: "Amount Paid", value: Formatters.currency(transaction.itemPrice))
                confirmationRow(label: "Platform Fee", value: Formatters.currency(transaction.commissionAmount))
                confirmationRow(label: "Date", value: Formatters.dateTime(transaction.completedAt ?? .now))
            }
            .padding()
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()
            PrimaryButton(title: "Back to Home", systemImage: "house.fill") {
                appState.tabSelection = 0
            }
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden()
    }

    private func confirmationRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.mutedText)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}
