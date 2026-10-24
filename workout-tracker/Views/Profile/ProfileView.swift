import SwiftUI

struct ProfileView: View {
    @AppStorage("profileName")      private var name: String = ""
    @AppStorage("profileSurname")   private var surname: String = ""
    @AppStorage("profilePhotoData") private var photoData: Data = Data()
    @AppStorage("appTheme")         private var themeRaw: String = AppTheme.system.rawValue
    @Environment(LocalizationManager.self) private var lm

    @State private var showEdit = false
    @State private var showReleaseNotes = false

    var body: some View {
        NavigationStack {
            List {
                profileHeader
                themeSection
                settingsSection
                versionSection
            }
            .navigationTitle(lm["tab_profile"])
        }
        .sheet(isPresented: $showEdit) {
            ProfileEditView(name: $name, surname: $surname, photoData: $photoData)
        }
        .sheet(isPresented: $showReleaseNotes) {
            ReleaseNotesView()
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

    // iCloud, Apple Health, backup, Live Activity and language live under Settings.
    private var settingsSection: some View {
        Section {
            NavigationLink(destination: SettingsView()) {
                Label(lm["profile_section_settings"], systemImage: "gearshape")
            }
        }
    }

    private var versionSection: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return Section {
            Button {
                showReleaseNotes = true
            } label: {
                VStack(spacing: 4) {
                    Text(lm.format("profile_version", version, build))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                        Text(lm["profile_release_notes"])
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.tint)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(Color.clear)
    }
}

#Preview {
    ProfileView()
        .environment(LocalizationManager())
}
