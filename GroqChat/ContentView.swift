// ContentView.swift
// dshgo / GroqChat — chat screen: message list, input, send, new chat, clear.
//
// The single shared AppSettings instance is created in GroqChatApp and
// passed down as an environment object; ChatViewModel deliberately owns
// no settings of its own, so model / temperature / maxTokens changes in
// Settings always reach the API call.

import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published var input: String = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    var canSend: Bool {
        !isLoading && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func send(settings: AppSettings) async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            errorMessage = "请先在设置里填写 Groq API Key。"
            return
        }
        input = ""
        errorMessage = nil
        messages.append(ChatMessage(role: .user, content: text))
        isLoading = true
        defer { isLoading = false }
        do {
            let reply = try await GroqClient.shared.send(
                messages: messages,
                model: settings.model,
                temperature: settings.temperature,
                maxTokens: settings.maxTokens,
                apiKey: apiKey
            )
            messages.append(ChatMessage(role: .assistant, content: reply))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func newChat() {
        messages = []
        errorMessage = nil
        input = ""
    }
}

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty {
                    emptyState
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                if viewModel.isLoading {
                                    HStack(spacing: 6) {
                                        ProgressView()
                                        Text("Groq 正在回复…")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let last = viewModel.messages.last {
                                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                            }
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                Divider()
                inputBar
            }
            .navigationTitle("GroqChat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("新会话", systemImage: "plus") { viewModel.newChat() }
                        Button("清空对话", systemImage: "trash", role: .destructive) { viewModel.newChat() }
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("设置")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 44))
                .foregroundStyle(.teal)
            Text(settings.hasAPIKey ? "开始聊天吧" : "先在设置里填入 Groq API Key")
                .font(.headline)
            Text("模型：\(settings.model.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !settings.hasAPIKey {
                Button("去设置") { showingSettings = true }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("输入消息…", text: $viewModel.input, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isLoading)
                .onSubmit {
                    Task { await viewModel.send(settings: settings) }
                }
            Button {
                Task { await viewModel.send(settings: settings) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
            }
            .disabled(!viewModel.canSend)
            .accessibilityLabel("发送")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.content)
                .textSelection(.enabled)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.role == .user ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(message.role == .user ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}
