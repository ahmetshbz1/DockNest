import SwiftUI

struct DockNestPopoverCircleButtonModifier: ViewModifier {
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .contentShape(Circle())
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .background(Color.primary.opacity(0.055), in: Circle())
            .overlay {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }
}

struct DockNestPopoverCapsuleButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .contentShape(Capsule())
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .background(Color.primary.opacity(0.055), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }
}

extension View {
    func dockNestPopoverCircleButton(size: CGFloat) -> some View {
        modifier(DockNestPopoverCircleButtonModifier(size: size))
    }

    func dockNestPopoverCapsuleButton() -> some View {
        modifier(DockNestPopoverCapsuleButtonModifier())
    }
}
