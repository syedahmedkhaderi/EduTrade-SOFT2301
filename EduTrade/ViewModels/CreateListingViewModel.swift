import Foundation
import SwiftUI
import PhotosUI

/// Create / edit listing ViewModel (spec §4.3, §12.9).
@MainActor
final class CreateListingViewModel: ObservableObject {

    // Step state
    @Published var step: Int = 0   // 0 = photos, 1 = details, 2 = review

    // Fields
    @Published var images: [UIImage] = []
    @Published var photoItems: [PhotosPickerItem] = [] {
        didSet { Task { await loadPhotos() } }
    }
    @Published var title = ""
    @Published var description = ""
    @Published var courseCode = ""
    @Published var subject = Constants.subjects.first ?? "Computer Science"
    @Published var condition: Condition = .good
    @Published var priceText = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdListing: Listing?
    @Published var moderationFlagged = false

    private let listingService: ListingServiceProtocol
    private let storage: StorageServiceProtocol
    private let appState: AppState

    init() {
        let appState = AppState.current!
        self.appState = appState
        self.listingService = appState.services.listings
        self.storage = appState.services.storage
    }

    var price: Double { Double(priceText) ?? 0 }

    var canProceedFromPhotos: Bool { images.count >= Constants.minListingImages }
    var canProceedFromDetails: Bool {
        Validators.isListingValid(
            title: title, description: description, courseCode: courseCode,
            subject: subject, price: price, imageCount: images.count
        )
    }

    // MARK: - Mutations

    func addImage(_ image: UIImage) {
        guard images.count < Constants.maxListingImages else { return }
        images.append(image)
    }

    func removeImage(at index: Int) {
        guard images.indices.contains(index) else { return }
        images.remove(at: index)
    }

    private func loadPhotos() async {
        for item in photoItems {
            guard images.count < Constants.maxListingImages else { break }
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run { addImage(image) }
            }
        }
        photoItems = []
    }

    func moveForward() {
        switch step {
        case 0: if canProceedFromPhotos { step = 1 }
        case 1: if canProceedFromDetails { step = 2 }
        default: break
        }
    }

    func moveBack() {
        if step > 0 { step -= 1 }
    }

    // MARK: - Submit

    func submit() async -> Bool {
        guard let seller = AppState.sessionUser() else {
            errorMessage = "Please sign in to create a listing."
            return false
        }
        guard canProceedFromDetails else {
            errorMessage = "Please complete all fields and add at least one photo."
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Upload images
        var imageURLs: [String] = []
        for image in images {
            if let url = try? await storage.uploadImage(image, folder: "listings") {
                imageURLs.append(url)
            }
        }
        guard !imageURLs.isEmpty else {
            errorMessage = AppError.listingRequiresPhoto.localizedDescription
            return false
        }

        let draft = Listing(
            sellerID: seller.id,
            title: title.trimmed,
            description: description.trimmed,
            courseCode: courseCode.trimmed.uppercased(),
            subject: subject,
            price: price,
            condition: condition,
            imageURLs: imageURLs
        )

        do {
            let created = try await listingService.createListing(draft)
            createdListing = created
            moderationFlagged = (created.moderationStatus == .flagged)
            appState.toasts.success(moderationFlagged
                ? "Listing submitted — under review."
                : "Listing published successfully!")
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func reset() {
        step = 0
        images = []
        title = ""
        description = ""
        courseCode = ""
        subject = Constants.subjects.first ?? "Computer Science"
        condition = .good
        priceText = ""
        errorMessage = nil
        createdListing = nil
        moderationFlagged = false
    }
}
