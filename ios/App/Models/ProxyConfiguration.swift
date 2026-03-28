import Foundation

struct ProxyConfiguration: Codable, Equatable {
    enum InviteService: String, Codable, CaseIterable, Identifiable {
        case vk = "VK Calls"
        case yandex = "Yandex Telemost"

        var id: String { rawValue }
    }

    var inviteService: InviteService = .vk
    var peer: String = ""
    var link: String = ""
    var listen: String = "127.0.0.1:9000"
    var streams: Int = 8
    var useUDP: Bool = true
    var noDTLS: Bool = false
    var turnHost: String = ""
    var turnPort: String = ""
    var rawMode: Bool = false
    var rawCommand: String = ""

    static let `default` = ProxyConfiguration()

    func commandArguments() throws -> [String] {
        if rawMode {
            var parsed = try ShellWords.parse(rawCommand)
            if let first = parsed.first, !first.hasPrefix("-") {
                parsed.removeFirst()
            }
            guard !parsed.isEmpty else {
                throw ConfigurationError.emptyRawCommand
            }
            return parsed
        }

        let trimmedPeer = peer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLink = link.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedListen = listen.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTurnHost = turnHost.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTurnPort = turnPort.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPeer.isEmpty else {
            throw ConfigurationError.missingPeer
        }
        guard !trimmedLink.isEmpty else {
            throw ConfigurationError.missingLink
        }
        guard streams > 0 else {
            throw ConfigurationError.invalidStreams
        }

        var arguments: [String] = []

        if !trimmedTurnHost.isEmpty {
            arguments.append(contentsOf: ["-turn", trimmedTurnHost])
        }
        if !trimmedTurnPort.isEmpty {
            arguments.append(contentsOf: ["-port", trimmedTurnPort])
        }

        arguments.append(contentsOf: ["-peer", trimmedPeer])
        arguments.append(contentsOf: [inviteService == .vk ? "-vk-link" : "-yandex-link", trimmedLink])
        arguments.append(contentsOf: ["-listen", trimmedListen.isEmpty ? "127.0.0.1:9000" : trimmedListen])
        arguments.append(contentsOf: ["-n", String(streams)])

        if useUDP {
            arguments.append("-udp")
        }
        if noDTLS {
            arguments.append("-no-dtls")
        }

        return arguments
    }
}

enum ConfigurationError: LocalizedError {
    case missingPeer
    case missingLink
    case invalidStreams
    case emptyRawCommand

    var errorDescription: String? {
        switch self {
        case .missingPeer:
            return "Укажите адрес peer сервера в формате IP:Port."
        case .missingLink:
            return "Добавьте ссылку на звонок VK или Telemost."
        case .invalidStreams:
            return "Количество потоков должно быть больше нуля."
        case .emptyRawCommand:
            return "Raw-команда пустая."
        }
    }
}

enum ShellWords {
    static func parse(_ input: String) throws -> [String] {
        var result: [String] = []
        var current = ""
        var activeQuote: Character?
        var escaping = false

        for character in input {
            if escaping {
                current.append(character)
                escaping = false
                continue
            }

            if character == "\\" {
                escaping = true
                continue
            }

            if let quote = activeQuote {
                if character == quote {
                    activeQuote = nil
                } else {
                    current.append(character)
                }
                continue
            }

            if character == "\"" || character == "'" {
                activeQuote = character
                continue
            }

            if character.isWhitespace {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
                continue
            }

            current.append(character)
        }

        if escaping {
            current.append("\\")
        }

        if activeQuote != nil {
            throw ShellWordsError.unclosedQuote
        }

        if !current.isEmpty {
            result.append(current)
        }

        return result
    }
}

enum ShellWordsError: LocalizedError {
    case unclosedQuote

    var errorDescription: String? {
        switch self {
        case .unclosedQuote:
            return "В raw-команде не закрыта кавычка."
        }
    }
}
