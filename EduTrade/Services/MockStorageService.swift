import Foundation
import UIKit

/// Mock storage service. Returns placeholder URLs that resolve to bundled SF-symbol-style images.
/// In production this uploads to Firebase Storage and returns real download URLs.
final class MockStorageService: StorageServiceProtocol {

    func uploadImage(_ image: UIImage, folder: String) async throws -> String {
        // Mock: generate a stable key. The Image system resolves these to bundled placeholders.
        let key = "\(folder)/\(UUID().uuidString)"
        return key
    }

    func resolveURL(_ key: String) -> URL? {
        // For mock image keys we use the AsyncImage placeholder system; no real URL needed.
        URL(string: "https://edutrade.mock/images/\(key)")
    }
}
