import ExpoModulesCore
import Foundation

#if canImport(VkTurnCore)
import VkTurnCore
#endif

public final class VkTurnCoreModule: Module {
  #if canImport(VkTurnCore)
  private let service = GoProxycoreNewService()
  #endif

  public func definition() -> ModuleDefinition {
    Name("VkTurnCore")

    Constant("isAvailable") {
      self.bridgeAvailable
    }

    Function("getStatus") { () -> [String: Any] in
      [
        "isAvailable": self.bridgeAvailable,
        "isRunning": self.bridgeRunning
      ]
    }

    AsyncFunction("start") { (arguments: [String]) -> String? in
      self.start(arguments: arguments)
    }

    Function("stop") {
      self.stop()
    }

    Function("isRunning") { () -> Bool in
      self.bridgeRunning
    }

    Function("drainLogs") { () -> [String] in
      self.drainLogs()
    }

    OnDestroy {
      self.stop()
    }
  }

  private var bridgeAvailable: Bool {
    #if canImport(VkTurnCore)
    return true
    #else
    return false
    #endif
  }

  private var bridgeRunning: Bool {
    #if canImport(VkTurnCore)
    return service?.isRunning() ?? false
    #else
    return false
    #endif
  }

  private func start(arguments: [String]) -> String? {
    #if canImport(VkTurnCore)
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
    #else
    return "VkTurnCore.xcframework не подключен. Сначала выполни npm run prepare:ios."
    #endif
  }

  private func stop() {
    #if canImport(VkTurnCore)
    service?.stop()
    #endif
  }

  private func drainLogs() -> [String] {
    #if canImport(VkTurnCore)
    return splitLogLines(service?.drainLogs() ?? "")
    #else
    return []
    #endif
  }
}

private func splitLogLines(_ text: String) -> [String] {
  text
    .split(separator: "\n")
    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty }
}
