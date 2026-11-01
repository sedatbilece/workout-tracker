import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Binding var name: String
    @Binding var surname: String
    @Binding var photoData: Data
    @Binding var weightKg: Double
    @Binding var heightCm: Double
    @Environment(LocalizationManager.self) private var lm

    @State private var pickerItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    photoPicker
                }

                Section(lm["profile_section_personal"]) {
                    TextField(lm["profile_first_name"], text: $name)
                    TextField(lm["profile_last_name"], text: $surname)
                }

                Section {
                    MeasurementField(title: lm["calc_weight"], unit: lm["set_weight_unit"], value: $weightKg)
                    MeasurementField(title: lm["calc_height"], unit: lm["calc_unit_cm"], value: $heightCm)
                } header: {
                    Text(lm["profile_section_body"])
                } footer: {
                    Text(lm["profile_body_footer"])
                }
            }
            // No keyboard Done button here: its floating capsule covers the
            // weight field at the bottom of the sheet. Save closes the sheet anyway.
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(lm["profile_edit_title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm["common_cancel"]) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm["common_save"]) { dismiss() }
                        .bold()
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private var photoPicker: some View {
        HStack {
            Spacer()
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(photoData: photoData, name: name, surname: surname, size: 90)
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .tint)
                        .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
    }
}
