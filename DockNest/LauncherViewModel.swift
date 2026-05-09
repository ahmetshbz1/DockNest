import AppKit
import Combine
import Foundation

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published private(set) var allSections: [ApplicationSection]
    @Published private(set) var runningBundleIdentifiers: Set<String>
    @Published private var hiddenBundleIdentifiers: Set<String>
    @Published var errorMessage: String?

    private static let hiddenBundleIdentifiersKey = "hiddenBundleIdentifiers"
    private let launcher: AppLaunching
    private var cancellables = Set<AnyCancellable>()

    init(launcher: AppLaunching) {
        self.launcher = launcher
        self.errorMessage = nil
        self.allSections = ApplicationDiscovery.discoverSections()
        self.runningBundleIdentifiers = Self.resolveRunningBundleIdentifiers()
        self.hiddenBundleIdentifiers = Set(UserDefaults.standard.stringArray(forKey: Self.hiddenBundleIdentifiersKey) ?? [])

        let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter
        workspaceNotificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .merge(with: workspaceNotificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshRunningApplications()
            }
            .store(in: &cancellables)
    }

    var sections: [ApplicationSection] {
        allSections.compactMap { section in
            let visibleApplications = section.applications.filter { application in
                isVisible(application)
            }

            guard !visibleApplications.isEmpty else {
                return nil
            }

            return ApplicationSection(kind: section.kind, applications: visibleApplications)
        }
    }

    var hasVisibleIDESection: Bool {
        sections.contains { section in
            section.kind == .ide
        }
    }

    func isVisible(_ application: InstalledApplication) -> Bool {
        !hiddenBundleIdentifiers.contains(application.bundleIdentifier)
    }

    func setVisibility(_ isVisible: Bool, for application: InstalledApplication) -> Void {
        if isVisible {
            hiddenBundleIdentifiers.remove(application.bundleIdentifier)
        } else {
            hiddenBundleIdentifiers.insert(application.bundleIdentifier)
        }

        UserDefaults.standard.set(Array(hiddenBundleIdentifiers).sorted(), forKey: Self.hiddenBundleIdentifiersKey)
    }

    func isRunning(_ application: InstalledApplication) -> Bool {
        runningBundleIdentifiers.contains(application.bundleIdentifier)
    }

    func open(_ application: InstalledApplication) -> Void {
        open(application, urls: [])
    }

    func open(_ application: InstalledApplication, urls: [URL]) -> Void {
        Task {
            do {
                if urls.isEmpty {
                    try await launcher.open(application)
                } else {
                    try await launcher.open(urls, with: application)
                }

                NSApplication.shared.hide(nil)
            } catch {
                errorMessage = "\(application.name) açılamadı."
            }
        }
    }

    func refreshRunningApplications() -> Void {
        runningBundleIdentifiers = Self.resolveRunningBundleIdentifiers()
    }

    private static func resolveRunningBundleIdentifiers() -> Set<String> {
        Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    }
}
