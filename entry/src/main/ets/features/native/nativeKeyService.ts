import entry from 'libentry.so';

export class NativeKeyService {
  fetchHardcodedKey(): string {
    return entry.getSecretKeyFromNative();
  }

  async fetchRemoteKey(): Promise<string> {
    // 演示用途：真实场景应走安全信道请求服务端。
    const random = Math.floor(Date.now() % 1_000_000).toString(16).padStart(6, '0');
    return `KMS-${random}`;
  }
}
