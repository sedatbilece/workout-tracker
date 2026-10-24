import Foundation
import SwiftData
import CoreTransferable
import UniformTypeIdentifiers

// JSON backup of all templates, workout history and profile details.
// Import merges by `uuid`: records that already exist are skipped, so the
// same file can be restored more than once safely.
struct BackupFile: Codable {
    static let currentFormatVersion = 1

    var formatVersion: Int
    var exportedAt: Date
    var appVersion: String
    var profile: Profile?
    var templates: [WorkoutTemplateRecord]
    var sessions: [WorkoutSessionRecord]

    struct Profile: Codable {
        var name: String
        var surname: String
        var photo: Data?
        var theme: String?
    }

    struct WorkoutTemplateRecord: Codable {
        var uuid: UUID
        var name: String
        var descriptionText: String
        var createdAt: Date
        var updatedAt: Date
        var exercises: [ExerciseTemplateRecord]
    }

    struct ExerciseTemplateRecord: Codable {
        var uuid: UUID
        var name: String
        var iconName: String
        var orderIndex: Int
        var sets: [SetTemplateRecord]
    }

    struct SetTemplateRecord: Codable {
        var uuid: UUID
        var orderIndex: Int
        var defaultKg: Double
        var defaultReps: Int
    }

    struct WorkoutSessionRecord: Codable {
        var uuid: UUID
        var templateNameSnapshot: String
        var date: Date
        var createdAt: Date
        var endedAt: Date?
        var isCompleted: Bool
        var healthKitWorkoutUUID: UUID?
        var exercises: [ExerciseSessionRecord]
    }

    struct ExerciseSessionRecord: Codable {
        var uuid: UUID
        var exerciseTemplateUUID: UUID?
        var nameSnapshot: String
        var iconNameSnapshot: String
        var orderIndex: Int
        var sets: [SetSessionRecord]
    }

    struct SetSessionRecord: Codable {
        var uuid: UUID
        var setTemplateUUID: UUID?
        var orderIndex: Int
        var kg: Double
        var reps: Int
        var isCompleted: Bool
        var completedAt: Date?
    }
}

struct BackupImportResult {
    var templatesAdded = 0
    var templatesSkipped = 0
    var sessionsAdded = 0
    var sessionsSkipped = 0
}

enum BackupError: Error {
    case invalidFile
    case newerFormat
}

struct BackupService {
    // UserDefaults keys used by ProfileView and RootView.
    private enum ProfileKey {
        static let name = "profileName"
        static let surname = "profileSurname"
        static let photo = "profilePhotoData"
        static let theme = "appTheme"
    }

    static func suggestedFileName(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "workout-backup-\(formatter.string(from: date)).json"
    }

    // MARK: - Export

