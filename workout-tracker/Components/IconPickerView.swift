import SwiftUI

private let allIcons: [String] = [
    "dumbbell", "dumbbell.fill",
    "figure.strengthtraining.traditional", "figure.strengthtraining.functional",
    "figure.run", "figure.walk", "figure.hiking", "figure.cycling",
    "figure.yoga", "figure.pilates", "figure.jumprope", "figure.rowing",
    "figure.swimming", "figure.boxing", "figure.martial.arts",
    "figure.cooldown", "figure.core.training", "figure.cross.training",
    "figure.flexibility", "figure.highintensity.intervaltraining",
    "sportscourt", "sportscourt.fill",
    "flame", "flame.fill",
    "heart", "heart.fill",
    "bolt", "bolt.fill",
    "star", "star.fill",
    "trophy", "trophy.fill",
    "checkmark.seal", "checkmark.seal.fill",
    "arrow.up", "arrow.up.circle.fill",
    "repeat", "repeat.circle",
    "timer", "stopwatch",
    "hand.raised", "hand.raised.fill",
    "muscle", "figure.arms.open",
]

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 12)]

    var filteredIcons: [String] {
        if searchText.isEmpty { return allIcons }
        return allIcons.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedIcon == icon ? Color.accentColor : Color(.secondarySystemBackground))
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? .white : .primary)
                            }
                            .frame(width: 56, height: 56)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, prompt: "İkon ara")
            .navigationTitle("İkon Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    IconPickerView(selectedIcon: .constant("dumbbell"))
}
