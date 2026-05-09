import SwiftUI

struct SetTemplateRowView: View {
    @Bindable var set: SetTemplate
    let index: Int

    @FocusState private var kgFocused: Bool
    @FocusState private var repsFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("Set \(index + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            Spacer()

            HStack(spacing: 4) {
                TextField("0", value: $set.defaultKg, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($kgFocused)
                    .frame(width: 60)
                Text("kg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                TextField("0", value: $set.defaultReps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($repsFocused)
                    .frame(width: 48)
                Text("tekrar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
