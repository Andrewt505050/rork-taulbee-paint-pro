//
//  ExpertChatView.swift
//  TaulbeePainting
//
//  The Paint Expert: an AI advisor customers can ask anything about painting.
//  Messages persist on-device via SwiftData. Includes starter prompts, a
//  typing indicator, and a link to the product library.
//

import SwiftUI
import SwiftData

struct ExpertChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.createdAt, order: .forward) private var messages: [ChatMessage]

    @State private var draft: String = ""
    @State private var isThinking = false
    @State private var errorText: String?
    @State private var confirmClear = false
    @State private var path = NavigationPath()
    @State private var segment: ExpertSegment = .suggested
    @FocusState private var inputFocused: Bool

    /// Optional question injected from the product detail screen.
    let initialQuestion: String?

    init(initialQuestion: String? = nil) {
        self.initialQuestion = initialQuestion
    }

    private let service = PaintExpertService()

    private let starters: [String] = [
        "What's the best paint for a humid bathroom?",
        "How do I fix peeling paint on my deck?",
        "Which finish should I use for kitchen cabinets?",
        "How do I prep walls before painting?",
        "What primer blocks water stains on a ceiling?"
    ]

    private let popularTopics: [(icon: String, title: String, question: String)] = [
        ("house.fill", "Interior walls", "What's the best paint and finish for interior living room walls?"),
        ("sun.max.fill", "Exterior siding", "What's the best paint for exterior siding that lasts?"),
        ("square.grid.3x3.fill", "Cabinets & trim", "How do I get a smooth, durable finish on cabinets and trim?"),
        ("drop.fill", "Moisture & mildew", "How do I prevent mildew in a humid bathroom?"),
        ("paintbrush.fill", "Prep & priming", "What's the right way to prep and prime before painting?")
    ]

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                conversation
                inputBar
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Paint Expert")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ExpertRoute.self) { route in
                switch route {
                case .library:
                    ProductLibraryView(onAsk: ask)
                case .product(let product):
                    ProductDetailView(product: product, onAsk: ask)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        path.append(ExpertRoute.library)
                    } label: {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle(Theme.brand)
                    }
                }
                if !messages.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            confirmClear = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                }
            }
            .confirmationDialog("Clear this conversation?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) { }
            }
        }
        .onAppear {
            if let initialQuestion, messages.isEmpty {
                send(text: initialQuestion)
            }
        }
    }

    // MARK: Conversation

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    if messages.isEmpty {
                        welcome
                    }
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                    if isThinking {
                        TypingBubble()
                            .id("typing")
                    }
                    if let errorText {
                        Text(errorText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Severity.serious.color)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in scrollToBottom(proxy) }
            .onChange(of: isThinking) { _, _ in scrollToBottom(proxy) }
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.brandGradient)
                        .frame(width: 76, height: 76)
                        .shadow(color: Theme.brand.opacity(0.35), radius: 14, y: 7)
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("Paint Expert")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Real answers from painting pros.")
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            segmentControl

            VStack(spacing: 10) {
                if segment == .suggested {
                    ForEach(starters, id: \.self) { prompt in
                        questionCard(icon: "sparkle", text: prompt) { send(text: prompt) }
                    }
                } else {
                    ForEach(popularTopics, id: \.title) { topic in
                        questionCard(icon: topic.icon, text: topic.title) { send(text: topic.question) }
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private var segmentControl: some View {
        HStack(spacing: 6) {
            segmentButton("Suggested Questions", .suggested)
            segmentButton("Popular Topics", .popular)
        }
        .padding(5)
        .background(Theme.canvasDeep, in: .capsule)
    }

    private func segmentButton(_ title: String, _ value: ExpertSegment) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy(duration: 0.2)) { segment = value }
        } label: {
            Text(title)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundStyle(segment == value ? .white : Theme.inkSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    if segment == value {
                        Capsule().fill(Theme.brandGradient)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func questionCard(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.brand)
                    .frame(width: 34, height: 34)
                    .background(Theme.lavender, in: .circle)
                Text(text)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.inkSecondary.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.surface, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Input bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask about paint, prep, color…", text: $draft, axis: .vertical)
                .font(.system(size: 16))
                .foregroundStyle(Theme.ink)
                .lineLimit(1...5)
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Theme.canvasDeep, in: .rect(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.hairline, lineWidth: 1))

            Button {
                send(text: draft)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(canSend ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.inkSecondary.opacity(0.4)), in: .circle)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Theme.surface)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .top)
    }

    enum ExpertSegment { case suggested, popular }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    // MARK: Actions

    private func send(text rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        Haptics.tap()
        errorText = nil
        draft = ""
        inputFocused = false

        let userMessage = ChatMessage(role: .user, text: text)
        modelContext.insert(userMessage)

        let history = messages.map { ExpertTurn(role: $0.role, text: $0.text) }
            + [ExpertTurn(role: .user, text: text)]

        isThinking = true
        Task {
            do {
                let reply = try await service.reply(to: history)
                modelContext.insert(ChatMessage(role: .assistant, text: reply))
                Haptics.success()
            } catch {
                errorText = (error as? ExpertError)?.errorDescription ?? "Something went wrong. Please try again."
                Haptics.warning()
            }
            isThinking = false
        }
    }

    /// Called from the product library/detail: pop back to chat and ask.
    private func ask(_ question: String) {
        path = NavigationPath()
        send(text: question)
    }

    private func clearAll() {
        for message in messages { modelContext.delete(message) }
        errorText = nil
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}
