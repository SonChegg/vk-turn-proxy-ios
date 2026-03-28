import SwiftUI

struct ServerGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                guideCard(
                    title: "1. Сервер",
                    text: "Запустите серверную часть на VPS и направьте её в локальный WireGuard/Hysteria порт.",
                    code: "./server-linux-amd64 -listen 0.0.0.0:56000 -connect 127.0.0.1:<порт_wg>"
                )

                guideCard(
                    title: "2. WireGuard на iPhone",
                    text: "В peer-конфиге замените endpoint на localhost и уменьшите MTU.",
                    code: """
Endpoint = 127.0.0.1:9000
MTU = 1280
"""
                )

                guideCard(
                    title: "3. Что ввести в приложении",
                    text: "Укажите адрес VPS и ссылку VK calls. Для первого запуска чаще всего хватает стандартного режима.",
                    code: """
Peer: 1.2.3.4:56000
Link: https://vk.com/call/join/...
Streams: 8
Use UDP: on
Listen: 127.0.0.1:9000
"""
                )

                guideCard(
                    title: "Важно для iOS",
                    text: "В этой версии пока используется localhost-сценарий, как у Android, но без Android-style app exclusion. Поэтому начните со split-tunnel WireGuard-конфига, а не с полного `0.0.0.0/0`, чтобы избежать циклической маршрутизации трафика самого proxy-клиента.",
                    code: nil
                )
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.13),
                    Color(red: 0.10, green: 0.12, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Настройка")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Готово") {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private func guideCard(title: String, text: String, code: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)

            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.8))

            if let code {
                Text(code)
                    .fbame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Color.green.opacity(0.95))
                    .padding(12)
                    .background(Color.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .textSelection(.enabled)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
