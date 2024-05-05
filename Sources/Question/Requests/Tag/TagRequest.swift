import Foundation

public struct MyTagsResponse: Decodable {
    public let tags: [Tag]
}

public struct GetMyTagsRequest: QuestionRequest {
    public typealias Response = MyTagsResponse

    public init() {}

    public var method: HTTPMethod { .get }
    public var path: String { "/my/tags" }
    public var queryItems: [String: Any] { [:] }
}
