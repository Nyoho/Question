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
            self.pendingUsersCount = bookmarkCountText
        }
        
        updateViewIfNeeded()
        loadExistingBookmarkIfNeeded()
        loadEntryMetadataIfNeeded()
    }
    
    // MARK: - Private state
    private let bookmarkManager: QuestionBookmarkManager = .shared
    private var permalink: URL?
    private var pendingTitle: String?
    private var pendingUsersCount: String?
    private var isLoadingBookmark = false
    private var hasLoadedView = false
    private var didRequestEntryMetadata = false
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
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
        usersCountLabel?.stringValue = pendingUsersCount ?? "-"
    }
    
    private func loadExistingBookmarkIfNeeded() {
        guard hasLoadedView, let permalink, !isLoadingBookmark else { return }
        
        isLoadingBookmark = true
        bookmarkManager.getMyBookmark(url: permalink) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingBookmark = false
                if case let .success(bookmark) = result {
                    self.commentField?.string = bookmark.commentRaw
                    self.pendingTitle = self.pendingTitle
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
                    self.pendingUsersCount = "\(entry.count) users"
                    self.updateViewIfNeeded()
                case .failure(let error):
                    NSLog("QuestionBookmarkViewController metadata failed: \(error)")
                }
            }
        }
    }
    
}
