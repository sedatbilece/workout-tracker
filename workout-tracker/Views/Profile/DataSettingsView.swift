import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// Settings → iCloud, Health & Data: iCloud sync, Apple Health and JSON backup.
struct DataSettingsView: View {
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    @AppStorage(CloudSync.enabledKey) private var iCloudSyncEnabled = true
    @Environment(LocalizationManager.self) private var lm
    @Environment(\.modelContext) private var modelContext

    @State private var showImporter = false
    @State private var infoAlert: InfoAlert?
    @State private var healthExportRunning = false
    @State private var iCloudAccount: CloudSync.AccountState?

    private struct InfoAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var body: some View {
        List {
            iCloudSection
            if HealthKitService.shared.isAvailable {
                healthSection
            }
            dataSection
        }
        .navigationTitle(lm["settings_data_sync"])
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result {
                importBackup(from: url)
            }
        }
        .alert(item: $infoAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text(lm["common_ok"])))
        }
    }

    // MARK: - Sections

    private var iCloudSection: some View {
        Section {
            Toggle(isOn: $iCloudSyncEnabled) {
                Label(lm["profile_icloud_toggle"], systemImage: "icloud")
            }
            if iCloudSyncEnabled, let iCloudAccount {
                iCloudStatusRow(iCloudAccount)
            }
            if iCloudSyncEnabled != CloudSync.isActive {
                Label(lm["profile_icloud_restart_hint"], systemImage: "arrow.clockwise")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text(lm["profile_icloud_footer"])
        }
        .task {
            iCloudAccount = await CloudSync.accountState()
        }
    }

    private func iCloudStatusRow(_ state: CloudSync.AccountState) -> some View {
        let (key, icon, color): (String, String, Color) = switch state {
        case .available:  ("profile_icloud_status_available", "checkmark.icloud", .green)
        case .noAccount:  ("profile_icloud_status_no_account", "xmark.icloud", .orange)
        case .restricted: ("profile_icloud_status_restricted", "exclamationmark.icloud", .orange)
        case .unknown:    ("profile_icloud_status_unknown", "questionmark.circle", .secondary)
        }
        return Label {
            Text(lm[key])
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
        }
        .font(.subheadline)
    }

    private var dataSection: some View {
        Section {
            ShareLink(
                item: BackupExport(container: modelContext.container),
                preview: SharePreview(BackupService.suggestedFileName())
            ) {
                Label(lm["profile_export_backup"], systemImage: "square.and.arrow.up")
            }
            Button {
                showImporter = true
            } label: {
                Label(lm["profile_import_backup"], systemImage: "square.and.arrow.down")
            }
        } header: {
            Text(lm["profile_section_data"])
        } footer: {
            Text(lm["profile_backup_footer"])
        }
    }

    private var healthSection: some View {
        Section {
            Toggle(isOn: Binding(get: { healthKitEnabled }, set: setHealthKitEnabled)) {
                Label {
                    Text(lm["profile_health_toggle"])
                } icon: {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                }
            }
            if healthKitEnabled {
                Button {
                    exportPastToHealth()
                } label: {
                    Label(lm["profile_health_export_past"], systemImage: "arrow.up.heart")
                }
                .disabled(healthExportRunning)
            }
        } header: {
            Text(lm["profile_section_health"])
        } footer: {
            Text(lm["profile_health_footer"])
        }
    }

    // MARK: - Apple Health

    private func setHealthKitEnabled(_ enabled: Bool) {
        guard enabled else {
            healthKitEnabled = false
            return
        }
        Task {
            let granted = await HealthKitService.shared.requestAuthorization()
            healthKitEnabled = granted
            if !granted {
                infoAlert = InfoAlert(title: lm["health_denied_title"], message: lm["health_denied_message"])
            }
        }
    }

    private func exportPastToHealth() {
        healthExportRunning = true
        Task {
            let count = await HealthKitService.shared.exportPast(context: modelContext)
            healthExportRunning = false
            infoAlert = InfoAlert(title: lm["health_export_title"], message: lm.format("health_export_result", count))
        }
    }

    // MARK: - Backup

    private func importBackup(from url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let result = try BackupService.importBackup(data: data, context: modelContext)
            infoAlert = InfoAlert(
                title: lm["backup_import_success_title"],
                message: lm.format(
                    "backup_import_result",
                    result.templatesAdded,
                    result.sessionsAdded,
                    result.templatesSkipped + result.sessionsSkipped
                )
            )
        } catch BackupError.newerFormat {
            infoAlert = InfoAlert(title: lm["backup_import_error_title"], message: lm["backup_import_error_version"])
        } catch {
            infoAlert = InfoAlert(title: lm["backup_import_error_title"], message: lm["backup_import_error_invalid"])
        }
    }
}

#Preview {
    NavigationStack {
        DataSettingsView()
            .environment(LocalizationManager())
    }
}
