import dataPreferences from '@ohos.data.preferences';
import hilog from '@ohos.hilog';
import cryptoFramework from '@ohos.security.cryptoFramework';
import type common from '@ohos.app.ability.common';

const DOMAIN = 0x2001;
const TAG = 'STORAGE_DEMO';
const INSECURE_PREF = 'vuln_credential';
const SECURE_PREF = 'secure_credential';

export class StorageDemoService {
  constructor(private readonly context: common.Context) {}

  async savePlainCredential(username: string, password: string) {
    const pref = await dataPreferences.getPreferences(this.context, INSECURE_PREF);
    await pref.put('username', username);
    await pref.put('password', password);
    await pref.flush();
    hilog.error(DOMAIN, TAG, '明文存储并记录日志: %{public}s / %{public}s', username, password);
  }

  async saveHashedCredential(username: string, password: string) {
    const pref = await dataPreferences.getPreferences(this.context, SECURE_PREF);
    await pref.put('username', username);
    await pref.put('password_hash', await this.sha256(password));
    await pref.flush();
    hilog.info(DOMAIN, TAG, '已存储账号，密码以 Hash 形式写入。');
  }

  private async sha256(input: string): Promise<string> {
    const md = cryptoFramework.createMd('SHA256');
    const data = new Uint8Array(this.stringToBytes(input));
    await md.update({ data });
    const out = await md.digest();
    return Array.from(out.data)
      .map((b: number) => b.toString(16).padStart(2, '0'))
      .join('');
  }

  private stringToBytes(str: string): number[] {
    const buf: number[] = [];
    for (let i = 0; i < str.length; i++) {
      buf.push(str.charCodeAt(i) & 0xff);
    }
    return buf;
  }
}
