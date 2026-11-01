import SwiftUI

// Settings → Appearance: light/dark mode and the theme color. `RootView`
// applies both; the theme color also reaches the Live Activity through
// `LiveActivitySync`.
struct AppearanceSettingsView: View {
    @AppStorage("appTheme") private var themeRaw: String = AppTheme.system.rawValue
    @AppStorage(AppAccent.storageKey) private var accent = AppAccent.defaultValue
    @Environment(LocalizationManager.self) private var lm

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 16)]

    var body: some View {
        List {
            Section(lm["profile_theme_label"]) {
                Picker(lm["profile_theme_label"], selection: $themeRaw) {
                    ForEach(AppTheme.allCases, id: \.rawValue) { t in
                        Text(lm[t.labelKey]).tag(t.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AppAccent.allCases, id: \.self) { option in
                        swatch(option)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text(lm["settings_accent_color"])
            } footer: {
                Text(lm["settings_accent_footer"])
            }
        }
        .navigationTitle(lm["profile_section_appearance"])
        .navigationBarTitleDisplayMode(.inline)
    }

    private func swatch(_ option: AppAccent) -> some View {
        Button {
            withAnimation(.snappy) {
                accent = option
            }
        } label: {
            ZStack {
                Circle()
                    .fill(option.color.gradient)
                    .frame(width: 44, height: 44)
                if option == accent {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Circle()
                        .strokeBorder(option.color, lineWidth: 2.5)
                        .frame(width: 54, height: 54)
                }
            }
            .frame(width: 54, height: 54)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lm[option.labelKey])
        .accessibilityAddTraits(option == accent ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
            .environment(LocalizationManager())
    }
}
