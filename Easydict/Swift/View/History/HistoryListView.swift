//
//  HistoryListView.swift
//  Easydict
//
//  Created by Assistant on 2025/09/03.
//

import Foundation
import SwiftUI

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
        .frame(minWidth: 980, minHeight: 620)
        .onAppear(perform: reload)
    }

    // MARK: Private

    @State private var rows: [HistoryRow] = []
    @State private var showRawIds: Set<String> = []
    @State private var selectedId: String?

    private var selectedRow: HistoryRow? {
        rows.first { $0.id == selectedId } ?? rows.first
    }

    private var header: some View {
        HStack {
            Text("history_title").font(.headline)
            Spacer()
            Button(role: .destructive) {
                EZHistoryManager.shared.clear()
                reload()
            } label: {
                Label("clear", systemImage: "trash")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(row.query)
                        .font(.body)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(row.query, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .help("copy")
                    .buttonStyle(.borderless)
                }

                if !row.translated.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(row.translated)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(row.translated, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .help("copy")
                        .buttonStyle(.borderless)
                    }
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
