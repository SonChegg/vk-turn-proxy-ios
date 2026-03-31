import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Clipboard from "expo-clipboard";
import { startTransition, useEffect, useEffectEvent, useState } from "react";
import VkTurnCore from "vk-turn-core";

import {
  buildCommandArguments,
  defaultProxyConfiguration,
  type ProxyConfiguration
} from "../lib/proxyConfig";

const STORAGE_KEY = "vk-turn-proxy-expo.configuration";

function clampLogs(lines: string[]): string[] {
  if (lines.length <= 400) {
    return lines;
  }
  return lines.slice(lines.length - 400);
}

export function useProxyController() {
  const initialStatus = VkTurnCore.getStatus();

  const [config, setConfig] = useState<ProxyConfiguration>(defaultProxyConfiguration);
  const [logs, setLogs] = useState<string[]>(["Ожидание запуска..."]);
  const [isRunning, setIsRunning] = useState<boolean>(initialStatus.isRunning);
  const [bridgeAvailable, setBridgeAvailable] = useState<boolean>(initialStatus.isAvailable);
  const [lastError, setLastError] = useState<string | null>(null);

  const appendLocalLog = useEffectEvent((line: string) => {
    const trimmed = line.trim();
    if (!trimmed) {
      return;
    }

    setLogs((previous) => clampLogs([...previous, trimmed]));
  });

  const appendNativeLogs = useEffectEvent((incoming: string[]) => {
    const cleaned = incoming.map((line) => line.trim()).filter(Boolean);
    if (cleaned.length === 0) {
      return;
    }

    setLogs((previous) => clampLogs([...previous, ...cleaned]));
  });

  const persistConfiguration = useEffectEvent(async (next: ProxyConfiguration) => {
    try {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    } catch {
      appendLocalLog("Предупреждение: не удалось сохранить настройки локально.");
    }
  });

  const flushNativeState = useEffectEvent(() => {
    const status = VkTurnCore.getStatus();
    setBridgeAvailable(status.isAvailable);
    setIsRunning(status.isRunning);
    appendNativeLogs(VkTurnCore.drainLogs());
  });

  useEffect(() => {
    let cancelled = false;

    void (async () => {
      try {
        const saved = await AsyncStorage.getItem(STORAGE_KEY);
        if (!saved || cancelled) {
          return;
        }

        const parsed = JSON.parse(saved) as Partial<ProxyConfiguration>;
        startTransition(() => {
          setConfig({
            ...defaultProxyConfiguration,
            ...parsed
          });
        });
      } catch {
        appendLocalLog("Предупреждение: локальные настройки повреждены и были пропущены.");
      }
    })();

    flushNativeState();
    const interval = setInterval(() => {
      flushNativeState();
    }, 400);

    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, []);

  function updateField<Key extends keyof ProxyConfiguration>(key: Key, value: ProxyConfiguration[Key]) {
    setConfig((previous) => {
      const next = {
        ...previous,
        [key]: value
      };
      void persistConfiguration(next);
      return next;
    });
  }

  function resetConfiguration() {
    setConfig(defaultProxyConfiguration);
    void persistConfiguration(defaultProxyConfiguration);
    appendLocalLog("Настройки сброшены к значениям по умолчанию.");
  }

  async function startProxy() {
    try {
      const argumentsList = buildCommandArguments(config);
      await persistConfiguration(config);

      const error = await VkTurnCore.start(argumentsList);
      if (error) {
        setLastError(error);
        setIsRunning(false);
        appendLocalLog(`ОШИБКА: ${error}`);
        return;
      }

      setLastError(null);
      setIsRunning(true);
      appendLocalLog(`Команда: ${argumentsList.join(" ")}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Неизвестная ошибка запуска.";
      setLastError(message);
      setIsRunning(false);
      appendLocalLog(`ОШИБКА: ${message}`);
    }
  }

  function stopProxy() {
    VkTurnCore.stop();
    setIsRunning(false);
    appendLocalLog("Остановка отправлена.");
  }

  function toggleProxy() {
    if (isRunning) {
      stopProxy();
      return;
    }

    void startProxy();
  }

  async function copyLogs() {
    await Clipboard.setStringAsync(logs.join("\n"));
    appendLocalLog("Логи скопированы в буфер обмена.");
  }

  return {
    bridgeAvailable,
    config,
    copyLogs,
    isRunning,
    lastError,
    logs,
    logsText: logs.join("\n"),
    resetConfiguration,
    toggleProxy,
    updateField
  };
}
