//
//  TagCompletionHelper.swift
//  Question
//

import Foundation

public struct TagPrefixResult {
    public let prefix: String
    public let bracketPosition: Int
}

public struct TagCompletionHelper {

    public init() {}

    /// テキストとカーソル位置から、タグ入力中のプレフィックスを抽出
    /// - Parameters:
    ///   - text: コメントテキスト
    ///   - cursorPosition: カーソル位置（0-indexed）
    /// - Returns: タグプレフィックスとブラケット位置、タグ入力中でなければnil
    public func extractTagPrefix(from text: String, cursorPosition: Int) -> TagPrefixResult? {
        guard cursorPosition >= 0, cursorPosition <= text.count else { return nil }

        let textBeforeCursor = String(text.prefix(cursorPosition))

        // カーソル位置から後ろに向かって`[`を探す
        guard let bracketIndex = textBeforeCursor.lastIndex(of: "[") else {
            return nil
        }

        let bracketPosition = textBeforeCursor.distance(from: textBeforeCursor.startIndex, to: bracketIndex)
        let afterBracket = textBeforeCursor[textBeforeCursor.index(after: bracketIndex)...]

        // `]`が含まれていたら、タグは閉じている
        if afterBracket.contains("]") {
            return nil
        }

        return TagPrefixResult(prefix: String(afterBracket), bracketPosition: bracketPosition)
    }

    /// タグ一覧をプレフィックスでフィルタリングし、count順でソート
    /// - Parameters:
    ///   - tags: タグ一覧
    ///   - prefix: フィルタリング用プレフィックス
    /// - Returns: フィルタリング・ソートされたタグ一覧
    public func filterTags(_ tags: [Tag], prefix: String) -> [Tag] {
        let filtered: [Tag]
        if prefix.isEmpty {
            filtered = tags
        } else {
            let lowercasedPrefix = prefix.lowercased()
            filtered = tags.filter { $0.tag.lowercased().hasPrefix(lowercasedPrefix) }
        }
        return filtered.sorted { $0.count > $1.count }
    }
}
