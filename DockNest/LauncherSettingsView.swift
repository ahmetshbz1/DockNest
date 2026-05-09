import SwiftUI

struct LauncherSettingsView: View {
    @ObservedObject var viewModel: LauncherViewModel
    let backAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.allSections) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 4)

                            ForEach(section.applications) { application in
                                SettingsApplicationRow(
                                    application: application,
                                    isVisible: visibilityBinding(for: application)
                                )
                            }
                        }
                    }
                }
                .padding(.vertical, 1)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        HStack {
            Button(action: backAction) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))

                    Text("Ayarlar")
                        .font(.system(size: 13, weight: .semibold))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Geri")

            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private func visibilityBinding(for application: InstalledApplication) -> Binding<Bool> {
        Binding(
            get: {
                viewModel.isVisible(application)
            },
            set: { isVisible in
                viewModel.setVisibility(isVisible, for: application)
            }
        )
    }
}

private struct SettingsApplicationRow: View {
    let application: InstalledApplication
    @Binding var isVisible: Bool

    var body: some View {
        Toggle(isOn: $isVisible) {
            HStack(spacing: 10) {
                Image(nsImage: application.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)

                Text(application.name)
                    .font(.system(size: 12))
                    .lineLimit(1)

                Spacer()
            }
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 8)
        .frame(minHeight: 34)
        .background(.quaternary.opacity(0.18), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
