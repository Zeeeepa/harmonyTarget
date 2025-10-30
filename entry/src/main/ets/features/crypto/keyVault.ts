import cryptoFramework from '@ohos.security.cryptoFramework';

export class KeyVault {
  readonly hardcodedKey = 'this_is_a_very_secret_key_123';
  readonly hardcodedMapApiKey = 'AKfj-s93f_thisIsAFakeBaiduMapKey';

  async generateRuntimeKey(): Promise<string> {
    const random = cryptoFramework.createRandom();
    const randomBlob = await random.generateRandom(16);
    return this.bytesToHex(Array.from(randomBlob.data));
  }

  private bytesToHex(bytes: number[]): string {
    return bytes.map(b => b.toString(16).padStart(2, '0')).join('');
  }
}
