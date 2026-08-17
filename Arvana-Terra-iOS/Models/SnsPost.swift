import Foundation

struct SnsPost: Codable, Identifiable {
    let id: String
    let authorId: String
    let authorName: String
    let authorAvatarUrl: String?
    let content: String
    let category: String
    let imageUrls: [String]
    let tags: [String]
    let likeCount: Int
    let commentCount: Int
    let isLikedByMe: Bool
    let isPublic: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case authorId
        case authorName
        case authorAvatarUrl
        case content
        case category
        case imageUrls
        case tags
        case likeCount
        case commentCount
        case isLikedByMe
        case isPublic
        case createdAt
        case updatedAt
    }
}

struct SnsComment: Codable, Identifiable {
    let id: String
    let postId: String
    let authorId: String
    let authorName: String
    let authorAvatarUrl: String?
    let content: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case postId
        case authorId
        case authorName
        case authorAvatarUrl
        case content
        case createdAt
    }
}

struct CreatePostRequest: Codable {
    let content: String
    let category: String
    let tags: [String]
    let isPublic: Bool
}

struct CreateCommentRequest: Codable {
    let content: String
}
