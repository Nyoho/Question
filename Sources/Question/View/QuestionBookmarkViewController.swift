//
//  File.swift
//  
//
//  Created by 北䑓 如法 on 21/N/16.
//

import Cocoa

public class QuestionBookmarkViewController: NSViewController {
    // MARK: - IBOutlets
    @IBOutlet private weak var titleLabel: NSTextField!
    @IBOutlet private weak var urlLabel: NSTextField!
    @IBOutlet private weak var usersCountLabel: NSTextField!
    @IBOutlet private weak var commentField: NSTextView!
    @IBOutlet private weak var saveButton: NSButton!
    
    // MARK: - Public
    public static func loadFromNib() -> QuestionBookmarkViewController {
        QuestionBookmarkViewController(nibName: "QuestionBookmarkViewController", bundle: Bundle.module)
    }
    
    public func configure(permalink: URL, title: String? = nil, bookmarkCountText: String? = nil) {
        self.permalink = permalink
        if let title {
            self.pendingTitle = title
        }
        if let bookmarkCountText {
            self.pendingUsersCountText = bookmarkCountText
        }
        
        updateViewIfNeeded()
        loadExistingBookmarkIfNeeded()
        loadEntryMetadataIfNeeded()
    }
    
    // MARK: - Private state
    private let bookmarkManager: QuestionBookmarkManager = .shared
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
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCommentField()
        hasLoadedView = true
        updateViewIfNeeded()
        loadExistingBookmarkIfNeeded()
        loadEntryMetadataIfNeeded()
    }
    
    // MARK: - Actions
    @IBAction private func saveBookmark(_ sender: Any) {
        guard let permalink else { return }
        saveButton.isEnabled = false
        
        let comment = commentField.string
        bookmarkManager.postMyBookmark(url: permalink, comment: comment) { [weak self] result in
            DispatchQueue.main.async {
                self?.saveButton.isEnabled = true
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
    
    // MARK: - Helpers
    private func updateViewIfNeeded() {
        guard hasLoadedView else { return }
        titleLabel?.stringValue = pendingTitle ?? ""
        urlLabel?.stringValue = permalink?.absoluteString ?? ""
        let (text, color) = usersCountDisplay()
        usersCountLabel?.stringValue = text
        usersCountLabel?.textColor = color
        updateWindowTitle()
    }
    
    private func loadExistingBookmarkIfNeeded() {
        guard hasLoadedView, let permalink, !isLoadingBookmark else { return }
        
        isLoadingBookmark = true
        bookmarkManager.getMyBookmark(url: permalink) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingBookmark = false
                if case let .success(bookmark) = result {
                    self.setCommentText(bookmark.commentRaw)
                    self.pendingTitle = self.pendingTitle
                    self.hasExistingBookmark = true
                    self.updateViewIfNeeded()
                }
            }
        }
    }
    
    private func loadEntryMetadataIfNeeded() {
        guard hasLoadedView, let permalink, !didRequestEntryMetadata else { return }
        
        didRequestEntryMetadata = true
        bookmarkManager.getEntry(url: permalink) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let entry):
                    self.pendingTitle = entry.title
                    self.usersCount = entry.count
                    self.updateViewIfNeeded()
                case .failure(let error):
                    NSLog("QuestionBookmarkViewController metadata failed: \(error)")
                }
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
    }
    
    private func setCommentText(_ text: String) {
        if let textStorage = commentField?.textStorage {
            let range = NSRange(location: 0, length: textStorage.length)
            let attributed = NSAttributedString(string: text, attributes: commentTextAttributes)
            textStorage.replaceCharacters(in: range, with: attributed)
        } else {
            commentField?.string = text
        }
        commentField?.scrollToBeginningOfDocument(nil)
    }
    
    private func usersCountDisplay() -> (String, NSColor) {
        if let count = usersCount {
            let text = localizedUsersCount(count)
            let color: NSColor = count == 0 ? .secondaryLabelColor : NSColor.systemRed
            return (text, color)
        } else if let text = pendingUsersCountText {
            return (text, .labelColor)
        } else {
            return (localizedUsersCount(0), .secondaryLabelColor)
        }
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
        let key = hasExistingBookmark ? "bookmark_window_title_edit" : "bookmark_window_title_add"
        let fallback = hasExistingBookmark ? "Edit Bookmark" : "Add Bookmark"
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
}
