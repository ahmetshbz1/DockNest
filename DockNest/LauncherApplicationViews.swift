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

struct ApplicationTile: View {
    let application: InstalledApplication
    let isRunning: Bool
    let action: () -> Void
    let dropped: ([URL]) -> Void

    @State private var isHovering = false
    @State private var isDropTargeted = false

    var body: some View {
        Button(action: action) {
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
        }
        .buttonStyle(.plain)
        .dropDestination(for: URL.self) { urls, _ in
            dropped(urls)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .onHover { hovering in
            isHovering = hovering
        }
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
        isRunning ? Color.accentColor.opacity(0.9) : Color.primary.opacity(0.35)
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(backgroundColor)
    }

    private var tileBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(isDropTargeted ? Color.accentColor.opacity(0.65) : Color.clear, lineWidth: 1)
    }

    private var backgroundColor: Color {
        if isDropTargeted {
            return Color.accentColor.opacity(0.16)
        }

        if isHovering {
            return Color.primary.opacity(0.06)
        }

        return Color.clear
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
