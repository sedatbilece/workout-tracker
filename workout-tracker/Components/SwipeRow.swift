import SwiftUI

/// VStack içinde kullanılabilen swipe-to-reveal bileşeni.
/// List.swipeActions'ın aksine ScrollView içindeki VStack'lerde çalışır.
/// Sola kaydırınca sağda [Kopyala] [Sil] butonları açılır; Sil en sağdadır.
struct SwipeRow<Content: View>: View {
    let onDuplicate: (() -> Void)?
    let onDelete: (() -> Void)?
    @ViewBuilder let content: () -> Content

    @Environment(LocalizationManager.self) private var lm
    @State private var offset: CGFloat = 0
    private let actionWidth: CGFloat = 72

    private var actionCount: Int {
        (onDuplicate == nil ? 0 : 1) + (onDelete == nil ? 0 : 1)
    }

    private var revealWidth: CGFloat {
        actionWidth * CGFloat(actionCount)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if offset < 0 {
                HStack(spacing: 0) {
                    if let onDuplicate {
                        actionButton(lm["common_duplicate"], icon: "plus.rectangle.on.rectangle", color: .blue, action: onDuplicate)
                    }
                    if let onDelete {
                        actionButton(lm["common_delete"], icon: "trash", color: .red, action: onDelete)
                    }
                }
                .frame(width: -offset)
                .frame(maxHeight: .infinity)
            }

            content()
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 15)
                        .onChanged { value in
                            guard actionCount > 0 else { return }
                            let start: CGFloat = isOpen ? -revealWidth : 0
                            offset = min(0, max(start + value.translation.width, -revealWidth))
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                offset = -offset >= revealWidth * 0.5 ? -revealWidth : 0
                            }
                        }
                )
        }
        .clipped()
        .onChange(of: actionCount) {
            withAnimation { offset = 0 }
        }
    }

    private var isOpen: Bool {
        offset <= -revealWidth
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button { execute(action) } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func execute(_ action: () -> Void) {
        withAnimation(.spring(response: 0.25)) { offset = 0 }
        action()
    }
}