    static func export(context: ModelContext) throws -> Data {
        DataMigrator.run(context: context)

        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.createdAt)]))
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.createdAt)]))

        let file = BackupFile(
            formatVersion: BackupFile.currentFormatVersion,
            exportedAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-",
            profile: exportProfile(),
            templates: templates.map(record(for:)),
            sessions: sessions.map(record(for:))
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(file)
    }

    private static func exportProfile() -> BackupFile.Profile {
        let defaults = UserDefaults.standard
        let photo = defaults.data(forKey: ProfileKey.photo)
        return BackupFile.Profile(
            name: defaults.string(forKey: ProfileKey.name) ?? "",
            surname: defaults.string(forKey: ProfileKey.surname) ?? "",
            photo: photo?.isEmpty == false ? photo : nil,
            theme: defaults.string(forKey: ProfileKey.theme)
        )
    }

    private static func record(for template: WorkoutTemplate) -> BackupFile.WorkoutTemplateRecord {
        BackupFile.WorkoutTemplateRecord(
            uuid: template.uuid ?? UUID(),
            name: template.name,
            descriptionText: template.descriptionText,
            createdAt: template.createdAt,
            updatedAt: template.updatedAt,
            exercises: template.exercises.sorted { $0.orderIndex < $1.orderIndex }.map { exercise in
                BackupFile.ExerciseTemplateRecord(
                    uuid: exercise.uuid ?? UUID(),
                    name: exercise.name,
                    iconName: exercise.iconName,
                    orderIndex: exercise.orderIndex,
                    sets: exercise.sets.sorted { $0.orderIndex < $1.orderIndex }.map { set in
                        BackupFile.SetTemplateRecord(
                            uuid: set.uuid ?? UUID(),
                            orderIndex: set.orderIndex,
                            defaultKg: set.defaultKg,
                            defaultReps: set.defaultReps
                        )
                    }
                )
            }
        )
    }

    private static func record(for session: WorkoutSession) -> BackupFile.WorkoutSessionRecord {
        BackupFile.WorkoutSessionRecord(
            uuid: session.uuid ?? UUID(),
            templateNameSnapshot: session.templateNameSnapshot,
            date: session.date,
            createdAt: session.createdAt,
            endedAt: session.endedAt,
            isCompleted: session.isCompleted,
            healthKitWorkoutUUID: session.healthKitWorkoutUUID,
            exercises: session.exercises.sorted { $0.orderIndex < $1.orderIndex }.map { exercise in
                BackupFile.ExerciseSessionRecord(
                    uuid: exercise.uuid ?? UUID(),
                    exerciseTemplateUUID: exercise.exerciseTemplateUUID,
                    nameSnapshot: exercise.nameSnapshot,
                    iconNameSnapshot: exercise.iconNameSnapshot,
                    orderIndex: exercise.orderIndex,
                    sets: exercise.sets.sorted { $0.orderIndex < $1.orderIndex }.map { set in
                        BackupFile.SetSessionRecord(
                            uuid: set.uuid ?? UUID(),
                            setTemplateUUID: set.setTemplateUUID,
                            orderIndex: set.orderIndex,
                            kg: set.kg,
                            reps: set.reps,
                            isCompleted: set.isCompleted,
                            completedAt: set.completedAt
                        )
                    }
                )
            }
        )
    }

    // MARK: - Import

    static func importBackup(data: Data, context: ModelContext) throws -> BackupImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let file = try? decoder.decode(BackupFile.self, from: data) else {
            throw BackupError.invalidFile
        }
        guard file.formatVersion <= BackupFile.currentFormatVersion else {
            throw BackupError.newerFormat
        }

        let existingTemplates = Set(try context.fetch(FetchDescriptor<WorkoutTemplate>()).compactMap(\.uuid))
        let existingSessions = Set(try context.fetch(FetchDescriptor<WorkoutSession>()).compactMap(\.uuid))
        var result = BackupImportResult()

        for record in file.templates {
            if existingTemplates.contains(record.uuid) {
                result.templatesSkipped += 1
            } else {
                context.insert(makeTemplate(from: record))
                result.templatesAdded += 1
            }
        }
        for record in file.sessions {
            if existingSessions.contains(record.uuid) {
                result.sessionsSkipped += 1
            } else {
                context.insert(makeSession(from: record))
                result.sessionsAdded += 1
            }
        }

        if let profile = file.profile {
            importProfile(profile)
        }

        try context.save()
        return result
    }

    // Only fills in profile details the device doesn't have yet.
    private static func importProfile(_ profile: BackupFile.Profile) {
        let defaults = UserDefaults.standard
        if (defaults.string(forKey: ProfileKey.name) ?? "").isEmpty, !profile.name.isEmpty {
            defaults.set(profile.name, forKey: ProfileKey.name)
        }
        if (defaults.string(forKey: ProfileKey.surname) ?? "").isEmpty, !profile.surname.isEmpty {
            defaults.set(profile.surname, forKey: ProfileKey.surname)
        }
        if (defaults.data(forKey: ProfileKey.photo) ?? Data()).isEmpty, let photo = profile.photo {
            defaults.set(photo, forKey: ProfileKey.photo)
        }
        if defaults.object(forKey: ProfileKey.theme) == nil, let theme = profile.theme {
            defaults.set(theme, forKey: ProfileKey.theme)
        }
    }

    private static func makeTemplate(from record: BackupFile.WorkoutTemplateRecord) -> WorkoutTemplate {
        let template = WorkoutTemplate(name: record.name, descriptionText: record.descriptionText)
        template.uuid = record.uuid
        template.createdAt = record.createdAt
        template.updatedAt = record.updatedAt
        template.exercises = record.exercises.map { exerciseRecord in
            let exercise = ExerciseTemplate(
                name: exerciseRecord.name,
                iconName: exerciseRecord.iconName,
                orderIndex: exerciseRecord.orderIndex
            )
            exercise.uuid = exerciseRecord.uuid
            exercise.sets = exerciseRecord.sets.map { setRecord in
                let set = SetTemplate(
                    orderIndex: setRecord.orderIndex,
                    defaultKg: setRecord.defaultKg,
                    defaultReps: setRecord.defaultReps
                )
                set.uuid = setRecord.uuid
                return set
            }
            return exercise
        }
        return template
    }

    private static func makeSession(from record: BackupFile.WorkoutSessionRecord) -> WorkoutSession {
        let session = WorkoutSession(templateNameSnapshot: record.templateNameSnapshot, date: record.date)
        session.uuid = record.uuid
        session.createdAt = record.createdAt
        session.endedAt = record.endedAt
        session.isCompleted = record.isCompleted
        session.healthKitWorkoutUUID = record.healthKitWorkoutUUID
        session.exercises = record.exercises.map { exerciseRecord in
            let exercise = ExerciseSession(
                exerciseTemplateUUID: exerciseRecord.exerciseTemplateUUID,
                nameSnapshot: exerciseRecord.nameSnapshot,
                iconNameSnapshot: exerciseRecord.iconNameSnapshot,
                orderIndex: exerciseRecord.orderIndex
            )
            exercise.uuid = exerciseRecord.uuid
            exercise.sets = exerciseRecord.sets.map { setRecord in
                let set = SetSession(
                    setTemplateUUID: setRecord.setTemplateUUID,
                    orderIndex: setRecord.orderIndex,
                    kg: setRecord.kg,
                    reps: setRecord.reps
                )
                set.uuid = setRecord.uuid
                set.isCompleted = setRecord.isCompleted
                set.completedAt = setRecord.completedAt
                return set
            }
            return exercise
        }
        return session
    }
}

// Share-sheet item that builds the backup file only when the user picks a destination.
nonisolated struct BackupExport: Transferable {
    let container: ModelContainer

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { item in
            let data = try await MainActor.run {
                try BackupService.export(context: item.container.mainContext)
            }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(await MainActor.run { BackupService.suggestedFileName() })
            try data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
