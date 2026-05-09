//
//  DockNestApp.swift
//  DockNest
//
//  Created by Ahmet on 9.05.2026.
//

import SwiftUI

@main
struct DockNestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
