import { requireOptionalNativeModule } from "expo";

import type { VkTurnCoreModuleShape } from "./VkTurnCore.types";

const stubModule: VkTurnCoreModuleShape = {
  isAvailable: false,
  getStatus() {
    return {
      isAvailable: false,
      isRunning: false
    };
  },
  async start(argumentsList: string[]) {
    return `VkTurnCore native module недоступен. Подготовь development build и framework. Аргументы: ${argumentsList.join(" ")}`;
  },
  stop() {},
  isRunning() {
    return false;
  },
  drainLogs() {
    return [];
  }
};

const VkTurnCore = requireOptionalNativeModule<VkTurnCoreModuleShape>("VkTurnCore") ?? stubModule;

export default VkTurnCore;
export * from "./VkTurnCore.types";
