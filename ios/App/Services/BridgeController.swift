import Foundation

protocol BridgeControlling {
    var isAvailable: Bool { get }
    func start(arguments: [String]) -> String?
    func stop()
    func isRunning() -> Bool
    func drainLogs() -> [String]
}

func makeBridgeController() -> BridgeControlling {
    #if canImport(VkTurnCore)
    return GoMobileBridgeController()
    #else
    return StubBridgeController()
    #endif
}

#if canImport(VkTurnCore)
import VkTurnCore

final class GoMobileBridgeController: BridgeControlling {
    private let service = GoProxycoreNewService()

    var isAvailable: Bool { true }

    func start(arguments: [String]) -> String? {
        guard let service else {
            return "Не удалось создать экземпляр Go bridge."
        }

        guard
            let payload = try? JSONEncoder().encode(arguments),
            let json = String(data: payload, encoding: .utf8)
        else {
            return "Не удалось сериализовать аргументы запуска."
        }

        let response = service.start(json) ?? ""
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func stop() {
        service?.stop()
    }

    func isRunning() -> Bool {
        service?.isRunning() ?? false
    }

    func drainLogs() -> [String] {
        splitLogLines(service?.drainLogs() ?? "")
    }
}
#else
final class StubBridgeController: BridgeControlling {
    private var running = false
    private var buffer: [String] = [
        "Stub runtime активен.",
        "Соберите ios/Frameworks/VkTurnCore.xcframework на macOS, чтобы включить настоящий bridge."
    ]

    var isAvailable: Bool { false }

    func start(arguments: [String]) -> String? {
        running = false
        buffer.append("Старт пропущен: настоящий bridge пока не подключен к target приложения.")
        buffer.append("Аргументы запуска: \(arguments.joined(separator: " "))")
        return "VkTurnCore.xcframework не подключен. Соберите bridge на macOS и добавьте framework в Xcode target."
    }

    func stop() {
        running = false
        buffer.append("Stub runtime остановлен.")
    }

    func isRunning() -> Bool {
        running
    }

    func drainLogs() -> [String] {
        defer { buffer.removeAll() }
        return buffer
    }
}
#endif

private func splitLogLines(_ text: String) -> [String] {
    text
        .split(separator: "\n")
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}
