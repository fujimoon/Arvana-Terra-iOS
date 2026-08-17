import SwiftUI

struct SnsTimelineView: View {
    @StateObject private var vm = SnsViewModel()
    @State private var showCreatePost = false
    @State private var selectedCategory: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "すべて", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                            Task { await vm.fetchPosts() }
                        }
                        ForEach(vm.categories, id: \.0) { cat in
                            FilterChip(title: cat.1, isSelected: selectedCategory == cat.0) {
                                selectedCategory = cat.0
                                Task { await vm.fetchPosts(category: cat.0) }
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .background(Color.surfaceWhite)

                if vm.isLoading && vm.posts.isEmpty {
                    LoadingView()
                } else if vm.posts.isEmpty {
                    EmptyStateView(title: "投稿なし", message: "最初の投稿をしてみましょう", systemImage: "square.and.pencil",
                                   actionTitle: "投稿する", action: { showCreatePost = true })
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

                            // SNS sub-sections
                            SNSSectionLinks()
                        }
                        .padding(16)
                    }
                    .background(Color.backgroundGray)
                }
            }
            .navigationTitle("ネットワーク")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "square.and.pencil").foregroundColor(.primaryNavy)
                    }
                }
            }
            .task { await vm.fetchPosts() }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(vm: vm)
            }
        }
    }
}

struct SnsPostCard: View {
    let post: SnsPost
    @ObservedObject var vm: SnsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.accentBlue.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.authorName.prefix(1)))
                            .font(.subheadline).fontWeight(.bold).foregroundColor(.primaryNavy)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName).font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                    Text(formatDate(post.createdAt)).font(.caption).foregroundColor(.textGray)
                }
                Spacer()
                CategoryBadge(category: post.category, vm: vm)
            }

            // Content
            Text(post.content)
                .font(.body).foregroundColor(.textDark).lineLimit(4)

            // Tags
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption).foregroundColor(.accentBlue)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.accentBlue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Actions
            Divider()
            HStack(spacing: 20) {
                Button(action: {
                    Task { await vm.likePost(post.id) }
                }) {
                    Label("\(post.likeCount)", systemImage: post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundColor(post.isLikedByMe ? .errorRed : .textGray)
                }
                .buttonStyle(.plain)

                Label("\(post.commentCount)", systemImage: "bubble.right")
                    .font(.subheadline).foregroundColor(.textGray)

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline).foregroundColor(.textGray)
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    func formatDate(_ dateString: String) -> String {
        let fmt = ISO8601DateFormatter()
        guard let date = fmt.date(from: dateString) else { return dateString }
        let now = Date()
        let diff = now.timeIntervalSince(date)
        if diff < 3600 { return "\(Int(diff / 60))分前" }
        if diff < 86400 { return "\(Int(diff / 3600))時間前" }
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }
}

struct CategoryBadge: View {
    let category: String
    @ObservedObject var vm: SnsViewModel

    var body: some View {
        Text(vm.categoryLabel(category))
            .font(.caption2).fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(categoryColor)
            .clipShape(Capsule())
    }

    var categoryColor: Color {
        switch category {
        case "consultation": return .warningOrange
        case "knowledge": return .secondaryBlue
        case "case_study": return .successGreen
        case "event": return .accentBlue
        case "tax": return .primaryNavy
        case "vendor": return .textGray
        case "announcement": return .errorRed
        default: return .textGray
        }
    }
}

struct SNSSectionLinks: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("コミュニティ")
                .font(.headline).foregroundColor(.textDark)

            VStack(spacing: 8) {
                NavigationLink { ConsultationView() } label: {
                    SNSLink(icon: "questionmark.circle.fill", title: "相談", subtitle: "専門家に相談する", color: .warningOrange)
                }
                .buttonStyle(.plain)
                NavigationLink { KnowledgeView() } label: {
                    SNSLink(icon: "book.fill", title: "ナレッジ", subtitle: "業界の知識・情報", color: .secondaryBlue)
                }
                .buttonStyle(.plain)
                NavigationLink { CaseStudiesView() } label: {
                    SNSLink(icon: "doc.richtext.fill", title: "事例", subtitle: "成功事例を学ぶ", color: .successGreen)
                }
                .buttonStyle(.plain)
                NavigationLink { EventsView() } label: {
                    SNSLink(icon: "calendar.badge.clock", title: "イベント", subtitle: "セミナー・勉強会", color: .accentBlue)
                }
                .buttonStyle(.plain)
                NavigationLink { TaxAdvisorView() } label: {
                    SNSLink(icon: "yensign.circle.fill", title: "税務相談", subtitle: "税理士・FPに相談", color: .primaryNavy)
                }
                .buttonStyle(.plain)
                NavigationLink { VendorSnsView() } label: {
                    SNSLink(icon: "person.text.rectangle.fill", title: "業者情報", subtitle: "信頼できる業者を探す", color: .textGray)
                }
                .buttonStyle(.plain)
                NavigationLink { AnnouncementsView() } label: {
                    SNSLink(icon: "megaphone.fill", title: "お知らせ", subtitle: "運営からのお知らせ", color: .errorRed)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SNSLink: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: icon).foregroundColor(color))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                Text(subtitle).font(.caption).foregroundColor(.textGray)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.textGray)
        }
        .padding(14)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CreatePostView: View {
    @ObservedObject var vm: SnsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var category = "general"
    @State private var tagsText = ""
    @State private var isPublic = true

    var isValid: Bool { !content.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("投稿内容") {
                    TextEditor(text: $content)
                        .frame(height: 150)
                        .overlay(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("何を共有しますか？").font(.body).foregroundColor(.textGray).padding(4)
                            }
                        }
                }
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(vm.categories, id: \.0) { Text($0.1).tag($0.0) }
                    }
                }
                Section("タグ") {
                    TextField("タグ (カンマ区切り)", text: $tagsText)
                }
                Section("公開設定") {
                    Toggle("公開投稿", isOn: $isPublic)
                }
            }
            .navigationTitle("投稿を作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("投稿") {
                        Task {
                            let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                            let success = await vm.createPost(content: content, category: category, tags: tags, isPublic: isPublic)
                            if success { dismiss() }
                        }
                    }
                    .disabled(!isValid || vm.isLoading)
                }
            }
        }
    }
}
