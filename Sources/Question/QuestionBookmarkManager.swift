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
import AppKit

private let questionBookmarkManagerInstance: QuestionBookmarkManager = QuestionBookmarkManager()

public class QuestionBookmarkManager {
    var consumerKey = ""
    var consumerSecret = ""
    public var authorized: Bool {
        get {
            return credential != nil
        }
    }
    let keychain = Keychain()
    public var username: String? {
        get {
            return UserDefaults.standard.string(forKey: "urlName")
        }
    }
    public var displayName: String? {
        get {
            return UserDefaults.standard.string(forKey: "displayName")
        }
    }
    var credential: OAuthSwiftCredential? {
        get {
            if let username = self.username, let data = keychain[data: username] {
                do {
                    let credential = try JSONDecoder().decode(OAuthSwiftCredential.self, from: data)
                    oauthswift.client = OAuthSwiftClient(credential: credential)
                    return credential

                } catch {
                    print("'Cannot retrieve your credential' Error: \(error)")
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
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
    }
    
    public func authenticate(viewController: QuestionAuthViewController) {
        oauthswift.authorizeURLHandler = viewController
        oauthswift.authorize(withCallbackURL: URL(string: "https://nyoho.jp/hatena")!) { result in
            switch result {
            case .success(let (credential, response, parameters)):
                print("Authentification succeeded.")
                guard let name = parameters["url_name"] as? String else { return }
                UserDefaults.standard.set(name, forKey: "urlName")
                
                guard let displayName = parameters["display_name"] as? String else { return }
                UserDefaults.standard.set(displayName, forKey: "displayName")
                
                do {
                    let d = try JSONEncoder().encode(credential)
                    let u = self.username!
                    self.keychain[data: u] = d
                } catch {
                    print("Error: \(error)")
                }
                viewController.close(self)
            case .failure(let error):
                print("Authentification failed.")
                switch error {
                case .requestError(let networkError, let request): // -11
                    print(networkError)
                    print(request)
                    break // do something with your networkError
                default:
                    break // do something
                }
                print(error.localizedDescription)
            }
        }
    }

    public func performAuthWithModalWindow(_ sender: Any) {
        //この方法では OAuthSwift エラー(-11) になる。400: Bad Request, Response: oauth_problem=parameter_rejected&oauth_parameters_rejected=oauth_token
        let vc = QuestionAuthViewController.loadFromNib()
        if let senderVC = sender as? NSViewController {
            senderVC.presentAsModalWindow(vc)
            QuestionBookmarkManager.shared.authenticate(viewController: vc)
        }
    }

    public func signOut() { // rename to logout?
        keychain["credential"] = nil
        let vc = QuestionAuthViewController(nibName: "QuestionAuthViewController", bundle: Bundle.module)
        vc.clearCookiesAndSessions()

        oauthswift.client.credential.oauthToken = ""
        oauthswift.client.credential.oauthTokenSecret = ""
        UserDefaults.standard.set(nil, forKey: "urlName")
        UserDefaults.standard.set(nil, forKey: "displayName")
    }
    
    public func send<Request: QuestionRequest>(request: Request, completion: @escaping (Result<Request.Response, QuestionError>) -> Void) {
        // TODO: add request.body

        let oauthswiftMethod = { (method: HTTPMethod) -> OAuthSwiftHTTPRequest.Method in
            switch method {
            case .post:
                return .POST
            default:
                return .GET
            }
        }(request.method)

        oauthswift.client.request(request.baseURL.absoluteString + request.path,
                                  method: oauthswiftMethod,
                                  parameters: request.queryItems,
                                  headers: nil,
                                  body: nil) { result in
            switch result {
            case .success(let response):
                do {
                    let data = response.data
                    let b = try request.response(from: data, urlResponse: response.response)
                    completion(Result.success(b))
                } catch {
                    print("JSON conversion failed in JSONDecoder", error.localizedDescription)
                }
            case .failure(let error):
                switch error { // error is OAuthSwiftError
                case .requestError(let e, let request):
                    //requestError[Error Domain=NSURLErrorDomain Code=404 "" UserInfo={Response-Body={"url":"...","message":"Bookmark is not found"}, NSErrorFailingURLKey=http://api.b.hatena.ne.jp/1/my/bookmark?url=..., Response-Headers={...
                    print("A request error: request = \(request)")
                    if let s =  (e as NSError).userInfo["Response-Body"] {
                        print(s)
                    }
                    completion(Result.failure(.connectionError(e)))
                default:
                    print("The others' error:")
                    print(error)
                }
            }
        }
    }

    public func getMyBookmark(url: URL, completion: @escaping (Result<Bookmark, QuestionError>) -> Void) {
        send(request: GetBookmarkRequest(url: url), completion: completion)
    }
    
    public func getEntry(url: URL, completion: @escaping (Result<Entry, QuestionError>) -> Void) {
        send(request: GetEntryRequest(url: url), completion: completion)
    }

    public func postMyBookmark(url: URL, comment: String, tags: [String] = [], postTwitter: Bool = false, postFacebook: Bool = false, postMixi: Bool = false, postEvernote: Bool = false, sendMail: Bool = false, isPrivate: Bool = false, completion: @escaping (Result<Bookmark, QuestionError>) -> Void) {
        let request = PostBookmarkRequest(url: url, comment: comment, tags: tags, postTwitter: postTwitter, postFacebook: postFacebook, postMixi: postMixi, postEvernote: postEvernote, sendMail: sendMail, isPrivate: isPrivate)
        send(request: request, completion: completion)
    }

//
//    public func getMyEntryWithSuccess:(void (^)(HTBMyEntry *myEntry))success
//    failure:(void (^)(NSError *error))failure;
//
//    public func getMyTagsWithSuccess:(void (^)(HTBMyTagsEntry *))success
//    failure:(void (^)(NSError *error))failure;
//
//    public func getBookmarkEntryWithURL:(NSURL *)url
//    success:(void (^)(HTBBookmarkEntry *entry))success
//    failure:(void (^)(NSError *error))failure;
//
//    public func getCanonicalEntryWithURL:(NSURL *)url
//    success:(void (^)(HTBCanonicalEntry *canonicalEntry))success
//    failure:(void (^)(NSError *error))failure;
//
//    public func getBookmarkedDataEntryWithURL:(NSURL *)url
//    success:(void (^)(HTBBookmarkedDataEntry *entry))success
//    failure:(void (^)(NSError *error))failure;
//    // Add or edit your bookmark.
//    public func postBookmarkWithURL:(NSURL *)url
//    comment:(NSString *)comment
//    tags:(NSArray *)tags
//    options:(HatenaBookmarkPOSTOptions)options
//    success:(void (^)(HTBBookmarkedDataEntry *entry))success
//    failure:(void (^)(NSError *error))failure;
//
//    public func deleteBookmarkWithURL:(NSURL *)url
//    success:(void (^)(void))success
//    failure:(void (^)(NSError *error))failure;

    public func composeBookmark(permalink: URL) {
        let bundle = Bundle.module.url(forResource: "QuestionBookmarkWindow", withExtension: "xib")
        
    }
    
    public func openBookmarkWindows(permalink: URL) {
        let vc = QuestionBookmarkViewController(nibName: "QuestionBookmarkViewController", bundle: Bundle.module)
        print(vc)
        //.presentAsModalWindow(vc)
    }
    
    public func makeBookmarkComposer(permalink: URL,
                                     title: String? = nil,
                                     bookmarkCountText: String? = nil,
                                     factory: (() -> QuestionBookmarkViewController)? = nil) throws -> QuestionBookmarkViewController {
        let presenter = QuestionBookmarkComposerPresenter(isAuthorized: { self.authorized },
                                                  viewControllerFactory: factory ?? { QuestionBookmarkViewController.loadFromNib() })
        return try presenter.makeViewController(permalink: permalink, title: title, bookmarkCountText: bookmarkCountText)
    }
}
