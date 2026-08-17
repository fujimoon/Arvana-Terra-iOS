import SwiftUI

struct SnsPostDetailView: View {
    let post: SnsPost
    @ObservedObject var vm: SnsViewModel
    @State private var commentText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Post content
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.accentBlue.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(post.authorName.prefix(1)))
                                    .font(.headline).fontWeight(.bold).foregroundColor(.primaryNavy)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.authorName).font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                            Text(formatDate(post.createdAt)).font(.caption).foregroundColor(.textGray)
                        }
                        Spacer()
                        CategoryBadge(category: post.category, vm: vm)
                    }

                    Text(post.content).font(.body).foregroundColor(.textDark)

                    if !post.tags.isEmpty {
                        FlowLayout(tags: post.tags)
                    }

                    HStack(spacing: 16) {
                        Button(action: {
                            Task { await vm.likePost(post.id) }
                        }) {
                            Label("\(post.likeCount)", systemImage: post.isLikedByMe ? "heart.fill" : "heart")
                                .foregroundColor(post.isLikedByMe ? .errorRed : .textGray)
                        }
                        .buttonStyle(.plain)

                        Label("\(post.commentCount)", systemImage: "bubble.right")
                            .foregroundColor(.textGray)
                    }
                    .font(.subheadline)
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Comments
                VStack(alignment: .leading, spacing: 12) {
                    Text("コメント (\(vm.comments.count))")
                        .font(.headline).foregroundColor(.textDark)

                    if vm.comments.isEmpty {
                        Text("コメントはまだありません")
                            .font(.caption).foregroundColor(.textGray)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.surfaceWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        ForEach(vm.comments) { comment in
                            CommentCard(comment: comment)
                        }
                    }
                }

                // Comment input
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.accentBlue.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "person.fill").foregroundColor(.accentBlue))

                    TextField("コメントを入力...", text: $commentText)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.backgroundGray)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button(action: {
                        guard !commentText.isEmpty else { return }
                        Task {
                            await vm.addComment(postId: post.id, content: commentText)
                            commentText = ""
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(commentText.isEmpty ? .textGray : .primaryNavy)
                    }
                    .disabled(commentText.isEmpty)
                }
                .padding(12)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
        .background(Color.backgroundGray)
        .navigationTitle("投稿詳細")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.fetchComments(postId: post.id) }
    }

    func formatDate(_ dateString: String) -> String {
        let fmt = ISO8601DateFormatter()
        guard let date = fmt.date(from: dateString) else { return dateString }
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日 HH:mm"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }
}

struct CommentCard: View {
    let comment: SnsComment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.accentBlue.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(comment.authorName.prefix(1)))
                        .font(.caption).fontWeight(.bold).foregroundColor(.primaryNavy)
                )
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName).font(.caption).fontWeight(.semibold).foregroundColor(.textDark)
                    Spacer()
                    Text(formatDate(comment.createdAt)).font(.caption2).foregroundColor(.textGray)
                }
                Text(comment.content).font(.body).foregroundColor(.textDark)
            }
        }
        .padding(12)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func formatDate(_ dateString: String) -> String {
        let fmt = ISO8601DateFormatter()
        guard let date = fmt.date(from: dateString) else { return dateString }
        let now = Date()
        let diff = now.timeIntervalSince(date)
        if diff < 3600 { return "\(Int(diff / 60))分前" }
        if diff < 86400 { return "\(Int(diff / 3600))時間前" }
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}

struct FlowLayout: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption).foregroundColor(.accentBlue)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.accentBlue.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }
}

// Stub SNS sub-views
struct ConsultationView: View {
    @StateObject private var vm = SnsViewModel()
    var body: some View {
        SnsFilteredView(category: "consultation", title: "相談", vm: vm)
    }
}

struct KnowledgeView: View {
    @StateObject private var vm = SnsViewModel()
    var body: some View {
        SnsFilteredView(category: "knowledge", title: "ナレッジ", vm: vm)
    }
}

struct CaseStudiesView: View {
    @StateObject private var vm = SnsViewModel()
    var body: some View {
        SnsFilteredView(category: "case_study", title: "事例", vm: vm)
    }
}

struct EventsView: View {
    @StateObject private var vm = SnsViewModel()
    var body: some View {
        SnsFilteredView(category: "event", title: "イベント", vm: vm)
    }
}

struct TaxAdvisorView: View {
    @StateObject private var vm = SnsViewModel()
    var body: some View {
        SnsFilteredView(category: "tax", title: "税務相談", vm: vm)
    }
}

struct VendorSnsView: View {
    @StateObject private var vm = SnsViewModel()
    var body: some View {
        SnsFilteredView(category: "vendor", title: "業者情報", vm: vm)
    }
}

struct AnnouncementsView: View {
    @StateObject private var vm = SnsViewModel()
    var body: some View {
        SnsFilteredView(category: "announcement", title: "お知らせ", vm: vm)
    }
}

struct SnsFilteredView: View {
    let category: String
    let title: String
    @ObservedObject var vm: SnsViewModel

    var body: some View {
        Group {
            if vm.isLoading && vm.posts.isEmpty {
                LoadingView()
            } else if vm.posts.isEmpty {
                EmptyStateView(title: "投稿なし", message: "\(title)の投稿がありません", systemImage: "square.and.pencil")
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(vm.posts) { post in
                            NavigationLink {
                                SnsPostDetailView(post: post, vm: vm)
                            } label: {
                                SnsPostCard(post: post, vm: vm)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .background(Color.backgroundGray)
            }
        }
        .navigationTitle(title)
        .task { await vm.fetchPosts(category: category) }
    }
}
