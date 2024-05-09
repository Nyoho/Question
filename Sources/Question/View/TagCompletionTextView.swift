//
//  TagCompletionTextView.swift
//  Question
//

import Cocoa

public class TagCompletionTextView: NSTextView {

    public var tagCompletionHelper: TagCompletionHelper?
    public var allTags: [Tag] = []

    private var isShowingCompletion = false
    private var previousTextLength = 0

    // `[`を含むように補完範囲を拡張
    public override var rangeForUserCompletion: NSRange {
        let baseRange = super.rangeForUserCompletion
        let text = self.string
        let cursorPosition = self.selectedRange().location

        // タグプレフィックスを検出
        guard let prefixResult = tagCompletionHelper?.extractTagPrefix(from: text, cursorPosition: cursorPosition) else {
            return baseRange
        }

        // `[`の位置から現在のカーソル位置までを補完範囲とする
        let bracketPosition = prefixResult.bracketPosition
        let length = cursorPosition - bracketPosition
        return NSRange(location: bracketPosition, length: length)
    }

    public override func completions(forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String]? {
        let text = self.string
        let cursorPosition = self.selectedRange().location

        guard let helper = tagCompletionHelper,
              let prefixResult = helper.extractTagPrefix(from: text, cursorPosition: cursorPosition) else {
            return super.completions(forPartialWordRange: charRange, indexOfSelectedItem: index)
        }

        let filteredTags = helper.filterTags(allTags, prefix: prefixResult.prefix)

        if filteredTags.isEmpty {
            return nil
        }

        // `[tag]`の形式で返す
        return filteredTags.map { "[\($0.tag)]" }
    }

    public override func didChangeText() {
        super.didChangeText()

        let text = self.string
        let currentLength = text.count
        let cursorPosition = self.selectedRange().location

        // 削除操作の場合は自動補完をスキップ
        let isDeleting = currentLength < previousTextLength
        previousTextLength = currentLength

        if isDeleting {
            return
        }

        // タグ入力中なら補完を表示
        if tagCompletionHelper?.extractTagPrefix(from: text, cursorPosition: cursorPosition) != nil {
            if !allTags.isEmpty && !isShowingCompletion {
                isShowingCompletion = true
                // 次のランループで実行して、テキスト変更の処理完了後に補完を表示
                DispatchQueue.main.async { [weak self] in
                    self?.complete(nil)
                    self?.isShowingCompletion = false
                }
            }
        }
    }
}
