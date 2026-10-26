import SwiftUI
import UIKit

/// VStack içinde kullanılabilen swipe-to-reveal bileşeni.
/// List.swipeActions'ın aksine ScrollView içindeki VStack'lerde çalışır.
/// Sola kaydırınca sağda `trailing` butonları, sağa kaydırınca solda
/// `leading` butonları açılır. Kenardaki (en dıştaki) buton `fullSwipe`
/// ise satır sonuna kadar kaydırıldığında o buton dokunmadan çalışır,
/// Mail'deki gibi.
/// Butonlar List'teki sistem kaydırma butonlarına benzer şekilde çizilir.
struct SwipeRow<Content: View>: View {
    /// Revealed by swiping right; the first one is on the far left.
    var leading: [SwipeAction] = []
    /// Revealed by swiping left; the last one is on the far right.
    var trailing: [SwipeAction] = []
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    /// Offset when the current drag began; nil while not dragging.
    @State private var dragStartOffset: CGFloat? = nil
    @State private var rowWidth: CGFloat = 0

    private let actionWidth: CGFloat = 74

    private var leadingWidth: CGFloat { actionWidth * CGFloat(leading.count) }
    private var trailingWidth: CGFloat { actionWidth * CGFloat(trailing.count) }

    private var leadingFullSwipe: SwipeAction? { leading.first.flatMap { $0.fullSwipe ? $0 : nil } }
    private var trailingFullSwipe: SwipeAction? { trailing.last.flatMap { $0.fullSwipe ? $0 : nil } }

    /// How far the row has to travel before a full swipe fires on release.
    private var fullSwipeDistance: CGFloat { max(rowWidth * 0.55, max(leadingWidth, trailingWidth) + 24) }

    /// The full-swipe action that would run if the finger lifted now.
    private var armedAction: SwipeAction? {
        if offset >= fullSwipeDistance { return leadingFullSwipe }
        if -offset >= fullSwipeDistance { return trailingFullSwipe }
        return nil
    }

    var body: some View {
        ZStack {
            // Buttons sit behind the row; the row slides over them.
            if offset > 0 {
                actionStrip(leading, edge: .leading, revealed: offset)
            } else if offset < 0 {
                actionStrip(trailing, edge: .trailing, revealed: -offset)
            }

            content()
                // Opaque base so the buttons don't show through faded
                // (completed) rows; matches the card background.
                .background(Color(.secondarySystemBackground))
                .contentShape(Rectangle())
                .offset(x: offset)
                .gesture(HorizontalPanGesture(onChanged: dragChanged, onEnded: dragEnded))
        }
        .clipped()
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
        .sensoryFeedback(.impact(weight: .medium), trigger: armedAction?.id) { _, new in new != nil }
        .onChange(of: leading.map(\.id) + trailing.map(\.id)) {
            close()
        }
    }

    // MARK: - Drag

    private func dragChanged(_ translation: CGFloat) {
        let start = dragStartOffset ?? offset
        dragStartOffset = start
        let proposed = start + translation
        if proposed >= 0 {
            offset = limited(proposed, revealWidth: leadingWidth, allowsFullSwipe: leadingFullSwipe != nil)
        } else {
            offset = -limited(-proposed, revealWidth: trailingWidth, allowsFullSwipe: trailingFullSwipe != nil)
        }
    }

    /// Follows the finger all the way when a full swipe is possible,
    /// otherwise a small rubber band past the fully open position.
    private func limited(_ distance: CGFloat, revealWidth: CGFloat, allowsFullSwipe: Bool) -> CGFloat {
        guard revealWidth > 0 else { return 0 }
        if allowsFullSwipe { return min(distance, rowWidth) }
        return distance > revealWidth ? revealWidth + (distance - revealWidth) / 4 : distance
    }

    private func dragEnded(_ translation: CGFloat, _ velocity: CGFloat) {
        defer { dragStartOffset = nil }
        guard dragStartOffset != nil else { return }

        if let action = armedAction {
            close()
            action.perform()
            return
        }

        // Where a flick would carry the row, like List's swipe actions.
        let predicted = offset + velocity * 0.15
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            if predicted > 0, !leading.isEmpty, predicted >= leadingWidth * 0.5 {
                offset = leadingWidth
            } else if predicted < 0, !trailing.isEmpty, -predicted >= trailingWidth * 0.5 {
                offset = -trailingWidth
            } else {
                offset = 0
            }
        }
    }

    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            offset = 0
        }
    }

    // MARK: - Buttons

    /// The buttons of one side. Past the open position the outermost button
    /// stretches to fill the gap; once a full swipe is armed it takes the
    /// whole revealed area.
    private func actionStrip(_ actions: [SwipeAction], edge: HorizontalEdge, revealed: CGFloat) -> some View {
        let open = actionWidth * CGFloat(actions.count)
        let armed = armedAction
        return HStack(spacing: 0) {
            ForEach(actions) { action in
                let isOuter = action.id == (edge == .leading ? actions.first : actions.last)?.id
                let width: CGFloat = if let armed {
                    action.id == armed.id ? revealed : 0
                } else if isOuter, action.fullSwipe {
                    actionWidth + max(0, revealed - open)
                } else {
                    actionWidth
                }
                // A stretched button keeps its icon next to the row, like Mail.
                actionButton(action, alignment: width > actionWidth ? (edge == .leading ? .trailing : .leading) : .center)
                    .frame(width: width)
                    .clipped()
                    .opacity(width == 0 ? 0 : 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: edge == .leading ? .leading : .trailing)
        .opacity(min(1, revealed / (open * 0.6)))
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: armed?.id)
    }

    private func actionButton(_ action: SwipeAction, alignment: Alignment) -> some View {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SwipeAction: Identifiable {
    let title: String
    let icon: String
    let color: Color
    /// Runs without a tap when the row is swiped all the way to this side.
    /// Only honored for the outermost button of a side.
    var fullSwipe = false
    let perform: () -> Void

    var id: String { icon }
}

/// A UIKit pan that only begins for mostly-horizontal drags, so vertical
/// drags that start on a row still scroll the enclosing ScrollView.
/// SwiftUI's DragGesture claims the touch before the direction is known.
private struct HorizontalPanGesture: UIGestureRecognizerRepresentable {
    let onChanged: (CGFloat) -> Void
    let onEnded: (_ translation: CGFloat, _ velocity: CGFloat) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let view = recognizer.view
        switch recognizer.state {
        case .began, .changed:
            onChanged(recognizer.translation(in: view).x)
        case .ended:
            onEnded(recognizer.translation(in: view).x, recognizer.velocity(in: view).x)
        case .cancelled, .failed:
            onEnded(recognizer.translation(in: view).x, 0)
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y) * 1.2
        }
    }
}
