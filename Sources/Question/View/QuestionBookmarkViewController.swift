//
//  File.swift
//  
//
//  Created by 北䑓 如法 on 21/N/16.
//

import Cocoa

public class QuestionBookmarkViewController: NSViewController, NSTextViewDelegate, TagInputTextFieldDelegate {
    // MARK: - IBOutlets
    @IBOutlet private weak var titleLabel: NSTextField!
    @IBOutlet private weak var urlLabel: NSTextField!
    @IBOutlet private weak var usersCountLabel: NSTextField!
    @IBOutlet private weak var commentField: TagCompletionTextView!
    @IBOutlet private weak var tagInputField: TagInputTextField!
    @IBOutlet private weak var saveButton: NSButton!
    @IBOutlet private weak var deleteButton: NSButton!
    
    // MARK: - Public
    public static func loadFromNib() -> QuestionBookmarkViewController {
        QuestionBookmarkViewController(nibName: "QuestionBookmarkViewController", bundle: Bundle.module)
    }
    
    public func configure(permalink: URL, title: String? = nil, bookmarkCountText: String? = nil) {
        resetLoadingState()
        self.permalink = permalink
        self.pendingTitle = title
        self.pendingUsersCountText = bookmarkCountText
        
        updateViewIfNeeded()
        loadExistingBookmarkIfNeeded()
        loadEntryMetadataIfNeeded()
    }
    
