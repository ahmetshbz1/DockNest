import Foundation

struct ApplicationDiscovery {
    private static let developerToolsCategory = "public.app-category.developer-tools"

    static func discoverSections() -> [ApplicationSection] {
        let applications = discoverApplications()

        return ApplicationKind.allCases.compactMap { kind in
            let groupedApplications = applications.filter { application in
                application.kind == kind
            }

            guard !groupedApplications.isEmpty else {
                return nil
            }

            return ApplicationSection(kind: kind, applications: groupedApplications)
        }
    }

    private static func discoverApplications() -> [InstalledApplication] {
        var seen = Set<String>()

        return applicationURLs()
            .compactMap { url in
                makeApplication(from: url)
            }
            .filter { application in
                seen.insert(application.bundleIdentifier).inserted
            }
            .sorted { first, second in
                first.name.localizedStandardCompare(second.name) == .orderedAscending
            }
    }

    private static func makeApplication(from url: URL) -> InstalledApplication? {
        guard let bundle = Bundle(url: url), let bundleIdentifier = bundle.bundleIdentifier else {
            return nil
        }

        let name = displayName(bundle: bundle, url: url)
        let category = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String

        guard let kind = classify(bundle: bundle, category: category) else {
            return nil
        }

        return InstalledApplication(id: bundleIdentifier, name: name, bundleIdentifier: bundleIdentifier, url: url, kind: kind)
    }

    private static func classify(bundle: Bundle, category: String?) -> ApplicationKind? {
        if declaresShellDocumentSupport(bundle: bundle) {
            return .terminal
        }

        if category == developerToolsCategory {
            return .ide
        }

        return nil
    }

    private static func declaresShellDocumentSupport(bundle: Bundle) -> Bool {
        guard let documentTypes = bundle.object(forInfoDictionaryKey: "CFBundleDocumentTypes") as? [NSDictionary] else {
            return false
        }

        return documentTypes.contains { documentType in
            let role = documentType["CFBundleTypeRole"] as? String
            let contentTypes = documentType["LSItemContentTypes"] as? [String] ?? []

            return role == "Shell" || contentTypes.contains("com.apple.terminal.shell-script")
        }
    }

    private static func displayName(bundle: Bundle, url: URL) -> String {
        if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return displayName
        }

        if let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return bundleName
        }

        return url.deletingPathExtension().lastPathComponent
    }

    private static func applicationURLs() -> [URL] {
        var urls = [URL]()
        let fileManager = FileManager.default

        for directory in searchDirectories() where fileManager.fileExists(atPath: directory.path) {
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                guard url.pathExtension == "app" else {
                    continue
                }

                urls.append(url)
                enumerator.skipDescendants()
            }
        }

        return urls
    }

    private static func searchDirectories() -> [URL] {
        [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Utilities", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
        ]
    }
}
