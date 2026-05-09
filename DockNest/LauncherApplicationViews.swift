import AppKit
import SwiftUI

struct SectionHeader: View {
    let title: String
    let showsSettings: Bool
    let settingsAction: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Spacer()

            if showsSettings {
                Button(action: settingsAction) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help("Ayarlar")
                .dockNestTooltip("Ayarlar", alignment: .bottom, offsetY: 8)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct ApplicationKindTabs: View {
    let sections: [ApplicationSection]
    let selectedKind: ApplicationKind
    let showsSettings: Bool
    let selectionChanged: (ApplicationKind) -> Void
    let settingsAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(sections) { section in
                    Button {
                        selectionChanged(section.kind)
                    } label: {
                        Text(section.title)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .frame(minWidth: 62)
                            .background(tabBackground(for: section.kind))
                            .foregroundStyle(tabForeground(for: section.kind))
                    }
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }
            .padding(3)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer(minLength: 8)

            if showsSettings {
                Button(action: settingsAction) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help("Ayarlar")
                .dockNestTooltip("Ayarlar", alignment: .bottom, offsetY: 8)
            }
        }
        .padding(.horizontal, 4)
    }

    private func tabBackground(for kind: ApplicationKind) -> some ShapeStyle {
        kind == selectedKind ? AnyShapeStyle(Color.primary.opacity(0.13)) : AnyShapeStyle(Color.clear)
    }

    private func tabForeground(for kind: ApplicationKind) -> some ShapeStyle {
        kind == selectedKind ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.secondary)
    }
}

struct ApplicationTile: View {
    let application: InstalledApplication
    let isRunning: Bool
    let isHovering: Bool
    let isReorderTarget: Bool
    let dropped: ([URL]) -> Void

    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 6) {
            Image(nsImage: application.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 34, height: 34)

            Text(application.name)
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .truncationMode(.tail)

            runningIndicator
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, minHeight: 82)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background(tileBackground)
        .overlay(tileBorder)
        .dropDestination(for: URL.self) { urls, _ in
            dropped(urls)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(application.name)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var runningIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 5, height: 5)

            Text(statusText)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(statusColor)
        }
        .padding(.top, 1)
    }

    private var statusText: String {
        isRunning ? "Açık" : "Kapalı"
    }

    private var statusColor: Color {
        isRunning ? Color(nsColor: .systemGreen).opacity(0.9) : Color.primary.opacity(0.35)
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(backgroundColor)
    }

    private var tileBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(isDropTargeted || isReorderTarget ? Color.accentColor.opacity(0.65) : Color.clear, lineWidth: 1)
    }

    private var backgroundColor: Color {
        if isDropTargeted || isReorderTarget {
            return Color.accentColor.opacity(0.16)
        }

        if isHovering {
            return Color.primary.opacity(0.06)
        }

        return Color.clear
    }
}

struct ApplicationTileInteractionLayer: NSViewRepresentable {
    let longPressDuration: TimeInterval
    let clicked: () -> Void
    let longPressed: (CGPoint) -> Void
    let dragged: (CGPoint) -> Void
    let hoveringChanged: (Bool) -> Void
    let ended: () -> Void

    func makeNSView(context: Context) -> InteractionView {
        let view = InteractionView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: InteractionView, context: Context) -> Void {
        context.coordinator.layer = self
        nsView.coordinator = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(layer: self)
    }

    final class Coordinator {
        var layer: ApplicationTileInteractionLayer

        init(layer: ApplicationTileInteractionLayer) {
            self.layer = layer
        }
    }

    final class InteractionView: NSView {
        weak var coordinator: Coordinator?
        private var longPressTimer: Timer?
        private var mouseDownLocation = CGPoint.zero
        private var didLongPress = false
        private var didCancelClick = false
        private var trackingArea: NSTrackingArea?
        private let clickMovementTolerance: CGFloat = 8

        override var acceptsFirstResponder: Bool {
            true
        }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }

        override func updateTrackingAreas() {
            if let trackingArea {
                removeTrackingArea(trackingArea)
            }

            super.updateTrackingAreas()

            let trackingArea = NSTrackingArea(
                rect: .zero,
                options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(trackingArea)
            self.trackingArea = trackingArea
        }

        override func mouseEntered(with event: NSEvent) {
            coordinator?.layer.hoveringChanged(true)
        }

        override func mouseExited(with event: NSEvent) {
            coordinator?.layer.hoveringChanged(false)
        }

        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(self)
            mouseDownLocation = convert(event.locationInWindow, from: nil)
            didLongPress = false
            didCancelClick = false

            longPressTimer?.invalidate()
            longPressTimer = Timer.scheduledTimer(withTimeInterval: coordinator?.layer.longPressDuration ?? 1.5, repeats: false) { [weak self] _ in
                guard let self else {
                    return
                }

                didLongPress = true
                coordinator?.layer.longPressed(mouseDownLocation)
            }
        }

        override func mouseDragged(with event: NSEvent) {
            let location = convert(event.locationInWindow, from: nil)

            guard didLongPress else {
                if distance(from: mouseDownLocation, to: location) > clickMovementTolerance {
                    didCancelClick = true
                    longPressTimer?.invalidate()
                    longPressTimer = nil
                }

                return
            }

            coordinator?.layer.dragged(location)
        }

        override func mouseUp(with event: NSEvent) {
            longPressTimer?.invalidate()
            longPressTimer = nil

            if didLongPress {
                coordinator?.layer.ended()
            } else if !didCancelClick {
                coordinator?.layer.clicked()
            }

            didLongPress = false
            didCancelClick = false
        }

        private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
            hypot(second.x - first.x, second.y - first.y)
        }
    }
}

struct PopoverArrow: Shape {
    let edge: DockEdge

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch edge {
        case .bottom:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        case .left:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .right:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }

        path.closeSubpath()
        return path
    }
}
