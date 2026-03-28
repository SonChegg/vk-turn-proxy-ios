import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var config: ProxyConfiguration
    @Published private(set) var logs: [String]
    @Published private(set) var isRunning: Bool
    @Published var lastError: String?

    let bridgeAvailable: Bool

    private let bridge: BridgeControlling
    private var pollTask: Task<Void, Never>?

    init(bridge: BridgeControlling = makeBridgeController()) {
        self.bridge = bridge
        self.bridgeAvailable = bridge.isAvailable
        self.config = SettingsStore.load()
        self.logs = ["Ожидание запуска..."]
        self.isRunning = bridge.isRunning()

        flushBridgeLogs()
        startPolling()
    }

    deinit {
        pollTask?.cancel()
    }

    var logsText: String {
        logs.joined(separator: "\n")
    }

    func persistConfiguration() {
        SettingsStore.save(config)
    }

    func resetConfiguration() {
        config = .default
        persistConfiguration()
        appendLocalLog("Настройки сброшены к значениям по умолчанию.")
    }

    func toggleProxy() {
        if isRunning {
            stopProxy()
        } else {
            startProxy()
        }
    }

    func startProxy() {
        do {
            let arguments = try config.commandArguments()
            persistConfiguration()

            if let error = bridge.start(arguments: arguments) {
                lastError = error
                isRunning = false
                appendLocalLog("ОШИБКА: \(error)")
                return
            }

            lastError = nil
            isRunning = true
            appendLocalLog("Команда: \(arguments.joined(separator: " "))")
        } catch {
            let message = error.localizedDescription
            lastError = message
            isRunning = false
            appendLocalLog("ОШИБКА: \(message)")
        }
    }

    func stopProxy() {
        bridge.stop()
        isRunning = false
        appendLocalLog("Остановка отправлена.")
    }

    func appendLocalLog(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        logs.append(trimmed)
        if logs.count > 400 {
            logs.removeFirst(logs.count - 400)
        }
    }

    private func flushBridgeLogs() {
        for line in bridge.drainLogs() {
            appendLocalLog(line)
        }
    }

    private func startPolling() {
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await MainActor.run {
                    self.flushBridgeLogs()
                    self.isRunning = self.bridge.isRunning()
                }

                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
    }
}
