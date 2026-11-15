// SettingsView.swift
// dshgo / GroqChat — settings sheet: Groq API key, model, temperature, max tokens.
//
// The API key is stored in the iOS Keychain (see KeychainHelper in
// Models.swift). It never leaves the device except in requests to
// api.groq.com, and it is never written into source code or the repo.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var apiKeyInput: String = ""
    @State private var saveMessage: String?
    @State private var saveSucceeded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("gsk_…", text: $apiKeyInput)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    Button("保存 API Key") {
                        saveSucceeded = KeychainHelper.saveAPIKey(apiKeyInput)
                        saveMessage = saveSucceeded ? "已保存到本机钥匙串。" : "保存失败，请检查 Key 是否为空。"
                        if saveSucceeded { apiKeyInput = "" }
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if settings.hasAPIKey {
                        Button("删除已保存的 API Key", role: .destructive) {
                            KeychainHelper.deleteAPIKey()
                            saveMessage = "已删除本机保存的 API Key。"
                            saveSucceeded = true
                        }
                    }
                    if let saveMessage {
                        Text(saveMessage)
                            .font(.footnote)
                            .foregroundStyle(saveSucceeded ? .secondary : .red)
                    }
                } header: {
                    Text("Groq API Key")
                } footer: {
                    Text("Key 只存在本机钥匙串里，不会上传到任何地方；每次聊天只发给 api.groq.com。在 console.groq.com 申请免费 Key。")
                }

                Section("模型") {
                    Picker("模型", selection: $settings.model) {
                        ForEach(GroqModel.allCases) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    Text(settings.model.shortDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("生成参数") {
                    HStack {
                        Text("Temperature")
                        Slider(value: $settings.temperature, in: 0...2, step: 0.1)
                        Text(String(format: "%.1f", settings.temperature))
                            .font(.footnote.monospacedDigit())
                            .frame(width: 32, alignment: .trailing)
                    }
                    Stepper("Max tokens：\(settings.maxTokens)", value: $settings.maxTokens, in: 256...4096, step: 256)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                apiKeyInput = ""
                saveMessage = nil
            }
        }
    }
}
