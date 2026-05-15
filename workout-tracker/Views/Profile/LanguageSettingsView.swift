import SwiftUI

struct LanguageSettingsView: View {
    @Environment(LocalizationManager.self) private var lm

    var body: some View {
        List {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    lm.languageCode = language.rawValue
                } label: {
                    HStack {
                        Text(language.flag)
                            .font(.title2)
                            .frame(width: 36)

                        Text(language == .system ? lm["language_system"] : language.displayName)
                            .foregroundStyle(.primary)

                        Spacer()

                        if lm.languageCode == language.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle(lm["language_settings_title"])
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
            .environment(LocalizationManager())
    }
}
