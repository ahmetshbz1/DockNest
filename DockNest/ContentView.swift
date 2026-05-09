//
//  ContentView.swift
//  DockNest
//
//  Created by Ahmet on 9.05.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: LauncherViewModel
    @State private var isShowingSettings = false
    private let placement: LauncherPanelPlacement
    private let arrowSize = CGSize(width: 24, height: 12)
    private let cornerRadius: CGFloat = 18

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
                                ApplicationTile(application: application, isRunning: viewModel.isRunning(application)) {
                                    viewModel.open(application)
                                } dropped: { urls in
                                    viewModel.open(application, urls: urls)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            viewModel.refreshRunningApplications()
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

#Preview {
    ContentView()
}
