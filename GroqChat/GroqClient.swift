// GroqClient.swift
// dshgo / GroqChat — thin client for Groq's OpenAI-compatible chat API.
// Endpoint: POST https://api.groq.com/openai/v1/chat/completions
// Non-streaming request; the API key is passed in by the caller, never stored here.

import Foundation

enum GroqError: LocalizedError {
    case missingAPIKey
    case httpError(statusCode: Int, body: String)
    case invalidResponse
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "请先在设置里填写 Groq API Key。"
        case .httpError(let statusCode, let body):
            let detail = body.isEmpty ? "" : "：\(body.prefix(300))"
            return "Groq 请求失败（HTTP \(statusCode)）\(detail)"
        case .invalidResponse:
            return "Groq 返回了无法解析的响应。"
        case .emptyResponse:
            return "Groq 没有返回任何内容。"
        }
    }
}

struct GroqChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
    let stream: Bool
}

struct GroqChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String
        }
        let message: Message
    }
    struct Usage: Decodable {
        let prompt_tokens: Int?
        let completion_tokens: Int?
        let total_tokens: Int?
    }

    let choices: [Choice]
    let usage: Usage?
}

final class GroqClient {
    static let shared = GroqClient()
    private static let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

    private init() {}

    /// Send the conversation to Groq and return the assistant's reply text.
    func send(
        messages: [ChatMessage],
        model: GroqModel,
        temperature: Double,
        maxTokens: Int,
        apiKey: String
    ) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw GroqError.missingAPIKey }

        let requestBody = GroqChatRequest(
            model: model.rawValue,
            messages: messages.map { GroqChatRequest.Message(role: $0.role.rawValue, content: $0.content) },
            temperature: temperature,
            max_tokens: maxTokens,
            stream: false
        )

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GroqError.httpError(statusCode: httpResponse.statusCode, body: body)
        }

        let decoded = try JSONDecoder().decode(GroqChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { throw GroqError.emptyResponse }
        return content
    }
}
