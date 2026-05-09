import AppKit
import Foundation
import OSLog

protocol AppLaunching {
    func open(_ application: InstalledApplication) async throws
    func open(_ urls: [URL], with application: InstalledApplication) async throws
}

struct WorkspaceAppLauncher: AppLaunching {
    private let logger = Logger(subsystem: "com.ahmetshbz.DockNest", category: "WorkspaceAppLauncher")

    func open(_ application: InstalledApplication) async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        do {
            try await NSWorkspace.shared.openApplication(at: application.url, configuration: configuration)
        } catch {
            logger.error("Uygulama açılamadı: \(application.bundleIdentifier, privacy: .public)")
            throw error
        }
    }

    func open(_ urls: [URL], with application: InstalledApplication) async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.open(urls, withApplicationAt: application.url, configuration: configuration) { _, error in
                if let error {
                    logger.error("Dosya uygulamayla açılamadı: \(application.bundleIdentifier, privacy: .public)")
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume()
            }
        }
    }
}