    // MARK: - Private state
    private let bookmarkManager: QuestionBookmarkManager = .shared
    private let tagCompletionHelper = TagCompletionHelper()
    private lazy var commentTextAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.textColor,
        .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
    ]
    private var permalink: URL?
    private var pendingTitle: String?
    private var pendingUsersCountText: String?
    private var usersCount: UInt?
    private var hasExistingBookmark = false
    private var isLoadingBookmark = false
    private var hasLoadedView = false
    private var didRequestEntryMetadata = false
    private var isEntryLoaded = false
    private var isBookmarkLoaded = false
    private var isShowingCommentPlaceholder = true
    private var pendingCommentText: String?
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCommentField()
        setupTagInputField()
        configureDeleteButtonAppearance()
        hasLoadedView = true
        updateViewIfNeeded()
        loadExistingBookmarkIfNeeded()
        loadEntryMetadataIfNeeded()
        loadTagsForCompletion()
    }
    
    // MARK: - Actions
    @IBAction private func saveBookmark(_ sender: Any) {
        guard let permalink else { return }
        setActionButtonsEnabled(false)
        
        let comment = commentField.string
        bookmarkManager.postMyBookmark(url: permalink, comment: comment) { [weak self] result in
            DispatchQueue.main.async {
                self?.setActionButtonsEnabled(true)
                switch result {
                case .success:
                    self?.view.window?.performClose(nil)
                case .failure(let error):
                    NSSound.beep()
                    NSLog("QuestionBookmarkViewController save failed: \(error)")
                }
            }
        }
    }
    
    @IBAction private func deleteBookmark(_ sender: Any) {
        guard hasExistingBookmark, isBookmarkLoaded, let permalink else { return }
        setActionButtonsEnabled(false)
        bookmarkManager.deleteMyBookmark(url: permalink) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.setActionButtonsEnabled(true)
                    self?.view.window?.performClose(nil)
                case .failure(let error):
                    self?.setActionButtonsEnabled(true)
                    switch error {
                    case .responseParseError(let underlying):
                        if let decodingError = underlying as? DecodingError,
                           case .dataCorrupted = decodingError {
                            // DELETE の 204 など、JSON なしで発生した場合は成功扱い
                            self?.view.window?.performClose(nil)
                            return
                        }
                    case .httpStatus(let code, _):
                        if code == 404 {
                            self?.view.window?.performClose(nil)
                            return
                        }
                    default:
                        break
                    }
                    NSSound.beep()
                    NSLog("QuestionBookmarkViewController delete failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func updateViewIfNeeded() {
        guard hasLoadedView else { return }
        titleLabel?.stringValue = titleDisplayText()
        urlLabel?.stringValue = urlDisplayText()
        let (text, color) = usersCountDisplay()
        usersCountLabel?.stringValue = text
        usersCountLabel?.textColor = color
        updateCommentFieldAppearance()
        updateDeleteButtonVisibility()
        updateWindowTitle()
    }
    
    private func loadExistingBookmarkIfNeeded() {
        guard hasLoadedView, let permalink, !isLoadingBookmark else { return }
        
        isLoadingBookmark = true
        bookmarkManager.getMyBookmark(url: permalink) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingBookmark = false
                switch result {
                case let .success(bookmark):
                    self.setCommentText(bookmark.commentRaw)
                    self.pendingTitle = self.pendingTitle
                    self.hasExistingBookmark = true
                case .failure:
                    self.setCommentText("")
                    self.hasExistingBookmark = false
                }
                self.isBookmarkLoaded = true
                self.updateViewIfNeeded()
            }
        }
    }
    
    private func loadEntryMetadataIfNeeded() {
        guard hasLoadedView, let permalink, !didRequestEntryMetadata else { return }
        
        didRequestEntryMetadata = true
        bookmarkManager.getEntry(url: permalink) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isEntryLoaded = true
                switch result {
                case .success(let entry):
                    self.pendingTitle = entry.title
                    self.usersCount = entry.count
                case .failure(let error):
                    NSLog("QuestionBookmarkViewController metadata failed: \(error)")
                    self.usersCount = nil
                }
                self.updateViewIfNeeded()
            }
        }
    }
    
    private func setupCommentField() {
        commentField.isEditable = true
        commentField.isSelectable = true
        commentField.isRichText = false
        commentField.font = .systemFont(ofSize: NSFont.systemFontSize)
        commentField.textColor = NSColor.textColor
        commentField.backgroundColor = .textBackgroundColor
        commentField.textContainer?.widthTracksTextView = true
        commentField.textContainer?.lineFragmentPadding = 4
        commentField.enclosingScrollView?.hasVerticalScroller = true
        commentField.typingAttributes = commentTextAttributes
        commentField.delegate = self
        commentField.isAutomaticTextCompletionEnabled = true
        commentField.tagCompletionHelper = tagCompletionHelper
        if isShowingCommentPlaceholder {
            showCommentLoadingPlaceholder()
        }
    }

    private func setupTagInputField() {
        tagInputField?.tagCompletionHelper = tagCompletionHelper
        tagInputField?.tagInputDelegate = self
        tagInputField?.isAutomaticTextCompletionEnabled = true
    }
    
    private func setCommentText(_ text: String) {
        pendingCommentText = text
        applyPendingCommentTextIfPossible()
    }
    
    private func applyPendingCommentTextIfPossible() {
        guard hasLoadedView, let text = pendingCommentText else { return }
        if let textStorage = commentField?.textStorage {
            let range = NSRange(location: 0, length: textStorage.length)
            let attributed = NSAttributedString(string: text, attributes: commentTextAttributes)
            textStorage.replaceCharacters(in: range, with: attributed)
        } else {
            commentField?.string = text
        }
        commentField?.textColor = NSColor.textColor
        commentField?.isEditable = true
        isShowingCommentPlaceholder = false
        commentField?.scrollToBeginningOfDocument(nil)
    }
    
    private func titleDisplayText() -> String {
        if let title = pendingTitle, !title.isEmpty {
            return title
        }
        if isEntryLoaded, let urlString = permalink?.absoluteString {
            return urlString
        }
        return localizedString("bookmark_loading_title", fallback: "Loading…")
    }
    
    private func urlDisplayText() -> String {
        if let urlString = permalink?.absoluteString {
            return urlString
        }
        return localizedString("bookmark_loading_url", fallback: "Loading…")
    }
    
    private func updateCommentFieldAppearance() {
        if isBookmarkLoaded {
            applyPendingCommentTextIfPossible()
        } else {
            commentField?.isEditable = false
            if !isShowingCommentPlaceholder {
                showCommentLoadingPlaceholder()
            } else if commentField?.string.isEmpty ?? true {
                showCommentLoadingPlaceholder()
            }
        }
    }
    
    private func usersCountDisplay() -> (String, NSColor) {
        if !isEntryLoaded {
            if let text = pendingUsersCountText {
                return (text, .labelColor)
            }
            let loading = localizedString("bookmark_loading_users", fallback: "Loading…")
            return (loading, .secondaryLabelColor)
        }
        if let count = usersCount {
            let text = localizedUsersCount(count)
            let color: NSColor = count == 0 ? .secondaryLabelColor : .systemRed
            return (text, color)
        }
        return (localizedUsersCount(0), .secondaryLabelColor)
    }
    
    private func localizedUsersCount(_ count: UInt) -> String {
        if count == 0 {
            return localizedString("bookmark_users_zero", fallback: "No bookmarks yet")
        }
        let numberString = numberFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
        let format = localizedString("bookmark_users_count", fallback: "%@ users")
        return String(format: format, numberString)
    }
    
    private func updateWindowTitle() {
        let key: String
        let fallback: String
        if !isEntryLoaded || !isBookmarkLoaded {
            key = "bookmark_window_title_loading"
            fallback = "Loading…"
        } else if hasExistingBookmark {
            key = "bookmark_window_title_edit"
            fallback = "Edit Bookmark"
        } else {
            key = "bookmark_window_title_add"
            fallback = "Add Bookmark"
        }
        let title = localizedString(key, fallback: fallback)
        if let window = view.window {
            window.title = title
        } else {
            self.title = title
        }
    }
    
    private func localizedString(_ key: String, fallback: String) -> String {
        let result = Bundle.module.localizedString(forKey: key, value: nil, table: nil)
        if result == key {
            return fallback
        }
        return result
    }
    
    private func resetLoadingState() {
        isEntryLoaded = false
        isBookmarkLoaded = false
        isLoadingBookmark = false
        hasExistingBookmark = false
        usersCount = nil
        isShowingCommentPlaceholder = true
        pendingCommentText = nil
        if hasLoadedView {
            showCommentLoadingPlaceholder()
        }
    }
    
    private func showCommentLoadingPlaceholder() {
        let placeholder = localizedString("bookmark_loading_comment", fallback: "Loading…")
        commentField?.string = placeholder
        commentField?.isEditable = false
        commentField?.textColor = NSColor.secondaryLabelColor
        isShowingCommentPlaceholder = true
    }

    // MARK: - NSTextViewDelegate
    public func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            saveBookmark(self)
            return true
        }
        return false
    }

    // MARK: - TagInputTextFieldDelegate
    public func tagInputTextField(_ textField: TagInputTextField, didSubmitTag tag: String) {
        insertTagIntoComment(tag)
    }

    private func insertTagIntoComment(_ tag: String) {
        let tagString = "[\(tag)]"
        let comment = commentField.string

        // 既存のタグの終わり位置を探す
        let insertPosition = findTagInsertPosition(in: comment)

        if let textStorage = commentField.textStorage {
            let insertString: String
            if insertPosition == 0 {
                insertString = tagString
            } else if insertPosition < comment.count {
                // タグの後にスペースがなければ追加しない
                insertString = tagString
            } else {
                insertString = tagString
            }

            let attributed = NSAttributedString(string: insertString, attributes: commentTextAttributes)
            textStorage.insert(attributed, at: insertPosition)
        }
    }

    private func findTagInsertPosition(in comment: String) -> Int {
        // コメントの先頭からタグ `[...]` を探して、最後のタグの終わり位置を返す
        var position = 0
        var index = comment.startIndex

        while index < comment.endIndex {
            if comment[index] == "[" {
                // `]`を探す
                if let closeBracket = comment[index...].firstIndex(of: "]") {
                    let nextIndex = comment.index(after: closeBracket)
                    position = comment.distance(from: comment.startIndex, to: nextIndex)
                    index = nextIndex
                    continue
                }
            }
            break
        }

        return position
    }

    private func updateDeleteButtonVisibility() {
        let shouldShow = isBookmarkLoaded && hasExistingBookmark
        deleteButton?.isHidden = !shouldShow
        if shouldShow {
            deleteButton?.isEnabled = saveButton?.isEnabled ?? true
        } else {
            deleteButton?.isEnabled = false
        }
    }
    
    private func setActionButtonsEnabled(_ enabled: Bool) {
        saveButton?.isEnabled = enabled
        if deleteButton?.isHidden == false {
            deleteButton?.isEnabled = enabled
        }
        commentField?.isEditable = enabled && isBookmarkLoaded && !isShowingCommentPlaceholder
    }
    
    private func configureDeleteButtonAppearance() {
        deleteButton?.imagePosition = .imageOnly
        if let image = NSImage(named: NSImage.touchBarDeleteTemplateName) ?? NSImage(named: NSImage.stopProgressTemplateName) {
            image.isTemplate = true
            deleteButton?.image = image
        } else {
            deleteButton?.title = "Delete"
        }
        deleteButton?.toolTip = localizedString("bookmark_delete_tooltip", fallback: "Delete bookmark")
        deleteButton?.isHidden = true
    }

    private func loadTagsForCompletion() {
        bookmarkManager.getMyTags { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tags):
                    self?.commentField?.allTags = tags
                    self?.tagInputField?.allTags = tags
                case .failure:
                    break
                }
            }
        }
    }
}
