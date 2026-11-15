// Models.swift
// dshgo / GroqChat — data models and on-device settings.
// The Groq API key is stored in the iOS Keychain, never in source code.

import Foundation

/// One chat message. `role` follows the OpenAI-compatible chat API.
struct ChatMessage: Identifiable, Equatable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    let content: String
    let createdAt: Date

    init(id: UUID = UUID(), role: Role, content: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

/// Groq models offered by the app. IDs are Groq model IDs, used verbatim
/// in the `model` field of the chat-completions request.
enum GroqModel: String, CaseIterable, Identifiable {
    case gptOSS120B = "openai/gpt-oss-120b"
    case gptOSS20B = "openai/gpt-oss-20b"
    case qwen332B = "qwen/qwen3-32b"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gptOSS120B: return "GPT-OSS 120B"
        case .gptOSS20B: return "GPT-OSS 20B"
        case .qwen332B: return "Qwen3 32B"
        }
    }

    var shortDescription: String {
        switch self {
        case .gptOSS120B: return "默认 · 最强，适合复杂任务"
        case .gptOSS20B: return "更快更轻，适合日常对话"
        case .qwen332B: return "Qwen3，适合中文与代码"
        }
    }

    static var `default`: GroqModel { .gptOSS120B }
}

/// Minimal Keychain wrapper for the Groq API key.
/// The key lives only on the device; it is sent to api.groq.com and nowhere else.
enum KeychainHelper {
    private static let service = "com.kn.dshgo.groq"
    private static let account = "groq-api-key"

    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty
        else { return nil }
        return key
    }

    static func saveAPIKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        deleteAPIKey()
        let data = Data(trimmed.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    static func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

/// Non-secret settings, stored in UserDefaults.
final class AppSettings: ObservableObject {
    @Published var model: GroqModel {
        didSet { UserDefaults.standard.set(model.rawValue, forKey: "groq.model") }
    }
    @Published var temperature: Double {
        didSet { UserDefaults.standard.set(temperature, forKey: "groq.temperature") }
    }
    @Published var maxTokens: Int {
        didSet { UserDefaults.standard.set(maxTokens, forKey: "groq.maxTokens") }
    }

    init() {
        let storedModel = UserDefaults.standard.string(forKey: "groq.model")
        self.model = GroqModel(rawValue: storedModel ?? "") ?? .default
        let storedTemperature = UserDefaults.standard.double(forKey: "groq.temperature")
        self.temperature = storedTemperature == 0 ? 0.7 : storedTemperature
        let storedMaxTokens = UserDefaults.standard.integer(forKey: "groq.maxTokens")
        self.maxTokens = storedMaxTokens == 0 ? 1024 : storedMaxTokens
    }

    var hasAPIKey: Bool { KeychainHelper.loadAPIKey() != nil }
}
