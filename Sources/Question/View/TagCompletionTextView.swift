//
//  TagCompletionTextView.swift
//  Question
//

import Cocoa

public class TagCompletionTextView: NSTextView {

    public var tagCompletionHelper: TagCompletionHelper?
    public var allTags: [Tag] = []

    private var isInserting = false

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

        // プレフィックスが空（`[`のみ）の場合は選択なしにする
        if prefixResult.prefix.isEmpty {
            index.pointee = -1
        }

        // `[tag]`の形式で返す
        return filteredTags.map { "[\($0.tag)]" }
    }

    public override func insertText(_ string: Any, replacementRange: NSRange) {
        isInserting = true
        super.insertText(string, replacementRange: replacementRange)
        isInserting = false
    }

    public override func didChangeText() {
        super.didChangeText()

        // 挿入操作でない場合はスキップ
        guard isInserting else { return }

        let text = self.string
        let cursorPosition = self.selectedRange().location

        // タグ入力中なら補完を表示
        if tagCompletionHelper?.extractTagPrefix(from: text, cursorPosition: cursorPosition) != nil {
            if !allTags.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    self?.complete(nil)
                }
            }
        }
    }
}
