export type InviteService = "vk" | "yandex";

export type ProxyConfiguration = {
  inviteService: InviteService;
  peer: string;
  link: string;
  listen: string;
  streams: number;
  useUDP: boolean;
  noDTLS: boolean;
  turnHost: string;
  turnPort: string;
  rawMode: boolean;
  rawCommand: string;
};

export const defaultProxyConfiguration: ProxyConfiguration = {
  inviteService: "vk",
  peer: "",
  link: "",
  listen: "127.0.0.1:9000",
  streams: 8,
  useUDP: true,
  noDTLS: false,
  turnHost: "",
  turnPort: "",
  rawMode: false,
  rawCommand: ""
};

export class ConfigurationError extends Error {}

export function buildCommandArguments(config: ProxyConfiguration): string[] {
  if (config.rawMode) {
    const parsed = parseShellWords(config.rawCommand);
    if (parsed.length > 0 && !parsed[0].startsWith("-")) {
      parsed.shift();
    }

    if (parsed.length === 0) {
      throw new ConfigurationError("Raw-команда пустая.");
    }

    return parsed;
  }

  const peer = config.peer.trim();
  const link = config.link.trim();
  const listen = config.listen.trim() || "127.0.0.1:9000";
  const turnHost = config.turnHost.trim();
  const turnPort = config.turnPort.trim();

  if (!peer) {
    throw new ConfigurationError("Укажите адрес peer сервера в формате IP:Port.");
  }
  if (!link) {
    throw new ConfigurationError("Добавьте ссылку на звонок VK или Telemost.");
  }
  if (config.streams <= 0) {
    throw new ConfigurationError("Количество потоков должно быть больше нуля.");
  }

  const argumentsList: string[] = [];

  if (turnHost) {
    argumentsList.push("-turn", turnHost);
  }
  if (turnPort) {
    argumentsList.push("-port", turnPort);
  }

  argumentsList.push("-peer", peer);
  argumentsList.push(config.inviteService === "vk" ? "-vk-link" : "-yandex-link", link);
  argumentsList.push("-listen", listen);
  argumentsList.push("-n", String(config.streams));

  if (config.useUDP) {
    argumentsList.push("-udp");
  }
  if (config.noDTLS) {
    argumentsList.push("-no-dtls");
  }

  return argumentsList;
}

export function parseShellWords(input: string): string[] {
  const result: string[] = [];
  let current = "";
  let activeQuote: "'" | '"' | null = null;
  let escaping = false;

  for (const character of input) {
    if (escaping) {
      current += character;
      escaping = false;
      continue;
    }

    if (character === "\\") {
      escaping = true;
      continue;
    }

    if (activeQuote) {
      if (character === activeQuote) {
        activeQuote = null;
      } else {
        current += character;
      }
      continue;
    }

    if (character === "'" || character === "\"") {
      activeQuote = character;
      continue;
    }

    if (/\s/.test(character)) {
      if (current) {
        result.push(current);
        current = "";
      }
      continue;
    }

    current += character;
  }

  if (escaping) {
    current += "\\";
  }

  if (activeQuote) {
    throw new ConfigurationError("В raw-команде не закрыта кавычка.");
  }

  if (current) {
    result.push(current);
  }

  return result;
}
