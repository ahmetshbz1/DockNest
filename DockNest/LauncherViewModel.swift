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
    private static let applicationOrderByKindKey = "applicationOrderByKind"
    private let launcher: AppLaunching
    private var applicationOrderByKind: [String: [String]]
    private var cancellables = Set<AnyCancellable>()

    init(launcher: AppLaunching) {
        let storedApplicationOrder = Self.loadApplicationOrder()

        self.launcher = launcher
        self.errorMessage = nil
        self.applicationOrderByKind = storedApplicationOrder
        self.allSections = Self.applyApplicationOrder(storedApplicationOrder, to: ApplicationDiscovery.discoverSections())
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

    func moveApplication(withBundleIdentifier sourceBundleIdentifier: String, beforeBundleIdentifier destinationBundleIdentifier: String, in kind: ApplicationKind) -> Bool {
        guard sourceBundleIdentifier != destinationBundleIdentifier else {
            return false
        }

        guard let sectionIndex = allSections.firstIndex(where: { $0.kind == kind }) else {
            return false
        }

        var applications = allSections[sectionIndex].applications

        guard let sourceIndex = applications.firstIndex(where: { $0.bundleIdentifier == sourceBundleIdentifier }) else {
            return false
        }

        let movedApplication = applications.remove(at: sourceIndex)

        guard let destinationIndex = applications.firstIndex(where: { $0.bundleIdentifier == destinationBundleIdentifier }) else {
            return false
        }

        applications.insert(movedApplication, at: destinationIndex)
        allSections[sectionIndex] = ApplicationSection(kind: kind, applications: applications)
        applicationOrderByKind[kind.rawValue] = applications.map(\.bundleIdentifier)
        UserDefaults.standard.set(applicationOrderByKind, forKey: Self.applicationOrderByKindKey)

        return true
    }

    func moveApplication(withBundleIdentifier sourceBundleIdentifier: String, to destinationIndex: Int, in kind: ApplicationKind) -> Bool {
        guard let sectionIndex = allSections.firstIndex(where: { $0.kind == kind }) else {
            return false
        }

        var applications = allSections[sectionIndex].applications

        guard let sourceIndex = applications.firstIndex(where: { $0.bundleIdentifier == sourceBundleIdentifier }) else {
            return false
        }

        let movedApplication = applications.remove(at: sourceIndex)
        let boundedDestinationIndex = min(max(destinationIndex, 0), applications.count)

        guard boundedDestinationIndex != sourceIndex else {
            return false
        }

        applications.insert(movedApplication, at: boundedDestinationIndex)
        allSections[sectionIndex] = ApplicationSection(kind: kind, applications: applications)
        applicationOrderByKind[kind.rawValue] = applications.map(\.bundleIdentifier)
        UserDefaults.standard.set(applicationOrderByKind, forKey: Self.applicationOrderByKindKey)

        return true
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

    private static func loadApplicationOrder() -> [String: [String]] {
        UserDefaults.standard.dictionary(forKey: Self.applicationOrderByKindKey) as? [String: [String]] ?? [:]
    }

    private static func applyApplicationOrder(_ orderByKind: [String: [String]], to sections: [ApplicationSection]) -> [ApplicationSection] {
        sections.map { section in
            guard let orderedBundleIdentifiers = orderByKind[section.kind.rawValue] else {
                return section
            }

            let rankByBundleIdentifier = Dictionary(uniqueKeysWithValues: orderedBundleIdentifiers.enumerated().map { index, bundleIdentifier in
                (bundleIdentifier, index)
            })

            let applications = section.applications.sorted { first, second in
                let firstRank = rankByBundleIdentifier[first.bundleIdentifier]
                let secondRank = rankByBundleIdentifier[second.bundleIdentifier]

                switch (firstRank, secondRank) {
                case let (firstRank?, secondRank?):
                    return firstRank < secondRank
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return first.name.localizedStandardCompare(second.name) == .orderedAscending
                }
            }

            return ApplicationSection(kind: section.kind, applications: applications)
        }
    }
}
