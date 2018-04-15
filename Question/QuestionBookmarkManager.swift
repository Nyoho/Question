//
//  QuestionBookmarkManager.swift
//  Question
//
//  Created by 北䑓 如法 on 16/3/1.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Foundation
import OAuthSwift
import KeychainAccess

private let questionBookmarkManagerInstance: QuestionBookmarkManager = QuestionBookmarkManager()

public class QuestionBookmarkManager {
    var consumerKey = ""
    var consumerSecret = ""
    public var authorized = false
    let keychain = Keychain()
    var username = ""
    var displayName = ""
    
    var oauthswift = OAuth1Swift(
        consumerKey:     "consumerKey",
        consumerSecret:  "consumerSecret",
        requestTokenUrl: "https://www.hatena.com/oauth/initiate?scope=read_public,write_public",
        authorizeUrl:    "https://www.hatena.ne.jp/oauth/authorize",
        accessTokenUrl:  "https://www.hatena.com/oauth/token"
    )

    public class var shared: QuestionBookmarkManager {
        struct Static {
            static let instance = QuestionBookmarkManager()
        }
        return Static.instance
    }

    public func setConsumerKey(consumerKey: String, consumerSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        oauthswift = OAuth1Swift(
            consumerKey:     consumerKey,
            consumerSecret:  consumerSecret,
            requestTokenUrl: "https://www.hatena.com/oauth/initiate?scope=read_public,write_public",
            authorizeUrl:    "https://www.hatena.ne.jp/oauth/authorize",
            accessTokenUrl:  "https://www.hatena.com/oauth/token"
        )
        checkAuthed()
    }
    
    func checkAuthed() {
        if let username = UserDefaults.standard.string(forKey: "urlName") {
            self.username = username
            if let data = keychain[data: username] {
                do {
                    let credential = try JSONDecoder().decode(OAuthSwiftCredential.self, from: data)
                    oauthswift.client = OAuthSwiftClient(credential: credential)
                    self.displayName = UserDefaults.standard.string(forKey: "displayName") ?? ""
                    authorized = true
                } catch {
                    print("'Cannot retrieve your credential' Error: \(error)")
                }
            }
        }
    }
    
    public func auth(viewController: QuestionAuthViewController) {
        oauthswift.authorizeURLHandler = viewController
        oauthswift.authorize(
            withCallbackURL: URL(string: "https://nyoho.jp/oauth/")!,
            success: { credential, response, parameters in
                print("Authentification succeeded.")
                if let n = parameters["url_name"] as? String {
                    self.username = n
                    UserDefaults.standard.set(n, forKey: "urlName")
                }
                if let n = parameters["display_name"] as? String {
                    self.displayName = n
                    UserDefaults.standard.set(n, forKey: "displayName")
                }
                do {
                    let d = try JSONEncoder().encode(credential)
                    self.keychain[data: self.username] = d
                } catch {
                    print("Error: \(error)")
                }
                self.authorized = true
        },
            failure: { error in
                print("Authentification failed.")
                print(error.localizedDescription)
        })
    }

    public func signOut() {
        keychain["credential"] = nil
        if let vc = QuestionAuthViewController.init(nibName: "QuestionAuthViewController", bundle: Bundle.main) {
            vc.clearCookiesAndSessions()
        }
        oauthswift.client.credential.oauthToken = ""
        oauthswift.client.credential.oauthTokenSecret = ""
        authorized = false
    }
    
    public func getMyBookmark(url: String) {
        oauthswift.client.get(
            "http://api.b.hatena.ne.jp/1/my/bookmark",
            parameters: ["url": url],
            headers: nil,
            success: { response in
                do {
                    let data = response.data
                    if let s = String(bytes: data, encoding: String.Encoding.utf8) {
                        print(s)
                    }
                    let b = try Bookmark(response: response.response, json: data)
                    print(b)
                } catch {
                    print("JSON conversion failed in JSONDecoder", error.localizedDescription)
                }
        },
            failure: { error in
                switch error { // error is OAuthSwiftError
                case .requestError(let e, let request):
                    //requestError[Error Domain=NSURLErrorDomain Code=404 "" UserInfo={Response-Body={"url":"...","message":"Bookmark is not found"}, NSErrorFailingURLKey=http://api.b.hatena.ne.jp/1/my/bookmark?url=..., Response-Headers={...
                    print("A request error:")
                    if let s =  (e as NSError).userInfo["Response-Body"] {
                        print(s)
                    }
                default:
                    print("The others' error:")
                    print(error)
                }
        })
    }
}

// MARK:-

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case head = "HEAD"
    case delete = "DELETE"
    case patch = "PATCH"
    case trace = "TRACE"
    case options = "OPTIONS"
    case connect = "CONNECT"
}

protocol QuestionRequest {
    associatedtype Response: Decodable
    
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var credential: OAuthSwiftCredential { get set }
}

extension QuestionRequest {
    var baseURL: URL {
        return URL(string: "http://api.b.hatena.ne.jp/1")!
    }
}
