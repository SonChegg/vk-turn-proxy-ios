import SwiftUI
import UIKit

struct MainView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingGuide = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.10, blue: 0.16),
                        Color(red: 0.09, green: 0.18, blue: 0.19),
                        Color(red: 0.14, green: 0.10, blue: 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        statusCard

                        if !model.bridgeAvailable {
                            warningCard
                        }

                        modeCard

                        if model.config.rawMode {
                            rawCard
                        } else {
                            guidedCard
                        }

                        actionsCard
                        logsCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("VK TURN Proxy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сервер") {
                        showingGuide = true
                    }
                }
            }
            .sheet(isPresented: $showingGuide) {
                NavigationStack {
                    ServerGuideView()
                }
            }
        }
    }

    private var statusCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(model.isRunning ? "Proxy запущен" : "Proxy остановлен")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(model.isRunning ? "RUNNING" : "IDLE")
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(model.isRunning ? Color.green : Color.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }

                Text("Для WireGuard на iOS используйте endpoint `127.0.0.1:9000` и `MTU = 1280`.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.78))
            }
        }
    }

    private var warningCard: some View {
        SectionCard(tint: Color.orange.opacity(0.16)) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bridge пока не подключен")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                Text("Интерфейс уже готов, но настоящий runtime включится только после сборки `VkTurnCore.xcframework` на macOS и добавления framework в target.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.82))
            }
        }
    }

    private var modeCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Режим запуска")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                Toggle(isOn: binding(\.rawMode)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Raw-команда")
                            .foregroundStyle(.white)
                        Text("Повторяет Android-режим ручных аргументов.")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }
                .tint(Color.cyan)
            }
        }
    }

    private var guidedCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Параметры")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("Тип ссылки")

                    Picker("Тип ссылки", selection: binding(\.inviteService)) {
                        ForEach(ProxyConfiguration.InviteService.allCases) { service in
                            Text(service.rawValue).tag(service)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                field("Peer (IP:Port сервера)", text: binding(\.peer), prompt: "11.22.33.44:56000")
                field("Ссылка на звонок", text: binding(\.link), prompt: "https://vk.com/call/join/...")
                field("Локальный endpoint", text: binding(\.listen), prompt: "127.0.0.1:9000")
                field("Override TURN IP", text: binding(\.turnHost), prompt: "необязательно")
                field("Override TURN Port", text: binding(\.turnPort), prompt: "необязательно")

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        fieldLabel("Потоки")
                        Spacer()
                        Text("\(model.config.streams)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.white)
                    }

                    Stepper(value: binding(\.streams), in: 1...16) {
                        Text("Количество параллельных соединений")
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                    .tint(Color.cyan)
                }

                Toggle("Использовать UDP (-udp)", isOn: binding(\.useUDP))
                    .tint(Color.cyan)
                    .foregroundStyle(.white)

                Toggle("Без DTLS обфускации (-no-dtls)", isOn: binding(\.noDTLS))
                    .tint(Color.cyan)
                    .foregroundStyle(.white)
            }
        }
    }

    private var rawCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Raw-команда")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                Text("Можно вставлять почти тот же набор флагов, что в Android. Если в начале указать `./client`, оно будет отброшено автоматически.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.78))

                TextEditor(text: binding(\.rawCommand))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 140)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(Color.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
    }

    private var actionsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                if let lastError = model.lastError {
                    Text(lastError)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.orange)
                }

                Button {
                    model.toggleProxy()
                } label: {
                    Text(model.isRunning ? "Остановить Proxy" : "Запустить Proxy")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                }
                .buttonStyle(PillButtonStyle(background: model.isRunning ? Color.red.opacity(0.75) : Color.green.opacity(0.72)))

                HStack(spacing: 10) {
                    Button("Сбросить") {
                        model.resetConfiguration()
                    }
                    .buttonStyle(PillButtonStyle(background: Color.white.opacity(0.10)))

                    Button("Скопировать логи") {
                        UIPasteboard.general.string = model.logsText
                        model.appendLocalLog("Логи скопированы в буфер обмена.")
                    }
                    .buttonStyle(PillButtonStyle(background: Color.white.opacity(0.10)))
                }
            }
        }
    }

    private var logsCard: some View {
        SectionCard(tint: Color.black.opacity(0.28)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Логи")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(model.logs.count)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                ScrollView {
                    Text(model.logsText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(Color.green.opacity(0.95))
                        .textSelection(.enabled)
                }
                .frame(minHeight: 220)
                .padding(12)
                .background(Color.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<ProxyConfiguration, Value>) -> Binding<Value> {
        Binding(
            get: {
                model.config[keyPath: keyPath]
            },
            set: { newValue in
                model.config[keyPath: keyPath] = newValue
                model.persistConfiguration()
            }
        )
    }

    @ViewBuilder
    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(title)

            TextField("", text: text, prompt: Text(prompt).foregroundStyle(Color.white.opacity(0.35)))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.76))
    }
}

private struct SectionCard<Content: View>: View {
    let tint: Color
    let content: Content

    init(tint: Color = Color.white.opacity(0.08), @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(tint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

private struct PillButtonStyle: ButtonStyle {
    let background: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(background.opacity(configuration.isPressed ? 0.65 : 1.0), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}
