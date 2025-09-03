//
//  HistoryManager.swift
//  Easydict
//
//  Created by Assistant on 2025/09/03.
//

import Foundation

// MARK: - EZHistoryItem

@objcMembers
final class EZHistoryItem: NSObject, Codable {
    // MARK: Lifecycle

    init(
        id: String = UUID().uuidString,
        text: String,
        result: String,
        from: String,
        to: String,
        service: String?,
        date: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.result = result
        self.from = from
        self.to = to
        self.service = service
        self.date = date
    }

    // MARK: Internal

    let id: String
    let text: String
    let result: String
    let from: String
    let to: String
    let service: String?
    let date: Date
}

// MARK: - EZHistoryManager

@objcMembers
final class EZHistoryManager: NSObject {
    // MARK: Lifecycle

    private override init() {
        super.init()
        load()
    }

    // MARK: Internal

    static let shared = EZHistoryManager()

    func allItems() -> [EZHistoryItem] {
        items
    }

    func save(text: String, result: String, from: String, to: String, service: String?) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let item = EZHistoryItem(text: text, result: result, from: from, to: to, service: service)
        items.insert(item, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        persist()
    }

    func clear() {
        items.removeAll()
        persist()
    }

    // MARK: Private

    private let userDefaultsKey = "kQueryHistoryItems"
    private let maxItems = 200
    private var items: [EZHistoryItem] = []

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([EZHistoryItem].self, from: data)
            items = decoded
        } catch {
            items = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            // ignore
        }
    }
}
