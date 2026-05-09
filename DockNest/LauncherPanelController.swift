import AppKit
import SwiftUI

@MainActor
final class LauncherPanelController {
    private let panelSize = NSSize(width: 360, height: 420)
    private var panel: NSPanel?
    private var hideAnimationToken = UUID()

    func toggle() -> Void {
        if let panel, panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() -> Void {
        hideAnimationToken = UUID()
        let layout = panelLayout()
        let panel = panel ?? makePanel()
        self.panel = panel

        panel.contentView = NSHostingView(
            rootView: ContentView(placement: layout.placement)
                .frame(width: layout.frame.width, height: layout.frame.height)
        )
        panel.alphaValue = 0
        panel.setFrame(scaledFrame(layout.frame, scale: 0.96), display: false)

        NSApplication.shared.activate()
        panel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
            panel.animator().setFrame(layout.frame, display: true)
        }
    }

    func hide() -> Void {
        guard let panel, panel.isVisible else {
            return
        }

        let token = UUID()
        hideAnimationToken = token

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.10
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self, weak panel] in
            Task { @MainActor [weak self, weak panel] in
                guard self?.hideAnimationToken == token else {
                    return
                }

                panel?.orderOut(nil)
                panel?.alphaValue = 1
            }
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        return panel
    }

    private func panelLayout() -> LauncherPanelLayout {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main ?? NSScreen.screens[0]

        let visibleFrame = screen.visibleFrame
        let dockEdge = dockEdge(on: screen)
        let origin: NSPoint
        let frame: NSRect

        switch dockEdge {
        case .bottom:
            origin = NSPoint(
                x: clamped(mouseLocation.x - panelSize.width / 2, min: visibleFrame.minX + 10, max: visibleFrame.maxX - panelSize.width - 10),
                y: visibleFrame.minY + 8
            )
            frame = NSRect(origin: origin, size: panelSize)
        case .left:
            origin = NSPoint(
                x: visibleFrame.minX + 8,
                y: clamped(mouseLocation.y - panelSize.height / 2, min: visibleFrame.minY + 10, max: visibleFrame.maxY - panelSize.height - 10)
            )
            frame = NSRect(origin: origin, size: panelSize)
        case .right:
            origin = NSPoint(
                x: visibleFrame.maxX - panelSize.width - 8,
                y: clamped(mouseLocation.y - panelSize.height / 2, min: visibleFrame.minY + 10, max: visibleFrame.maxY - panelSize.height - 10)
            )
            frame = NSRect(origin: origin, size: panelSize)
        }

        return LauncherPanelLayout(
            frame: frame,
            placement: LauncherPanelPlacement(
                dockEdge: dockEdge,
                anchorOffset: anchorOffset(mouseLocation: mouseLocation, panelFrame: frame, dockEdge: dockEdge)
            )
        )
    }

    private func dockEdge(on screen: NSScreen) -> DockEdge {
        let frame = screen.frame
        let visibleFrame = screen.visibleFrame

        if visibleFrame.minX > frame.minX {
            return .left
        }

        if visibleFrame.maxX < frame.maxX {
            return .right
        }

        return .bottom
    }

    private func clamped(_ value: CGFloat, min minimum: CGFloat, max maximum: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minimum), maximum)
    }

    private func anchorOffset(mouseLocation: NSPoint, panelFrame: NSRect, dockEdge: DockEdge) -> CGFloat {
        switch dockEdge {
        case .bottom:
            return clamped(mouseLocation.x - panelFrame.minX, min: 28, max: panelFrame.width - 28)
        case .left, .right:
            return clamped(panelFrame.maxY - mouseLocation.y, min: 28, max: panelFrame.height - 28)
        }
    }

    private func scaledFrame(_ frame: NSRect, scale: CGFloat) -> NSRect {
        let widthDelta = frame.width * (1 - scale)
        let heightDelta = frame.height * (1 - scale)

        return frame.insetBy(dx: widthDelta / 2, dy: heightDelta / 2)
    }
}

private struct LauncherPanelLayout {
    let frame: NSRect
    let placement: LauncherPanelPlacement
}
