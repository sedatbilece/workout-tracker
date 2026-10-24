import Foundation
import SwiftData
import CloudKit

// iCloud sync of the SwiftData store through the user's private CloudKit
// database. The setting is read once at launch; changing it takes effect
// after the app restarts.
enum CloudSync {
    static let containerIdentifier = "iCloud.sedatbilece.workout-tracker"
    static let enabledKey = "iCloudSyncEnabled"

    /// The user's choice in Profile (on by default).
    static var isEnabledSetting: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    /// Whether the running store actually syncs with iCloud.
    private(set) static var isActive = false

    static func makeContainer(schema: Schema) -> ModelContainer {
        if isEnabledSetting {
            let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .private(containerIdentifier))
            do {
                let container = try ModelContainer(for: schema, configurations: [configuration])
                isActive = true
                return container
            } catch {
                // Fall back to the local store so the app keeps working.
                print("iCloud sync unavailable: \(error)")
            }
        }

        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    enum AccountState {
        case available
        case noAccount
        case restricted
        case unknown
    }

    static func accountState() async -> AccountState {
        guard let status = try? await CKContainer(identifier: containerIdentifier).accountStatus() else {
            return .unknown
        }
        switch status {
        case .available: return .available
        case .noAccount: return .noAccount
        case .restricted: return .restricted
        default: return .unknown
        }
    }
}
