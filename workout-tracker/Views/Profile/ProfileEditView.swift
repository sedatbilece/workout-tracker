import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Binding var name: String
    @Binding var surname: String
    @Binding var photoData: Data

    @State private var pickerItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    photoPicker
                }

                Section("Kişisel Bilgiler") {
                    TextField("Ad", text: $name)
                    TextField("Soyad", text: $surname)
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { dismiss() }
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
                        .foregroundStyle(.white, Color.accentColor)
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
