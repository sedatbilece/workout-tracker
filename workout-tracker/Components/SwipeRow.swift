import SwiftUI

/// VStack içinde kullanılabilen swipe-to-reveal bileşeni.
/// List.swipeActions'ın aksine ScrollView içindeki VStack'lerde çalışır.
struct SwipeRow<Content: View>: View {
    @ViewBuilder let content: () -> Content
    let onDuplicate: (() -> Void)?
    let onDelete: (() -> Void)?

    @State private var offset: CGFloat = 0
    private let actionWidth: CGFloat = 72

    var body: some View {
        ZStack(alignment: .leading) {
            if let onDuplicate, offset > 0 {
                Button { execute(onDuplicate) } label: {
                    Image(systemName: "plus.rectangle.on.rectangle")
                        .foregroundStyle(.white)
                        .frame(width: offset)
                        .frame(maxHeight: .infinity)
                        .background(Color.blue)
                        .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .buttonStyle(.plain)
            }

            if let onDelete, offset < 0 {
                Button { execute(onDelete) } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.white)
                        .frame(width: -offset)
                        .frame(maxHeight: .infinity)
                        .background(Color.red)
                        .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .buttonStyle(.plain)
            }

            content()
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 15)
                        .onChanged { value in
                            let t = value.translation.width
                            if t < 0, onDelete != nil {
                                offset = max(t, -actionWidth)
                            } else if t > 0, onDuplicate != nil {
                                offset = min(t, actionWidth)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                if abs(offset) >= actionWidth * 0.5 {
                                    offset = offset < 0 ? -actionWidth : actionWidth
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .clipped()
    }

    private func execute(_ action: () -> Void) {
        withAnimation(.spring(response: 0.25)) { offset = 0 }
        action()
    }
}
