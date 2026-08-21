import Foundation
import SwiftUI

@MainActor
class SnsViewModel: ObservableObject {
    @Published var posts: [SnsPost] = []
    @Published var selectedPost: SnsPost?
    @Published var comments: [SnsComment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategory: String?

    private let apiService = APIService.shared

    func fetchPosts(category: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            posts = try await apiService.getPosts(category: category)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchPostById(_ id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            selectedPost = try await apiService.getPostById(id)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createPost(content: String, category: String, tags: [String], isPublic: Bool) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = CreatePostRequest(content: content, category: category, tags: tags, isPublic: isPublic)
            let newPost = try await apiService.createPost(request)
            posts.insert(newPost, at: 0)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func likePost(_ id: String) async {
        do {
            try await apiService.likePost(id)
            if let idx = posts.firstIndex(where: { $0.id == id }) {
                // Refresh the post
                let updated = try await apiService.getPostById(id)
                posts[idx] = updated
            }
        } catch {
            print("SnsViewModel: Like error - \(error.localizedDescription)")
        }
    }

    func fetchComments(postId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            comments = try await apiService.getComments(postId: postId)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addComment(postId: String, content: String) async -> Bool {
        do {
            let newComment = try await apiService.createComment(postId: postId, content: content)
            comments.append(newComment)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func categoryLabel(_ category: String) -> String {
        switch category {
        case "general": return "一般"
        case "consultation": return "相談"
        case "knowledge": return "ナレッジ"
        case "case_study": return "事例"
        case "event": return "イベント"
        case "tax": return "税務"
        case "vendor": return "業者"
        case "announcement": return "お知らせ"
        default: return category
        }
    }

    let categories = [
        ("general", "一般"),
        ("consultation", "相談"),
        ("knowledge", "ナレッジ"),
        ("case_study", "事例"),
        ("event", "イベント"),
        ("tax", "税務"),
        ("vendor", "業者"),
        ("announcement", "お知らせ")
    ]
}
