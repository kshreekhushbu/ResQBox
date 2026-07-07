export type ConfigType = 'string' | 'html';

export interface Config {
  configId: number;
  configKey: string;
  configValue: string;
  createdAt: string;
  updatedAt: string;
}

export interface UpdateConfigPayload {
  configId: number;
  configValue: string;
}

export interface ConfigState {
  configs: Config[];
  currentConfig: Config | null;
  loading: boolean;
  error: string | null;
  successMessage: string | null;
}
