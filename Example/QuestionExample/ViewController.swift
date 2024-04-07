//
//  ViewController.swift
//  QuestionExample
//
//  Created by 北䑓 如法 on 16/3/8.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa
import Question

class ViewController: NSViewController {

    @IBOutlet weak var urlField: NSTextField!
    @IBOutlet weak var commentField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        QuestionBookmarkManager.shared.setConsumerKey(consumerKey: Config.consumerKey, consumerSecret: Config.consumerSecret)
    }

    @IBAction func performAuth(_ sender: Any) {
        if !QuestionBookmarkManager.shared.authorized {
            let vc = QuestionAuthViewController.loadFromNib()
            self.presentAsModalWindow(vc)
            QuestionBookmarkManager.shared.authenticate(viewController: vc)
            print(vc)
        } else {
            print("You already authed.")
        }
    }
    
    @IBAction func signOut(_ sender: Any) {
        QuestionBookmarkManager.shared.signOut()
    }
    
    @IBAction func getBookmark(_ sender: Any) {
        guard QuestionBookmarkManager.shared.authorized else { return }
        guard let url = URL(string: urlField.stringValue) else { return }
        QuestionBookmarkManager.shared.getMyBookmark(url: url, completion: { (result) in
            switch result {
            case .success(let bookmark):
                print("Bookmark object: \(bookmark)")
                self.commentField.stringValue = bookmark.commentRaw
            case .failure(let error):
                print("error \(error)")
            }
        })
    }
    
    @IBAction func openBookmarkComposer(_ sender: Any) {
        guard QuestionBookmarkManager.shared.authorized else {
            print("You need to authenticate first.")
            return
        }
        guard let url = URL(string: urlField.stringValue) else { return }
        
        let composer = QuestionBookmarkViewController.loadFromNib()
        composer.configure(permalink: url)
        presentAsModalWindow(composer)
    }
    
    @IBAction func postBookmark(_ sender: Any) {
        guard QuestionBookmarkManager.shared.authorized else { return }
        guard let url = URL(string: urlField.stringValue) else { return }
        let comment = commentField.stringValue
        QuestionBookmarkManager.shared.postMyBookmark(url: url, comment: comment, completion: { (result) in
            switch result {
            case .success(let bookmark):
                print("Bookmark object: \(bookmark)")
            case .failure(let error):
                print("error \(error)")
            }
        })
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}
