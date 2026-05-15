import SwiftUI

struct ProfileView: View {
    @AppStorage("profileName")      private var name: String = ""
    @AppStorage("profileSurname")   private var surname: String = ""
    @AppStorage("profilePhotoData") private var photoData: Data = Data()
    @AppStorage("appTheme")         private var themeRaw: String = AppTheme.system.rawValue
    @Environment(LocalizationManager.self) private var lm

    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            List {
                profileHeader
                themeSection
                settingsSection
                languageSection
                versionSection
            }
            .navigationTitle(lm["tab_profile"])
        }
        .sheet(isPresented: $showEdit) {
            ProfileEditView(name: $name, surname: $surname, photoData: $photoData)
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

    private var settingsSection: some View {
        Section(lm["profile_section_settings"]) {
            Text(lm["common_coming_soon"])
                .foregroundStyle(.secondary)
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
