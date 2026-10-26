import Foundation

// User-facing release notes bundled as ReleaseNotes.json. A new entry is added
// on every dev → main merge (see docs/VERSIONING.md), newest build first.
struct ReleaseNote: Decodable, Identifiable {
    let version: String
    let build: Int
    let date: String
    let notes: [String: [String]]

    var id: Int { build }

    /// Notes in the given language, falling back to English, then Turkish.
    func items(for languageCode: String) -> [String] {
        notes[languageCode] ?? notes["en"] ?? notes["tr"] ?? []
    }

    /// `date` ("yyyy-MM-dd") formatted for the given language.
    func formattedDate(for languageCode: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let parsed = parser.date(from: date) else { return date }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: parsed)
    }

    static func loadAll(bundle: Bundle = .main) -> [ReleaseNote] {
        struct File: Decodable { let releases: [ReleaseNote] }

        guard let url = bundle.url(forResource: "ReleaseNotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data)
        else { return [] }
        return file.releases.sorted { $0.build > $1.build }
    }
}
