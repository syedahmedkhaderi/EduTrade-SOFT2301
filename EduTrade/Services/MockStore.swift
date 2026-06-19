import Foundation

/// A single in-memory data store backing all mock services.
/// Concurrency-safe actor. State persists across app launches via JSON on disk.
actor MockStore {

    // MARK: - State

    private(set) var users: [User] = []
    private(set) var listings: [Listing] = []
    private(set) var transactions: [Transaction] = []
    private(set) var ratings: [Rating] = []
    private(set) var reports: [Report] = []

    /// Plaintext passwords keyed by email (mock only).
    private var credentials: [String: String] = [:]

    /// In-flight created-but-not-yet-verified users.
    private var pendingVerification: Set<String> = []

    // MARK: - Persistence

    private let diskURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("EduTradeMockStore.json")
    }()

    // MARK: - Init

    func bootstrap() {
        loadFromDisk()
        if users.isEmpty {
            seed()
            saveToDisk()
        }
    }

    // MARK: - Seeding

    private func seed() {
        // --- Admin ---
        let admin = User(
            id: "admin-1",
            fullName: "Admin Account",
            universityEmail: "admin@udst.edu.qa",
            isEmailVerified: true,
            profileImageURL: nil,
            averageRating: 5.0,
            totalRatings: 1,
            isAdmin: true,
            isSuspended: false
        )
        users.append(admin)
        credentials["admin@udst.edu.qa"] = "admin123"

        // --- Demo student ---
        let demo = User(
            id: "student-demo",
            fullName: "Ahmed Al-Mansoori",
            universityEmail: "ahmed.mansoori@udst.edu.qa",
            isEmailVerified: true,
            profileImageURL: nil,
            averageRating: 4.8,
            totalRatings: 12
        )
        users.append(demo)
        credentials["ahmed.mansoori@udst.edu.qa"] = "password123"

        // --- More students (sellers) ---
        let otherStudents: [(String, String, Double, Int)] = [
            ("Sara Al-Kuwari",        "sara.kuwari@udst.edu.qa",       4.9,  8),
            ("Mohammed Al-Sulaiti",   "m.sulaiti@udst.edu.qa",         4.7, 15),
            ("Fatima Al-Noaimi",      "fatima.noaimi@udst.edu.qa",     5.0,  6),
            ("Abdullah Al-Mohannadi", "abdullah.m@udst.edu.qa",        4.3, 22),
            ("Noor Al-Subaie",        "noor.subaie@udst.edu.qa",       4.6,  9),
            ("Khalid Al-Boainin",     "khalid.boainin@udst.edu.qa",    4.1,  4),
            ("Latifa Al-Dosari",      "latifa.dosari@udst.edu.qa",     4.8, 11)
        ]
        for (i, (name, email, rating, count)) in otherStudents.enumerated() {
            users.append(User(
                id: "student-\(i+2)",
                fullName: name,
                universityEmail: email,
                isEmailVerified: true,
                averageRating: rating,
                totalRatings: count
            ))
            credentials[email] = "password123"
        }

        // --- Listings ---
        let sampleListings: [(String, String, String, String, Double, Condition, String, Int)] = [
            // title, desc, course, subject, price, condition, imageKey, sellerIndex
            ("Intro to Python Programming",
             "Used for SOFT1101. Highlighting and pencil notes in first 3 chapters. No missing pages. Great for first-year IT students.",
             "SOFT1101", "Computer Science", 90.0, .good,
             "textbook-python", 1),

            ("Engineering Mechanics: Statics",
             "Hibbeler 14th edition. Hardcover in excellent condition. Used for MECH1201.",
             "MECH1201", "Engineering", 180.0, .likeNew,
             "textbook-mechanics", 2),

            ("Principles of Management",
             "Robbins & Coulter. Lightly used. Minor highlighting in chapter 4-6.",
             "BUSI1301", "Business", 75.0, .fair,
             "textbook-management", 3),

            ("Human Anatomy & Physiology Lab Manual",
             "Marieb. Used for HSCI2103. No filled-in pages. Spiral binding intact.",
             "HSCI2103", "Health Sciences", 65.0, .good,
             "textbook-anatomy", 4),

            ("Calculus: Early Transcendentals",
             "Stewart 8th edition. Hardcover. Great condition. Used for MATH1401.",
             "MATH1401", "Mathematics", 220.0, .likeNew,
             "textbook-calculus", 5),

            ("Data Structures & Algorithms in Java",
             "Robert Lafore. Slightly worn cover, pages clean. Used for SOFT2202.",
             "SOFT2202", "Computer Science", 110.0, .good,
             "textbook-dsa", 1),

            ("Digital Fundamentals",
             "Floyd. Paperback. Excellent condition. Used for ELCT1301.",
             "ELCT1301", "Electrical", 95.0, .new,
             "textbook-digital", 6),

            ("Organic Chemistry Textbook",
             "Clayden 2nd edition. Minor water damage on back cover, otherwise clean.",
             "CHEM2401", "Applied Sciences", 130.0, .fair,
             "textbook-organic", 7),

            ("Introduction to Business Statistics",
             "Used for BUSI2305. Some chapters have pencil notes. Includes formula sheet.",
             "BUSI2305", "Business", 80.0, .good,
             "textbook-stats", 2),

            ("Mechanical Engineering Drawing Kit",
             "Complete drafting kit: T-square, triangles, compass, protractor. Excellent for MECH1102.",
             "MECH1102", "Industrial Trades", 150.0, .good,
             "labkit-drawing", 3),

            ("Welding Fundamentals Lab Kit",
             "Safety goggles, gloves, and practice materials. Barely used.",
             "WELD1201", "Industrial Trades", 120.0, .likeNew,
             "labkit-welding", 4),

            ("English Academic Writing Guide",
             "Used for ENGL1001. Notes and annotations throughout. Still very usable.",
             "ENGL1001", "English Language", 40.0, .fair,
             "notes-english", 5),

            ("Network+ Certification Study Guide",
             "Exam N10-008. Like new, no highlighting. Used for ITEC2401.",
             "ITEC2401", "Information Technology", 140.0, .likeNew,
             "textbook-network", 6),

            ("Microbiology Lecture Notes (Printed)",
             "Complete semester notes printed and bound. Covers HSCI2204. Clean copy.",
             "HSCI2204", "Health Sciences", 50.0, .good,
             "notes-microbio", 7),

            ("Physics for Scientists & Engineers",
             "Serway 10th edition. Hardcover. Excellent condition. Used for PHYS1302.",
             "PHYS1302", "Applied Sciences", 200.0, .new,
             "textbook-physics", 1),

            ("Financial Accounting Textbook",
             "Weygandt, Kimmel, Kieso. Like new. Used for ACCT1201.",
             "ACCT1201", "Business", 160.0, .likeNew,
             "textbook-accounting", 2),

            ("C++ Programming: From Problem Analysis",
             "Malik 8th edition. Slightly worn cover. Used for SOFT1202.",
             "SOFT1202", "Computer Science", 85.0, .good,
             "textbook-cpp", 3),

            ("Electronic Devices & Circuit Theory",
             "Boylestad. Hardcover. Minor highlighting. Used for ELCT2201.",
             "ELCT2201", "Electrical", 170.0, .good,
             "textbook-electronic", 4),

            ("Precalculus: Mathematics for Calculus",
             "Stewart. Paperback. Light wear. Used for MATH1301.",
             "MATH1301", "Mathematics", 70.0, .fair,
             "textbook-precalc", 5),

            ("Database Systems Design",
             "Connolly & Begg 7th edition. Excellent condition. Used for SOFT2301.",
             "SOFT2301", "Computer Science", 145.0, .likeNew,
             "textbook-database", 6)
        ]

        for (idx, listing) in sampleListings.enumerated() {
            let seller = users[listing.7]
            let title = listing.0
            let desc = listing.1
            let course = listing.2
            let subject = listing.3
            let price = listing.4
            let condition = listing.5
            let imageKey = listing.6

            // Stagger creation times over the past 30 days
            let daysAgo = Double(idx)
            let created = Date().addingTimeInterval(-daysAgo * 86400)

            listings.append(Listing(
                id: "listing-\(idx+1)",
                sellerID: seller.id,
                title: title,
                description: desc,
                courseCode: course,
                subject: subject,
                price: price,
                condition: condition,
                imageURLs: [imageKey],
                status: .active,
                moderationStatus: .approved,
                createdAt: created,
                updatedAt: created
            ))
        }

        // Two flagged listings for the moderation queue
        listings.append(Listing(
            id: "listing-flagged-1",
            sellerID: "student-demo",
            title: "Final Exam Answer Key for SOFT2202",
            description: "Contains answer key for the upcoming final exam cheat sheet.",
            courseCode: "SOFT2202",
            subject: "Computer Science",
            price: 200.0,
            condition: .new,
            imageURLs: ["notes-cheat"],
            status: .active,
            moderationStatus: .flagged,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600)
        ))

        // A couple of sold listings + completed transactions for history/ratings
        if let calc = listings.first(where: { $0.title.contains("Calculus") }),
           let buyer = users.first(where: { $0.id == "student-demo" }) {
            var soldListing = calc
            soldListing.status = .sold
            if let idx = listings.firstIndex(where: { $0.id == calc.id }) {
                listings[idx] = soldListing
            }
            let tx = Transaction.make(listing: soldListing, buyerID: buyer.id)
            transactions.append(tx)
        }
    }

    // MARK: - CRUD helpers (used by service implementations)

    func upsertUser(_ user: User) {
        if let idx = users.firstIndex(where: { $0.id == user.id }) {
            users[idx] = user
        } else {
            users.append(user)
        }
        saveToDisk()
    }

    func upsertListing(_ listing: Listing) {
        if let idx = listings.firstIndex(where: { $0.id == listing.id }) {
            listings[idx] = listing
        } else {
            listings.append(listing)
        }
        saveToDisk()
    }

    func upsertTransaction(_ tx: Transaction) {
        if let idx = transactions.firstIndex(where: { $0.id == tx.id }) {
            transactions[idx] = tx
        } else {
            transactions.append(tx)
        }
        saveToDisk()
    }

    func upsertRating(_ rating: Rating) {
        if let idx = ratings.firstIndex(where: { $0.id == rating.id }) {
            ratings[idx] = rating
        } else {
            ratings.append(rating)
        }
        saveToDisk()
    }

    func upsertReport(_ report: Report) {
        if let idx = reports.firstIndex(where: { $0.id == report.id }) {
            reports[idx] = report
        } else {
            reports.append(report)
        }
        saveToDisk()
    }

    func getUser(id: String) -> User? { users.first { $0.id == id } }
    func getListing(id: String) -> Listing? { listings.first { $0.id == id } }

    func setCredential(email: String, password: String) {
        credentials[email] = password
    }

    func checkCredential(email: String, password: String) -> User? {
        guard credentials[email]?.lowercased() == password.lowercased() else { return nil }
        return users.first { $0.universityEmail.lowercased() == email.lowercased() }
    }

    func findUser(email: String) -> User? {
        users.first { $0.universityEmail.lowercased() == email.lowercased() }
    }

    func addPendingVerification(_ userID: String) { pendingVerification.insert(userID) }
    func removePendingVerification(_ userID: String) { pendingVerification.remove(userID) }
    func isPendingVerification(_ userID: String) -> Bool { pendingVerification.contains(userID) }

    // MARK: - Disk persistence

    struct Snapshot: Codable {
        var users: [User]
        var listings: [Listing]
        var transactions: [Transaction]
        var ratings: [Rating]
        var reports: [Report]
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: diskURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        users = snap.users
        listings = snap.listings
        transactions = snap.transactions
        ratings = snap.ratings
        reports = snap.reports
    }

    func saveToDisk() {
        let snap = Snapshot(users: users, listings: listings, transactions: transactions, ratings: ratings, reports: reports)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: diskURL, options: .atomic)
        }
    }

    func resetAll() {
        users.removeAll()
        listings.removeAll()
        transactions.removeAll()
        ratings.removeAll()
        reports.removeAll()
        credentials.removeAll()
        pendingVerification.removeAll()
        seed()
        saveToDisk()
    }
}
