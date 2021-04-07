//
//  AppDelegate.swift
//  QuestionExample
//
//  Created by 北䑓 如法 on 16/3/8.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa
import OAuthSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSAppleEventManager.shared().setEventHandler(self, andSelector:#selector(AppDelegate.handleGetURL(event:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func handleGetURL(event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
           if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue, let url = URL(string: urlString) {
               applicationHandle(url: url)
           }
       }

    class var sharedInstance: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }
    
}

extension AppDelegate {
    func applicationHandle(url: URL) {
        if (url.host == "oauth-callback") {
            OAuthSwift.handle(url: url)
        } else {
            // Google provider is the only one with your.bundle.id url schema.
            OAuthSwift.handle(url: url)
        }
    }
}
