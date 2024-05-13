//
//  TagInputTextField.swift
//  Question
//

import Cocoa

public protocol TagInputTextFieldDelegate: AnyObject {
    func tagInputTextField(_ textField: TagInputTextField, didSubmitTag tag: String)
    func tagInputTextFieldDidChangeText(_ textField: TagInputTextField)
}

public class TagInputTextField: NSTextField {

    public weak var tagInputDelegate: TagInputTextFieldDelegate?
    public var tagCompletionHelper: TagCompletionHelper?
    public var allTags: [Tag] = []

    private var lastTriggeredText: String = ""

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        self.delegate = self
        self.placeholderString = "Tag"
    }
}

extension TagInputTextField: NSTextFieldDelegate {

    public func control(_ control: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
        let text = textView.string

        guard let helper = tagCompletionHelper else {
            return []
        }

        let filteredTags = helper.filterTags(allTags, prefix: text)
        return filteredTags.map { $0.tag }
    }

    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            let tag = self.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !tag.isEmpty {
                tagInputDelegate?.tagInputTextField(self, didSubmitTag: tag)
                self.stringValue = ""
            }
            return true
        }
        return false
    }

    public func controlTextDidChange(_ obj: Notification) {
        let currentText = self.stringValue

        tagInputDelegate?.tagInputTextFieldDidChangeText(self)

        // 同じテキストで既にトリガー済みならスキップ
        if currentText == lastTriggeredText {
            return
        }

        // テキストが短くなった（削除）場合はスキップ
        if currentText.count < lastTriggeredText.count {
            lastTriggeredText = currentText
            return
        }

        lastTriggeredText = currentText

        // タグがあり、入力中なら補完を表示
        if !allTags.isEmpty && !currentText.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let fieldEditor = self?.currentEditor() as? NSTextView else { return }
                fieldEditor.complete(nil)
            }
        }
    }
}
