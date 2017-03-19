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

    override func viewDidLoad() {
        super.viewDidLoad()

        QuestionBookmarkManager.sharedManager.setConsumerKey(Config.consumerKey, consumerSecret: Config.consumerSecret)
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

