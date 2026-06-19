import SwiftUI
import PhotosUI

/// Create listing multi-step form (spec §4.3, §12.9).
struct CreateListingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = CreateListingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator
                Group {
                    switch vm.step {
                    case 0: PhotoStepView(vm: vm)
                    case 1: DetailsStepView(vm: vm)
                    default: ReviewStepView(vm: vm)
                    }
                }
                navigationBar
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.reset()
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: .constant(vm.createdListing != nil)) {
                CreateListingSuccessView(vm: vm) {
                    vm.reset()
                    dismiss()
                }
            }
            .overlay {
                if vm.isLoading { LoadingOverlay(message: "Publishing…") }
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i <= vm.step ? Theme.accentColor : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            if vm.step > 0 {
                Button { vm.moveBack() } label: {
                    Label("Back", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
            }
            Button {
                if vm.step < 2 {
                    vm.moveForward()
                } else {
                    Task { _ = await vm.submit() }
                }
            } label: {
                Text(vm.step < 2 ? "Continue" : "Publish Listing")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(canProceed ? Theme.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canProceed)
        }
        .padding()
        .background(.bar)
    }

    private var canProceed: Bool {
        switch vm.step {
        case 0: return vm.canProceedFromPhotos
        case 1: return vm.canProceedFromDetails
        default: return true
        }
    }
}

// MARK: - Step 1: Photos

struct PhotoStepView: View {
    @ObservedObject var vm: CreateListingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with progress
                VStack(alignment: .leading, spacing: 6) {
                    Text("Step 1 of 3 — Photos")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accentColor)
                    Text("Add photos of your item")
                        .font(.title2.bold())
                    Text("Good photos sell faster. Add up to \(Constants.maxListingImages) photos. The first one becomes the cover image.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedText)
                }

                // Photo grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(vm.images.indices), id: \.self) { idx in
                        Image(uiImage: vm.images[idx])
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    vm.removeImage(at: idx)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, .black.opacity(0.5))
                                }
                                .padding(4)
                            }
                            .overlay(alignment: .bottomLeading) {
                                if idx == 0 {
                                    Text("Cover")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6).padding(.vertical, 3)
                                        .background(Theme.accentColor)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                        .padding(4)
                                }
                            }
                    }
                    if vm.images.count < Constants.maxListingImages {
                        PhotosPicker(selection: $vm.photoItems, maxSelectionCount: Constants.maxListingImages - vm.images.count, matching: .images) {
                            VStack(spacing: 6) {
                                Image(systemName: "camera.badge.ellipsis").font(.title2)
                                Text("Add Photo").font(.caption.weight(.medium))
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            )
                        }
                    }
                }

                // Photo tips
                VStack(alignment: .leading, spacing: 10) {
                    Text("Photo Tips").font(.subheadline.weight(.semibold))
                    photoTip(icon: "sun.max.fill", text: "Use natural lighting for the clearest shots", color: .orange)
                    photoTip(icon: "rectangle.dashed", text: "Fill the frame — center your item", color: .blue)
                    photoTip(icon: "sparkles", text: "Clean the item before photographing", color: .purple)
                    photoTip(icon: "camera.metering.center.weighted", text: "Show any wear or damage honestly", color: .red)
                }
                .padding()
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if vm.images.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundStyle(Theme.accentColor)
                        Text("At least one photo is required to publish your listing.")
                            .font(.caption).foregroundStyle(Theme.mutedText)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding()
        }
    }

    private func photoTip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            Text(text).font(.caption).foregroundStyle(Theme.mutedText)
        }
    }
}

// MARK: - Step 2: Details

struct DetailsStepView: View {
    @ObservedObject var vm: CreateListingViewModel

    var body: some View {
        Form {
            Section {
                Text("Step 2 of 3 — Details")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accentColor)
                Text("Tell buyers about your item")
                    .font(.title3.bold())
            }
            .listRowBackground(Color.clear)

            Section("Listing Details") {
                TextField("Title", text: $vm.title, prompt: Text("e.g. Calculus: Early Transcendentals"))
                TextField("Course Code (e.g. SOFT1101)", text: $vm.courseCode)
                    .autocapitalization(.allCharacters)

                Picker("Subject", selection: $vm.subject) {
                    ForEach(Constants.subjects, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)

                Picker("Condition", selection: $vm.condition) {
                    ForEach(Condition.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section {
                HStack {
                    Text("QAR")
                        .foregroundStyle(Theme.mutedText)
                    TextField("0.00", text: $vm.priceText)
                        .keyboardType(.decimalPad)
                }
                if !vm.priceText.isEmpty, !Validators.isValidListingPrice(vm.price) {
                    Label("Price must be between 0 and 10,000 QAR", systemImage: "info.circle")
                        .font(.caption).foregroundStyle(.orange)
                }
            } header: {
                Text("Price")
            } footer: {
                if vm.price > 0 {
                    Text("After the 10% platform fee, you'll receive \(Formatters.currencyShort((vm.price * 0.9).roundedTo2())).")
                        .font(.caption)
                }
            }

            Section {
                TextEditor(text: $vm.description)
                    .frame(minHeight: 120)
            } header: {
                Text("Description")
            } footer: {
                Text("Include details like edition, highlighting, notes, or any damage. Listings with detailed descriptions sell 40% faster.")
                    .font(.caption)
            }

            if let error = vm.errorMessage {
                Section { ErrorBanner(message: error) }
                    .listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            }
        }
    }
}

// MARK: - Step 3: Review

struct ReviewStepView: View {
    @ObservedObject var vm: CreateListingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let first = vm.images.first {
                    Image(uiImage: first)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(vm.title).font(.title3.bold())
                    HStack {
                        ConditionTagView(condition: vm.condition)
                        tagChip(vm.courseCode.uppercased())
                        tagChip(vm.subject)
                    }
                    Text(Formatters.currency(vm.price))
                        .font(.headline).foregroundStyle(Theme.accentColor)
                    Divider()
                    Text(vm.description).font(.body)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 6) {
                    Label("Commission (10%)", systemImage: "percent")
                        .font(.caption).foregroundStyle(Theme.mutedText)
                    Text("You'll receive \(Formatters.currencyShort((vm.price * 0.9).roundedTo2())) after the 10% platform fee.")
                        .font(.caption).foregroundStyle(Theme.mutedText)
                }
                .padding(.horizontal)
            }
        }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text).font(.caption.weight(.medium))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Theme.accentColor.opacity(0.12))
            .foregroundStyle(Theme.accentColor)
            .clipShape(Capsule())
    }
}

// MARK: - Success

struct CreateListingSuccessView: View {
    @ObservedObject var vm: CreateListingViewModel
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: vm.moderationFlagged ? "eye.circle.fill" : "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(vm.moderationFlagged ? .orange : Theme.success)
            Text(vm.moderationFlagged ? "Under Review" : "Listing Published!")
                .font(.title2.bold())
            Text(vm.moderationFlagged
                ? "Your listing is being reviewed by our moderation team. It will appear in search once approved."
                : "Your item is now live and visible to UDST students.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.mutedText)
                .padding(.horizontal, 32)
            Spacer()
            PrimaryButton(title: "Done", systemImage: "checkmark") { onDone() }
                .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden()
    }
}
