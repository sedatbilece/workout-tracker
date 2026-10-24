import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ProfileView: View {
    @AppStorage("profileName")      private var name: String = ""
    @AppStorage("profileSurname")   private var surname: String = ""
    @AppStorage("profilePhotoData") private var photoData: Data = Data()
    @AppStorage("appTheme")         private var themeRaw: String = AppTheme.system.rawValue
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    @Environment(LocalizationManager.self) private var lm
    @Environment(\.modelContext) private var modelContext

    @State private var showEdit = false
    @State private var showImporter = false
    @State private var infoAlert: InfoAlert?
    @State private var healthExportRunning = false

    private struct InfoAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var body: some View {
        NavigationStack {
            List {
                profileHeader
                themeSection
                dataSection
                if HealthKitService.shared.isAvailable {
                    healthSection
                }
                languageSection
                versionSection
            }
            .navigationTitle(lm["tab_profile"])
        }
        .sheet(isPresented: $showEdit) {
            ProfileEditView(name: $name, surname: $surname, photoData: $photoData)
        }
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

    private var profileHeader: some View {
        Section {
            HStack(spacing: 16) {
                AvatarView(photoData: photoData, name: name, surname: surname, size: 64)

                VStack(alignment: .leading, spacing: 2) {
                    let fullName = [name, surname].filter { !$0.isEmpty }.joined(separator: " ")
                    Text(fullName.isEmpty ? lm["profile_unnamed"] : fullName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(lm["profile_edit_hint"])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { showEdit = true }
            .padding(.vertical, 4)
        }
    }

    private var themeSection: some View {
        Section(lm["profile_section_appearance"]) {
            Picker(lm["profile_theme_label"], selection: $themeRaw) {
                ForEach(AppTheme.allCases, id: \.rawValue) { t in
                    Text(lm[t.labelKey]).tag(t.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
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

    private var languageSection: some View {
        let lang = AppLanguage(rawValue: lm.languageCode) ?? .system
        return Section(lm["profile_section_language"]) {
            NavigationLink(destination: LanguageSettingsView()) {
                HStack(spacing: 10) {
                    Text(lang.flag)
                    Text(lang == .system ? lm["language_system"] : lang.displayName)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var versionSection: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return Section {
            HStack {
                Spacer()
                Text(lm.format("profile_version", version, build))
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }
}

#Preview {
    ProfileView()
        .environment(LocalizationManager())
}
