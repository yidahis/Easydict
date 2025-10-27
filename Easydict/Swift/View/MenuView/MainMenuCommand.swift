//
//  MainMenuCommand.swift
//  Easydict
//
//  Created by Sharker on 2024/2/4.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

struct EasydictMainMenu: Commands {
    // MARK: Internal

    var body: some Commands {
        // Shortcuts
        MainMenuShortcutCommand()

        // Override Help
        CommandGroup(replacing: .help) {
            Button("menu_feedback") {
                openURL(URL(string: "\(EZGithubRepoEasydictURL)/issues")!)
            }
        }

        // Override About
        CommandGroup(replacing: .appInfo) {
            Button {
                HostWindowManager.shared.showAboutWindow()
            } label: {
                Text("menubar.about")
            }
        }

        // Check for updates
        CommandGroup(after: .appInfo, addition: {
            Button {
                Configuration.shared.updater.checkForUpdates()
            } label: {
                Text("check_updates")
            }
        })

        // History Window Shortcut and Clipboard Image OCR
        CommandGroup(after: .appInfo, addition: {
            Button {
                HostWindowManager.shared.showHistoryWindow()
            } label: {
                Text("history_title")
            }
            .keyboardShortcut("g", modifiers: [.command, .option])

            // 添加剪贴板图像识别菜单项
            Button {
                Shortcut.shared.clipboardImageOCR()
            } label: {
                Text("menu_clipboard_image_ocr")
            }
            .keyboardShortcut("e", modifiers: [.option])
        })
    }

    // MARK: Private

    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow
}
