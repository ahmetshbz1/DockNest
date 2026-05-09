import AppKit
import SwiftUI

private enum TooltipEdge {
    case top
    case bottom
}

private struct TooltipBubbleView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.black)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
    }
}

@MainActor
private final class TooltipWindowController {
    static let shared = TooltipWindowController()

    private let panel: NSPanel
    private let hostingView: NSHostingView<TooltipBubbleView>
    private var currentOwner: UUID?

    private init() {
        hostingView = NSHostingView(rootView: TooltipBubbleView(text: ""))
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 2)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient]
        panel.contentView = hostingView
    }

    func show(owner: UUID, text: String, anchorRect: CGRect, edge: TooltipEdge, offsetX: CGFloat, offsetY: CGFloat) -> Void {
        hostingView.rootView = TooltipBubbleView(text: text)
        hostingView.layoutSubtreeIfNeeded()

        let fittingSize = hostingView.fittingSize
        guard fittingSize.width > 0, fittingSize.height > 0 else { return }

        let screen = NSScreen.screens.first { screen in
            screen.frame.intersects(anchorRect)
        } ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? anchorRect.insetBy(dx: -400, dy: -400)
        let margin: CGFloat = 8

        var originX = anchorRect.midX - fittingSize.width / 2 + offsetX
        originX = min(max(originX, visibleFrame.minX + margin), visibleFrame.maxX - fittingSize.width - margin)

        var originY: CGFloat
        switch edge {
        case .bottom:
            originY = anchorRect.minY - fittingSize.height - offsetY
        case .top:
            originY = anchorRect.maxY + offsetY
        }

        if edge == .bottom && originY < visibleFrame.minY + margin {
            originY = anchorRect.maxY + margin
        } else if edge == .top && originY + fittingSize.height > visibleFrame.maxY - margin {
            originY = anchorRect.minY - fittingSize.height - margin
        }

        panel.setFrame(NSRect(origin: NSPoint(x: originX, y: originY), size: fittingSize), display: true)
        panel.orderFrontRegardless()
        currentOwner = owner
    }

    func hide(owner: UUID) -> Void {
        guard currentOwner == owner else { return }
        currentOwner = nil
        panel.orderOut(nil)
    }
}

@MainActor
private final class TooltipAnchorBox {
    weak var view: NSView?

    func screenRect() -> CGRect? {
        guard let view, let window = view.window else { return nil }
        let rectInWindow = view.convert(view.bounds, to: nil)
        return window.convertToScreen(rectInWindow)
    }
}

private struct TooltipAnchorReader: NSViewRepresentable {
    let box: TooltipAnchorBox

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.wantsLayer = false

        DispatchQueue.main.async {
            box.view = view
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) -> Void {
        if box.view !== nsView {
            DispatchQueue.main.async {
                box.view = nsView
            }
        }
    }
}

private struct TooltipModifier: ViewModifier {
    let text: String
    var enabled = true
    var alignment: Alignment = .bottom
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 12

    @State private var isHovered = false
    @State private var anchorBox = TooltipAnchorBox()
    @State private var ownerID = UUID()

    func body(content: Content) -> some View {
        content
            .background(TooltipAnchorReader(box: anchorBox))
            .onHover { hovering in
                guard enabled else {
                    isHovered = false
                    TooltipWindowController.shared.hide(owner: ownerID)
                    return
                }

                isHovered = hovering
                if hovering {
                    showTooltip()
                } else {
                    TooltipWindowController.shared.hide(owner: ownerID)
                }
            }
            .onChange(of: text) { _, _ in
                guard isHovered else { return }
                showTooltip()
            }
            .onDisappear {
                TooltipWindowController.shared.hide(owner: ownerID)
            }
    }

    private func showTooltip() -> Void {
        guard let anchorRect = anchorBox.screenRect() else { return }
        TooltipWindowController.shared.show(
            owner: ownerID,
            text: text,
            anchorRect: anchorRect,
            edge: alignment == .top ? .top : .bottom,
            offsetX: offsetX,
            offsetY: offsetY
        )
    }
}

extension View {
    func dockNestTooltip(_ text: String?, enabled: Bool = true, alignment: Alignment = .bottom, offsetX: CGFloat = 0, offsetY: CGFloat = 12) -> some View {
        modifier(
            TooltipModifier(
                text: text ?? "",
                enabled: enabled && text != nil,
                alignment: alignment,
                offsetX: offsetX,
                offsetY: offsetY
            )
        )
    }
}
