import Foundation

enum DockEdge {
    case bottom
    case left
    case right
}

struct LauncherPanelPlacement: Equatable {
    let dockEdge: DockEdge
    let anchorOffset: CGFloat

    static let preview = LauncherPanelPlacement(dockEdge: .bottom, anchorOffset: 196)
}
