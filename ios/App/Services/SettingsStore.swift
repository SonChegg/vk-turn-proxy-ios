import Foundation

enum SettingsStore {
    private static let configurationKey = "vk-turn-proxy-ios.configuration"

    static func load() -> ProxyConfiguration {
        guard
            let data = UserDefaults.standard.data(forKey: configurationKey),
            let config = try? JSONDecoder().decode(ProxyConfiguration.self, from: data)
        else {
            return .default
        }

        return config
    }

    static func save(_ configuration: ProxyConfiguration) {
        guard let data = try? JSONEncoder().encode(configuration) else {
            return
        }

        UserDefaults.standard.set(data, forKey: configurationKey)
    }
}
