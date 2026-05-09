import AppKit
import Foundation

struct InstalledApplication: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let url: URL
    let kind: ApplicationKind

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

enum ApplicationKind: String, CaseIterable {
    case ide
    case terminal
    case browser

    var title: String {
        switch self {
        case .ide:
            return "IDE"
        case .terminal:
            return "Terminal"
        case .browser:
            return "Browser"
        }
    }
}

struct ApplicationSection: Identifiable, Hashable {
    let kind: ApplicationKind
    let applications: [InstalledApplication]

    var id: String {
        kind.rawValue
    }

    var title: String {
        kind.title
    }
}
