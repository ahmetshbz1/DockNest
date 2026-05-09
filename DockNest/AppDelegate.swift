import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panelController = LauncherPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) -> Void {
        NSApplication.shared.setActivationPolicy(.regular)
        panelController.show()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController.toggle()
        return false
    }

    func applicationWillResignActive(_ notification: Notification) -> Void {
        panelController.hide()
    }

}
