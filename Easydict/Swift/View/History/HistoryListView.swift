//
//  HistoryListView.swift
//  Easydict
//
//  Created by Assistant on 2025/09/03.
//

import AppKit
import Foundation
import SwiftUI

// MARK: - ExportFormat

enum ExportFormat {
    case json
    case csv
}

// MARK: - HistoryListView

struct HistoryListView: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                sidebar
                    .frame(width: 320)
                Divider()
                detail
            }
        }
        .frame(minWidth: 1000, minHeight: 800)
        .onAppear(perform: reload)
        .alert("export_result", isPresented: $showingExportAlert) {
            Button("ok") {
                showingExportAlert = false
            }
        } message: {
            Text(exportAlertMessage)
        }
    }

    // MARK: Private

    @State private var rows: [HistoryRow] = []
    @State private var showRawIds: Set<String> = []
    @State private var selectedId: String?
    @State private var showingExportAlert = false
    @State private var exportAlertMessage = ""

    private var selectedRow: HistoryRow? {
        rows.first { $0.id == selectedId } ?? rows.first
    }

    private var header: some View {
        HStack {
            Text("history_title").font(.headline)
            Spacer()
            HStack(spacing: 8) {
                Menu {
                    Button {
                        exportHistory(format: .json)
                    } label: {
                        Label("export_json", systemImage: "doc.text")
                    }

                    Button {
                        exportHistory(format: .csv)
                    } label: {
                        Label("export_csv", systemImage: "tablecells")
                    }
                } label: {
                    Label("export", systemImage: "square.and.arrow.up")
                }
                .disabled(rows.isEmpty)

                Button(role: .destructive) {
                    EZHistoryManager.shared.clear()
                    reload()
                } label: {
                    Label("clear", systemImage: "trash")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .frame(height: 50)
    }

    private var sidebar: some View {
        List(rows, selection: $selectedId) { row in
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(row.from)
                    Image(systemName: "arrow.right")
                    Text(row.to)
                    Spacer()
                    Text(row.timeString)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .font(.system(size: 10))

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(row.query)
                        .font(.body)
                        .fontWeight(.bold)
                        .lineLimit(2)
                }

                if !row.translated.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(row.translated)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .contextMenu {
                Button("copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(row.query, forType: .string)
                }
                if !row.translated.isEmpty {
                    Button("copy_translated_text") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(row.translated, forType: .string)
                    }
                }
                Divider()
                Button(role: .destructive) {
                    EZHistoryManager.shared.delete(id: row.id)
                    reload()
                } label: {
                    Text("delete")
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var detail: some View {
        QueryViewControllerHost(selected: selectedRow)
            .frame(minWidth: 640)
    }

    private func toggleRaw(_ id: String) {
        if showRawIds.contains(id) {
            showRawIds.remove(id)
        } else {
            showRawIds.insert(id)
        }
    }

    private func reload() {
        var tmp: [HistoryRow] = []
        let items = EZHistoryManager.shared.allItems()
        for item in items {
            let row = HistoryRow(
                id: item.id,
                time: item.date,
                service: item.service ?? "",
                from: item.from,
                to: item.to,
                query: item.text,
                translated: item.result,
                raw: nil
            )
            tmp.append(row)
        }
        rows = tmp
        if selectedId == nil {
            selectedId = rows.first?.id
        }
    }

    private func exportHistory(format: ExportFormat) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = format == .json ? [.json] : [.commaSeparatedText]
        panel.nameFieldStringValue = "Easydict_History_\(Date().timeIntervalSince1970)"

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        do {
            switch format {
            case .json:
                guard let data = EZHistoryManager.shared.exportToJSON() else {
                    throw NSError(
                        domain: "ExportError",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to generate JSON data"]
                    )
                }
                try data.write(to: url)

            case .csv:
                let csvString = EZHistoryManager.shared.exportToCSV()
                try csvString.write(to: url, atomically: true, encoding: .utf8)
            }

            exportAlertMessage = "export_success \(url.lastPathComponent)"
            showingExportAlert = true

        } catch {
            exportAlertMessage = "export_failed \(error.localizedDescription)"
            showingExportAlert = true
        }
    }
}

// MARK: - HistoryRow

struct HistoryRow: Identifiable {
    let id: String
    let time: Date
    let service: String
    let from: String
    let to: String
    let query: String
    let translated: String
    let raw: String?

    var timeString: String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df.string(from: time)
    }
}
