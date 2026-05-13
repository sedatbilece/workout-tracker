import SwiftUI

struct AvatarView: View {
    let photoData: Data
    let name: String
    let surname: String
    let size: CGFloat

    private var initials: String {
        let first = name.first.map(String.init) ?? ""
        let last = surname.first.map(String.init) ?? ""
        let result = (first + last).uppercased()
        return result.isEmpty ? "?" : result
    }

    var body: some View {
        Group {
            if !photoData.isEmpty, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.accentColor.opacity(0.2)
                    Text(initials)
                        .font(.system(size: size * 0.38, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
