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
        requestTokenUrl: "https://www.hatena.com/oauth/initiate?scope=read_public,write_public,read_private,write_private",
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
            requestTokenUrl: "https://www.hatena.com/oauth/initiate?scope=read_public,write_public,read_private,write_private",
            authorizeUrl:    "https://www.hatena.ne.jp/oauth/authorize",
            accessTokenUrl:  "https://www.hatena.com/oauth/token"
        )
    }
    
    public func authenticate(viewController: QuestionAuthViewController) {
        // Clear previous token
        oauthswift = OAuth1Swift(
            consumerKey:     consumerKey,
            consumerSecret:  consumerSecret,
            requestTokenUrl: "https://www.hatena.com/oauth/initiate?scope=read_public,write_public,read_private,write_private",
            authorizeUrl:    "https://www.hatena.ne.jp/oauth/authorize",
            accessTokenUrl:  "https://www.hatena.com/oauth/token"
        )
        oauthswift.authorizeURLHandler = viewController

        // ログイン完了後にOAuthフローを再開するため
        viewController.onLoginCompleted = { [weak self] in
            self?.authenticate(viewController: viewController)
        }

        oauthswift.authorize(withCallbackURL: URL(string: "https://nyoho.jp/hatena")!) { result in
            switch result {
            case .success(let (credential, _, parameters)):
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
            case .delete:
                return .DELETE
            case .put:
                return .PUT
            case .patch:
                return .PATCH
            case .head:
                return .HEAD
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
                } catch let parsingError as QuestionError {
                    completion(.failure(parsingError))
                } catch let decodingError as DecodingError {
                    print("JSON conversion failed in JSONDecoder", decodingError.localizedDescription)
                    completion(.failure(.responseParseError(decodingError)))
                } catch {
                    completion(.failure(.responseParseError(error)))
                }
            case .failure(let error):
                switch error { // error is OAuthSwiftError
                case .requestError(let e, let request):
                    //requestError[Error Domain=NSURLErrorDomain Code=404 "" UserInfo={Response-Body={"url":"...","message":"Bookmark is not found"}, NSErrorFailingURLKey=http://api.b.hatena.ne.jp/1/my/bookmark?url=..., Response-Headers={...
                    print("A request error: request = \(request)")
                    let nsError = e as NSError
                    if let s = nsError.userInfo["Response-Body"] {
                        print(s)
                    }
                    if let response = nsError.userInfo[OAuthSwiftError.ResponseKey] as? HTTPURLResponse {
                        let data = nsError.userInfo[OAuthSwiftError.ResponseDataKey] as? Data ?? Data()
                        completion(.failure(.httpStatus(code: response.statusCode, data: data)))
                    } else {
                        completion(Result.failure(.connectionError(e)))
                    }
                default:
                    print("The others' error:")
                    print(error)
                    completion(.failure(.connectionError(error)))
                }
            }
        }
    }

    // https://developer.hatena.ne.jp/ja/documents/bookmark/apis/rest/bookmark#get_my_bookmark
    public func getMyBookmark(url: URL, completion: @escaping (Result<Bookmark, QuestionError>) -> Void) {
        send(request: GetBookmarkRequest(url: url), completion: completion)
    }
    
    // https://developer.hatena.ne.jp/ja/documents/bookmark/apis/rest/entry
    public func getEntry(url: URL, completion: @escaping (Result<Entry, QuestionError>) -> Void) {
        send(request: GetEntryRequest(url: url), completion: completion)
    }

    // https://developer.hatena.ne.jp/ja/documents/bookmark/apis/rest/tags/
    public func getMyTags(completion: @escaping (Result<[Tag], QuestionError>) -> Void) {
        send(request: GetMyTagsRequest()) { result in
            switch result {
            case .success(let response):
                completion(.success(response.tags))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // https://developer.hatena.ne.jp/ja/documents/bookmark/apis/rest/bookmark#post_my_bookmark
    public func postMyBookmark(url: URL, comment: String, tags: [String] = [], postTwitter: Bool = false, postFacebook: Bool = false, postMixi: Bool = false, postEvernote: Bool = false, sendMail: Bool = false, isPrivate: Bool = false, completion: @escaping (Result<Bookmark, QuestionError>) -> Void) {
        let request = PostBookmarkRequest(url: url, comment: comment, tags: tags, postTwitter: postTwitter, postFacebook: postFacebook, postMixi: postMixi, postEvernote: postEvernote, sendMail: sendMail, isPrivate: isPrivate)
        send(request: request, completion: completion)
    }
    
    /// https://developer.hatena.ne.jp/ja/documents/bookmark/apis/rest/bookmark#delete_my_bookmark
    public func deleteMyBookmark(url: URL, completion: @escaping (Result<Void, QuestionError>) -> Void) {
        let request = DeleteBookmarkRequest(url: url)
        send(request: request) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                if case .httpStatus(let code, _) = error, code == 404 {
                    completion(.success(()))
                } else {
                    completion(.failure(error))
                }
            }
        }
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
