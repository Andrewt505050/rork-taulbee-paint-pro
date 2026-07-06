//
//  ChatBubble.swift
//  TaulbeePainting
//
//  A single chat message bubble plus an animated typing indicator.
//

import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isUser {
                Spacer(minLength: 40)
                bubble
            } else {
                avatar
                bubble
                Spacer(minLength: 40)
            }
        }
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(Theme.brandGradient)
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 30, height: 30)
        .shadow(color: Theme.brand.opacity(0.25), radius: 4, y: 2)
    }

    private var bubble: some View {
        Text(.init(message.text))
            .font(.system(size: 15.5))
            .foregroundStyle(isUser ? .white : Theme.ink)
            .tint(isUser ? .white : Theme.brand)
            .textSelection(.enabled)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background {
                if isUser {
                    Theme.brandGradient
                } else {
                    Color(Theme.surface)
                }
            }
            .clipShape(.rect(cornerRadius: 18))
            .overlay {
                if !isUser {
                    RoundedRectangle(cornerRadius: 18).stroke(Theme.hairline, lineWidth: 1)
                }
            }
            .shadow(color: .black.opacity(isUser ? 0.12 : 0.05), radius: 6, y: 3)
    }
}

struct TypingBubble: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(Theme.brandGradient)
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 30, height: 30)

            HStack(spacing: 5) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Theme.inkSecondary.opacity(0.55))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == index ? 1.0 : 0.5)
                        .opacity(phase == index ? 1.0 : 0.5)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.surface, in: .rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.hairline, lineWidth: 1))

            Spacer(minLength: 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: false)) {
                phase = 2
            }
            Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}
