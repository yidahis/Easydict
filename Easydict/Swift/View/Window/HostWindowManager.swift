//
//  HostWindowManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/26.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation
import SwiftUI

// MARK: - HostWindowManager

/// Bridge host window manager for managing SwiftUI windows.
/// Since SwiftUI windows may cause some strange behaviors, such as showing the window automatically when the app launches, we need to use AppKit to manage the windows.
/// FIX: https://github.com/tisfeng/Easydict/issues/767
final class HostWindowManager {
    // MARK: Internal

    static let shared = HostWindowManager()

    func showWindow<Content: View>(
        windowId: String,
        title: String? = nil,
        width: CGFloat = 700,
        height: CGFloat = 600,
        resizable: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        // Bring app to front so the new window is visible immediately
        NSApp.activate(ignoringOtherApps: true)

        closeWindow(windowId: windowId)

        var styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
        if resizable {
            styleMask.insert(.resizable)
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        window.title = title ?? NSLocalizedString(windowId, comment: "")
        window.titlebarAppearsTransparent = true
        window.center()

        let wrappedContent = content()
            .frame(
                minWidth: width, maxWidth: .infinity,
                minHeight: height, maxHeight: .infinity
            )

        window.contentView = NSHostingView(rootView: wrappedContent)

        let windowController = NSWindowController(window: window)
        windowControllers[windowId] = windowController
        windowController.showWindow(nil)
    }

    func closeWindow(windowId: String) {
        if let windowController = windowControllers[windowId] {
            windowController.close()
            windowControllers.removeValue(forKey: windowId)
        }
    }

    // MARK: Private

    private var windowControllers: [String: NSWindowController] = [:]
}

// MARK: - Window Creation Methods

extension HostWindowManager {
    /// Show the History window.
    func showHistoryWindow() {
        showWindow(
            windowId: "history_window",
            title: NSLocalizedString("history_title", comment: ""),
            width: 1000,
            height: 800
        ) {
            HistoryListView()
        }
    }

    /// Show the About window (stub implementation to satisfy menu command).
    func showAboutWindow() {
        showWindow(
            windowId: "about_window",
            title: NSLocalizedString("menubar.about", comment: ""),
            width: 600,
            height: 220,
            resizable: false
        ) {
            AboutWindowView()
        }
    }
}

// MARK: - AboutWindowView

private struct AboutWindowView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Easydict")
                .font(.title2)
            Text("menubar.about")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
