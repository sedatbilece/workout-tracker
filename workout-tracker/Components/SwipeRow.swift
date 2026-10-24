import SwiftUI

/// VStack içinde kullanılabilen swipe-to-reveal bileşeni.
/// List.swipeActions'ın aksine ScrollView içindeki VStack'lerde çalışır.
/// Sola kaydırınca sağda [Kopyala] [Geri Al] [Sil] butonlarından verilenler
/// açılır; Sil en sağdadır.
/// Butonlar List'teki sistem kaydırma butonlarına benzer şekilde çizilir.
struct SwipeRow<Content: View>: View {
    let onDuplicate: (() -> Void)?
    var onUndo: (() -> Void)? = nil
    let onDelete: (() -> Void)?
    @ViewBuilder let content: () -> Content

    @Environment(LocalizationManager.self) private var lm
    @State private var offset: CGFloat = 0
    /// Offset when the current drag began; nil while not dragging.
    @State private var dragStartOffset: CGFloat? = nil
    /// Decided on the first drag event: only horizontal drags move the row,
    /// vertical ones are left to the enclosing ScrollView.
    @State private var isHorizontalDrag: Bool? = nil

    private let actionWidth: CGFloat = 74

    private var actions: [SwipeAction] {
        var result: [SwipeAction] = []
        if let onDuplicate {
            result.append(SwipeAction(title: lm["common_duplicate"], icon: "plus.rectangle.on.rectangle", color: .blue, perform: onDuplicate))
        }
        if let onUndo {
            result.append(SwipeAction(title: lm["common_undo"], icon: "arrow.uturn.backward", color: .orange, perform: onUndo))
        }
        if let onDelete {
            result.append(SwipeAction(title: lm["common_delete"], icon: "trash", color: .red, perform: onDelete))
        }
        return result
    }

    private var revealWidth: CGFloat {
        actionWidth * CGFloat(actions.count)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Fixed-size buttons behind the row; the row slides over them, so
            // nothing is re-laid out while dragging.
            if offset < 0 {
                HStack(spacing: 0) {
                    ForEach(actions) { action in
                        actionButton(action)
                    }
                }
                .frame(width: revealWidth)
                .opacity(min(1, -offset / (revealWidth * 0.6)))
            }

            content()
                // Opaque base so the buttons don't show through faded
                // (completed) rows; matches the card background.
                .background(Color(.secondarySystemBackground))
                .contentShape(Rectangle())
                .offset(x: offset)
                .gesture(dragGesture)
        }
        .clipped()
        .onChange(of: actions.count) {
            close()
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !actions.isEmpty else { return }
                if isHorizontalDrag == nil {
                    isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                }
                guard isHorizontalDrag == true else { return }

                let start = dragStartOffset ?? offset
                dragStartOffset = start
                let proposed = start + value.translation.width
                // Small rubber band past the fully open position.
                offset = proposed < -revealWidth
                    ? -revealWidth + (proposed + revealWidth) / 4
                    : min(0, proposed)
            }
            .onEnded { value in
                defer {
                    dragStartOffset = nil
                    isHorizontalDrag = nil
                }
                guard isHorizontalDrag == true, let start = dragStartOffset else { return }

                let predicted = start + value.predictedEndTranslation.width
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    offset = -predicted >= revealWidth * 0.5 ? -revealWidth : 0
                }
            }
    }

    private func actionButton(_ action: SwipeAction) -> some View {
        Button {
            close()
            action.perform()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: action.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 40)
                    .background(action.color, in: Capsule())
                Text(action.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: actionWidth)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            offset = 0
        }
    }
}

private struct SwipeAction: Identifiable {
    let title: String
    let icon: String
    let color: Color
    let perform: () -> Void

    var id: String { icon }
}
