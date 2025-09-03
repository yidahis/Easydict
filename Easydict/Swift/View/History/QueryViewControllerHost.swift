//
//  QueryViewControllerHost.swift
//  Easydict
//
//  Created by Assistant on 2025/09/03.
//

import AppKit
import SwiftUI

struct QueryViewControllerHost: NSViewControllerRepresentable {
    final class Coordinator { var controller: EZBaseQueryViewController? }

    // MARK: Inputs

    var selected: HistoryRow?

    func makeNSViewController(context: Context) -> EZBaseQueryViewController {
        let vc = EZBaseQueryViewController()
        context.coordinator.controller = vc
        return vc
    }

    func updateNSViewController(_ nsViewController: EZBaseQueryViewController, context: Context) {
        guard let item = selected else { return }
        nsViewController.inputText = item.query
        nsViewController.retryQuery()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
}
