import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: LauncherViewModel
    @State private var isShowingSettings = false
    @State private var reorderTargetBundleIdentifier: String?
    @State private var draggingApplication: InstalledApplication?
    @State private var dragLocation: CGPoint?
    @State private var dragGrabOffset = CGSize.zero
    @State private var applicationTileFrames: [String: CGRect] = [:]
    private let placement: LauncherPanelPlacement
    private let arrowSize = CGSize(width: 24, height: 12)
    private let cornerRadius: CGFloat = 18
    private static let reorderCoordinateSpace = "application-reorder-space"

    init(placement: LauncherPanelPlacement = .preview) {
        self.placement = placement
        _viewModel = StateObject(
            wrappedValue: LauncherViewModel(
                launcher: WorkspaceAppLauncher()
            )
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            content
                .padding(contentInsets)
            arrow
        }
        .alert("DockNest", isPresented: errorPresented) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isShowingSettings {
                LauncherSettingsView(viewModel: viewModel) {
                    isShowingSettings = false
                }
            } else if viewModel.sections.isEmpty {
                emptyState
            } else {
                applicationSections
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.separator.opacity(0.45), lineWidth: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var applicationSections: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.sections) { section in
                    VStack(alignment: .leading, spacing: 7) {
                        SectionHeader(title: section.title, showsSettings: showsSettingsButton(for: section)) {
                            isShowingSettings = true
                        }

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(section.applications) { application in
                                reorderableApplicationTile(application, in: section)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .coordinateSpace(name: Self.reorderCoordinateSpace)
        .onPreferenceChange(ApplicationTileFramePreferenceKey.self) { frames in
            applicationTileFrames = frames
        }
        .onAppear {
            viewModel.refreshRunningApplications()
        }
    }

    @ViewBuilder
    private func reorderableApplicationTile(_ application: InstalledApplication, in section: ApplicationSection) -> some View {
        ApplicationTile(
            application: application,
            isRunning: viewModel.isRunning(application),
            isReorderTarget: reorderTargetBundleIdentifier == application.bundleIdentifier
        ) {
            guard draggingApplication == nil else {
                draggingApplication = nil
                reorderTargetBundleIdentifier = nil
                return
            }

            viewModel.open(application)
        } dropped: { urls in
            viewModel.open(application, urls: urls)
        }
        .scaleEffect(draggingApplication?.bundleIdentifier == application.bundleIdentifier ? 1.04 : 1)
        .opacity(draggingApplication?.bundleIdentifier == application.bundleIdentifier ? 0.88 : 1)
        .offset(dragOffset(for: application))
        .zIndex(draggingApplication?.bundleIdentifier == application.bundleIdentifier ? 10 : 0)
        .animation(.snappy(duration: 0.16), value: viewModel.sections)
        .background(tileFrameReader(for: application))
        .highPriorityGesture(reorderGesture(for: application, in: section))
    }

    private func enterReorderMode(with application: InstalledApplication) -> Void {
        guard draggingApplication?.bundleIdentifier != application.bundleIdentifier else {
            return
        }

        draggingApplication = application
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }

    private func finishReorder() -> Void {
        draggingApplication = nil
        reorderTargetBundleIdentifier = nil
        dragLocation = nil
        dragGrabOffset = .zero
    }

    private func reorderGesture(for application: InstalledApplication, in section: ApplicationSection) -> some Gesture {
        LongPressGesture(minimumDuration: 0.28)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.reorderCoordinateSpace)))
            .onChanged { value in
                switch value {
                case .first(true):
                    enterReorderMode(with: application)
                case let .second(true, drag?):
                    enterReorderMode(with: application)
                    updateDragLocation(drag, for: application)
                    reorderApplication(application, in: section, at: drag.location)
                default:
                    break
                }
            }
            .onEnded { _ in
                finishReorder()
            }
    }

    private func updateDragLocation(_ drag: DragGesture.Value, for application: InstalledApplication) -> Void {
        if dragLocation == nil, let frame = applicationTileFrames[application.bundleIdentifier] {
            dragGrabOffset = CGSize(
                width: drag.startLocation.x - frame.midX,
                height: drag.startLocation.y - frame.midY
            )
        }

        dragLocation = drag.location
    }

    private func reorderApplication(_ application: InstalledApplication, in section: ApplicationSection, at location: CGPoint) -> Void {
        guard
            draggingApplication?.bundleIdentifier == application.bundleIdentifier,
            let destinationIndex = destinationIndex(for: application, in: section, at: location)
        else {
            reorderTargetBundleIdentifier = nil
            return
        }

        let destinationApplication = section.applications[destinationIndex]
        reorderTargetBundleIdentifier = destinationApplication.bundleIdentifier

        if viewModel.moveApplication(withBundleIdentifier: application.bundleIdentifier, to: destinationIndex, in: section.kind) {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
    }

    private func destinationIndex(for application: InstalledApplication, in section: ApplicationSection, at location: CGPoint) -> Int? {
        let indexedFrames = section.applications.enumerated().compactMap { index, candidate -> (index: Int, application: InstalledApplication, frame: CGRect)? in
            guard let frame = applicationTileFrames[candidate.bundleIdentifier] else {
                return nil
            }

            return (index, candidate, frame)
        }

        guard !indexedFrames.isEmpty else {
            return nil
        }

        if let hovered = indexedFrames.first(where: { $0.frame.insetBy(dx: -6, dy: -6).contains(location) }) {
            guard hovered.application.bundleIdentifier != application.bundleIdentifier else {
                return nil
            }

            return hovered.index
        }

        guard
            let currentFrame = applicationTileFrames[application.bundleIdentifier],
            let lastFrame = indexedFrames.last?.frame,
            location.y >= currentFrame.minY,
            location.y > lastFrame.midY
        else {
            return nil
        }

        return section.applications.count - 1
    }

    private func dragOffset(for application: InstalledApplication) -> CGSize {
        guard
            draggingApplication?.bundleIdentifier == application.bundleIdentifier,
            let dragLocation,
            let frame = applicationTileFrames[application.bundleIdentifier]
        else {
            return .zero
        }

        return CGSize(
            width: dragLocation.x - frame.midX - dragGrabOffset.width,
            height: dragLocation.y - frame.midY - dragGrabOffset.height
        )
    }

    private func tileFrameReader(for application: InstalledApplication) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ApplicationTileFramePreferenceKey.self,
                value: [application.bundleIdentifier: proxy.frame(in: .named(Self.reorderCoordinateSpace))]
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "app.dashed")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)

            Text("Uygulama bulunamadı")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 92), spacing: 8),
            GridItem(.flexible(minimum: 92), spacing: 8),
            GridItem(.flexible(minimum: 92), spacing: 8)
        ]
    }

    private func showsSettingsButton(for section: ApplicationSection) -> Bool {
        section.kind == .ide || (!viewModel.hasVisibleIDESection && section.id == viewModel.sections.first?.id)
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: {
                viewModel.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    private var contentInsets: EdgeInsets {
        switch placement.dockEdge {
        case .bottom:
            return EdgeInsets(top: 0, leading: 0, bottom: arrowSize.height, trailing: 0)
        case .left:
            return EdgeInsets(top: 0, leading: arrowSize.height, bottom: 0, trailing: 0)
        case .right:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: arrowSize.height)
        }
    }

    private var arrow: some View {
        GeometryReader { proxy in
            PopoverArrow(edge: placement.dockEdge)
                .fill(.regularMaterial)
                .overlay {
                    PopoverArrow(edge: placement.dockEdge)
                        .stroke(.separator.opacity(0.35), lineWidth: 1)
                }
                .frame(width: arrowFrame.width, height: arrowFrame.height)
                .offset(arrowOffset(in: proxy.size))
        }
        .allowsHitTesting(false)
    }

    private var arrowFrame: CGSize {
        switch placement.dockEdge {
        case .bottom:
            return arrowSize
        case .left, .right:
            return CGSize(width: arrowSize.height, height: arrowSize.width)
        }
    }

    private func arrowOffset(in size: CGSize) -> CGSize {
        switch placement.dockEdge {
        case .bottom:
            return CGSize(width: placement.anchorOffset - arrowSize.width / 2, height: size.height - arrowSize.height)
        case .left:
            return CGSize(width: 1, height: placement.anchorOffset - arrowSize.width / 2)
        case .right:
            return CGSize(width: size.width - arrowSize.height, height: placement.anchorOffset - arrowSize.width / 2)
        }
    }
}

private struct ApplicationTileFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) -> Void {
        value.merge(nextValue()) { _, newValue in
            newValue
        }
    }
}

#Preview {
    ContentView()
}
