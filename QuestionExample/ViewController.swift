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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        QuestionBookmarkManager.shared.setConsumerKey(consumerKey: Config.consumerKey, consumerSecret: Config.consumerSecret)
    }

    @IBAction func performAuth(_ sender: Any) {
        if !QuestionBookmarkManager.shared.authorized {
            let bundle = Bundle(identifier: "jp.nyoho.Question")!
            if let vc = QuestionAuthViewController.init(nibName: "QuestionAuthViewController", bundle: bundle) {
                self.presentViewControllerAsModalWindow(vc)
                QuestionBookmarkManager.shared.authenticate(viewController: vc)
            }
        } else {
            print("You already authed.")
        }
    }
    
    @IBAction func signOut(_ sender: Any) {
        QuestionBookmarkManager.shared.signOut()
    }
    
    @IBAction func getBookmark(_ sender: Any) {
        guard let url = URL(string: urlField.stringValue) else { return }
        QuestionBookmarkManager.shared.getMyBookmark(url: url, completion: { (result) in
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

