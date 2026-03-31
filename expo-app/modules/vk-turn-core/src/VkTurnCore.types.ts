export type VkTurnCoreStatus = {
  isAvailable: boolean;
  isRunning: boolean;
};

export type VkTurnCoreModuleShape = {
  isAvailable: boolean;
  getStatus(): VkTurnCoreStatus;
  start(argumentsList: string[]): Promise<string | null>;
  stop(): void;
  isRunning(): boolean;
  drainLogs(): string[];
};
