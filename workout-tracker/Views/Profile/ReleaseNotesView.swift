import SwiftUI

struct ReleaseNotesView: View {
    @Environment(LocalizationManager.self) private var lm
    @Environment(\.dismiss) private var dismiss

    private let releases = ReleaseNote.loadAll()
    private let installedBuild = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")

    private var languageCode: String {
        LocalizationManager.resolve(lm.languageCode)
    }

    var body: some View {
        NavigationStack {
            Group {
                if releases.isEmpty {
                    ContentUnavailableView(
                        lm["release_notes_empty"],
                        systemImage: "doc.text"
                    )
                } else {
                    List(releases) { release in
                        Section {
                            ForEach(release.items(for: languageCode), id: \.self) { item in
                                Label {
                                    Text(item)
                                } icon: {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundStyle(.tint)
                                }
                                .labelStyle(BulletLabelStyle())
                            }
                        } header: {
                            header(for: release)
                        }
                    }
                }
            }
            .navigationTitle(lm["release_notes_title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm["common_close"]) { dismiss() }
                }
            }
        }
    }

    private func header(for release: ReleaseNote) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(lm.format("profile_version", release.version, String(release.build)))
                .font(.headline)
                .foregroundStyle(.primary)
            if release.build == installedBuild {
                Text(lm["release_notes_installed"])
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: Capsule())
            }
            Spacer(minLength: 0)
            Text(release.formattedDate(for: languageCode))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
    }
}

/// Small dot aligned with the first line of a multi-line note.
private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            configuration.icon
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
            configuration.title
                .font(.subheadline)
        }
    }
}

#Preview {
    ReleaseNotesView()
        .environment(LocalizationManager())
}
