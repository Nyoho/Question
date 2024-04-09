import Foundation

public struct QuestionBookmarkComposerPresenter {
    public enum Error: Swift.Error, Equatable {
        case unauthorized
    }
    
    private let isAuthorized: () -> Bool
    private let viewControllerFactory: () -> QuestionBookmarkViewController
    
    public init(isAuthorized: @escaping () -> Bool,
                viewControllerFactory: @escaping () -> QuestionBookmarkViewController = { QuestionBookmarkViewController.loadFromNib() }) {
        self.isAuthorized = isAuthorized
        self.viewControllerFactory = viewControllerFactory
    }
    
    public func makeViewController(permalink: URL,
                                   title: String? = nil,
                                   bookmarkCountText: String? = nil) throws -> QuestionBookmarkViewController {
        guard isAuthorized() else {
            throw Error.unauthorized
        }
        let viewController = viewControllerFactory()
        viewController.configure(permalink: permalink, title: title, bookmarkCountText: bookmarkCountText)
        return viewController
    }
}
