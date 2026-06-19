import Foundation

/// A single in-memory data store backing all mock services.
/// Concurrency-safe actor. State persists across app launches via JSON on disk.
actor MockStore {
    private let currentSeedVersion = 5

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
    private var storedSeedVersion: Int = 0

    // MARK: - Persistence

    private let diskURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("EduTradeMockStore.json")
    }()

    // MARK: - Init

    func bootstrap() {
        loadFromDisk()
        if storedSeedVersion < currentSeedVersion {
            resetAll()
        } else if users.isEmpty {
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
        let sampleImageAssets = (
            pythonBook: "seed-photo-01",
            graphingCalculator: "seed-photo-02",
            anatomyManual: "seed-photo-11",
            stethoscope: "seed-photo-04",
            mechanicsBook: "seed-photo-05",
            draftingTools: "seed-photo-06",
            businessStatsBook: "seed-photo-07",
            scientificCalculator: "item-graphing-calculator",
            digitalBook: "seed-photo-08",
            multimeter: "item-multimeter",
            calculusBook: "seed-photo-09",
            safetyGoggles: "item-safety-goggles",
            databaseBook: "seed-photo-10",
            englishNotes: "seed-photo-15",
            networkBook: "seed-photo-03",
            laptopDesk: "item-laptop-desk",
            labGoggles: "seed-photo-17",
            welding: "seed-photo-18",
            physicsBook: "seed-photo-19",
            microbioNotes: "seed-photo-20"
        )

        let sampleListings: [(String, String, String, String, Double, Condition, String, Int)] = [
            // title, desc, course, subject, price, condition, imageAsset, sellerIndex
            ("Intro to Python Programming",
             "Used for SOFT1101. Clean pages, a few sticky tabs, and one summary sheet tucked inside.",
             "SOFT1101", "Computer Science", 90.0, .good,
             sampleImageAssets.pythonBook, 1),

            ("TI-84 Plus Graphing Calculator",
             "Used through MATH1401 and MATH1301. Fresh batteries included and all keys work perfectly.",
             "MATH1401", "Mathematics", 210.0, .likeNew,
             sampleImageAssets.graphingCalculator, 2),

            ("Human Anatomy & Physiology Lab Manual",
             "Used for HSCI2103. Spiral binding intact and no pages filled in.",
             "HSCI2103", "Health Sciences", 65.0, .good,
             sampleImageAssets.anatomyManual, 4),

            ("Clinical Stethoscope Starter Kit",
             "Ideal for first-year nursing labs. Includes soft case and spare ear tips.",
             "NURS1202", "Health Sciences", 145.0, .likeNew,
             sampleImageAssets.stethoscope, 5),

            ("Engineering Mechanics: Statics",
             "Hibbeler 14th edition. Hardcover with only light shelf wear.",
             "MECH1201", "Engineering", 180.0, .likeNew,
             sampleImageAssets.mechanicsBook, 2),

            ("Mechanical Drawing Kit",
             "T-square, triangles, compass set, and mechanical pencils for MECH1102 drafting labs.",
             "MECH1102", "Industrial Trades", 150.0, .good,
             sampleImageAssets.draftingTools, 3),

            ("Introduction to Business Statistics",
             "Used for BUSI2305. Includes a formula sheet and neat pencil annotations.",
             "BUSI2305", "Business", 80.0, .good,
             sampleImageAssets.businessStatsBook, 2),

            ("Casio Scientific Calculator",
             "Great for foundation math and physics classes. Screen is clear and solar panel works well.",
             "MATH1301", "Mathematics", 55.0, .good,
             sampleImageAssets.scientificCalculator, 6),

            ("Digital Fundamentals",
             "Used for ELCT1301. Excellent condition with no missing pages or folds.",
             "ELCT1301", "Electrical", 95.0, .new,
             sampleImageAssets.digitalBook, 6),

            ("Digital Multimeter for Circuits Lab",
             "Reliable student meter for ELCT2201. Comes with test leads and pouch.",
             "ELCT2201", "Electrical", 95.0, .good,
             sampleImageAssets.multimeter, 4),

            ("Calculus: Early Transcendentals",
             "Stewart 8th edition. Hardcover in strong condition and ideal for MATH1401.",
             "MATH1401", "Mathematics", 220.0, .likeNew,
             sampleImageAssets.calculusBook, 5),

            ("Safety Goggles + Lab Apron Set",
             "Packed for chemistry and biology practicals. Goggles are anti-fog and apron is freshly cleaned.",
             "CHEM1401", "Applied Sciences", 60.0, .likeNew,
             sampleImageAssets.safetyGoggles, 7),

            ("Database Systems Design",
             "Connolly & Begg 7th edition. Excellent condition for SOFT2301 students.",
             "SOFT2301", "Computer Science", 145.0, .likeNew,
             sampleImageAssets.databaseBook, 6),

            ("English Academic Writing Notes Bundle",
             "Bound lecture notes, essay structure templates, and sample citation pages for ENGL1001.",
             "ENGL1001", "English Language", 40.0, .good,
             sampleImageAssets.englishNotes, 5),

            ("Network+ Certification Study Guide",
             "Exam N10-008 prep guide. Minimal highlighting and a clean cover.",
             "ITEC2401", "Information Technology", 140.0, .likeNew,
             sampleImageAssets.networkBook, 6),

            ("Laptop Stand + Wireless Keyboard Combo",
             "Great for programming sessions in the library or dorm. Folds flat into a backpack.",
             "SOFT2202", "Information Technology", 175.0, .likeNew,
             sampleImageAssets.laptopDesk, 1),

            ("Organic Chemistry Flashcards + Lab Notebook",
             "Revision deck plus a half-used but tidy lab notebook for CHEM2401.",
             "CHEM2401", "Applied Sciences", 45.0, .good,
             sampleImageAssets.labGoggles, 7),

            ("Welding Fundamentals PPE Starter Pack",
             "Protective gloves, sleeves, and practice consumables prepared for WELD1201 labs.",
             "WELD1201", "Industrial Trades", 120.0, .likeNew,
             sampleImageAssets.welding, 4),

            ("Physics Problem-Solving Binder",
             "Worked examples, quizzes, and equation sheets organized for PHYS1302.",
             "PHYS1302", "Applied Sciences", 55.0, .good,
             sampleImageAssets.physicsBook, 1),

            ("Microbiology Lecture Notes (Printed)",
             "Complete semester notes printed and bound for HSCI2204 with clear section tabs.",
             "HSCI2204", "Health Sciences", 50.0, .good,
             sampleImageAssets.microbioNotes, 7)
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
        var seedVersion: Int
        var users: [User]
        var listings: [Listing]
        var transactions: [Transaction]
        var ratings: [Rating]
        var reports: [Report]

        init(seedVersion: Int, users: [User], listings: [Listing], transactions: [Transaction], ratings: [Rating], reports: [Report]) {
            self.seedVersion = seedVersion
            self.users = users
            self.listings = listings
            self.transactions = transactions
            self.ratings = ratings
            self.reports = reports
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            seedVersion = try container.decodeIfPresent(Int.self, forKey: .seedVersion) ?? 0
            users = try container.decode([User].self, forKey: .users)
            listings = try container.decode([Listing].self, forKey: .listings)
            transactions = try container.decode([Transaction].self, forKey: .transactions)
            ratings = try container.decode([Rating].self, forKey: .ratings)
            reports = try container.decode([Report].self, forKey: .reports)
        }
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: diskURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        storedSeedVersion = snap.seedVersion
        users = snap.users
        listings = snap.listings
        transactions = snap.transactions
        ratings = snap.ratings
        reports = snap.reports
    }

    func saveToDisk() {
        let snap = Snapshot(
            seedVersion: currentSeedVersion,
            users: users,
            listings: listings,
            transactions: transactions,
            ratings: ratings,
            reports: reports
        )
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
        storedSeedVersion = currentSeedVersion
        seed()
        saveToDisk()
    }
}
