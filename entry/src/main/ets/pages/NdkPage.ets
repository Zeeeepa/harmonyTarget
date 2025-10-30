import cryptoFramework from '@ohos.security.cryptoFramework';
import { InfoCard } from '../common/components/InfoCard';
import { SectionHeader } from '../common/components/SectionHeader';
import { NativeKeyService } from '../features/native/nativeKeyService';

@Entry
@Component
struct NdkPage {
  @State nativeKey: string = '点击按钮获取';
  @State errorMessage: string = '';
  @State inputText: string = '';
  @State encryptedText: string = '';
  @State currentMode: 'insecure' | 'secure' = 'insecure';
  private readonly keyService: NativeKeyService = new NativeKeyService();

  // 使用 HarmonyOS 加密框架 SM4(ECB/PKCS7) 加密并返回 HEX 字符串
  private encryptWithKey(plain: string, key: string): string {
    if (!key) {
      return '';
    }
    const keyBytes = this.normalizeKeyTo16Bytes(this.stringToBytes(key));
    const plainBytes = this.stringToBytes(plain);
    try {
      let symGen: cryptoFramework.SymKeyGenerator;
      try {
        symGen = cryptoFramework.createSymKeyGenerator('SM4_128');
      } catch (e1) {
        try {
          symGen = cryptoFramework.createSymKeyGenerator('SM4');
        } catch (e2) {
          this.errorMessage = `SM4算法不可用: ${e2}`;
          return '';
        }
      }
      const symKey = symGen.convertKeySync({ data: new Uint8Array(keyBytes) });
      let cipher: cryptoFramework.Cipher;
      try {
        cipher = cryptoFramework.createCipher('SM4|ECB|PKCS7');
      } catch (e) {
        // 兼容部分版本仅支持 PKCS5 的命名
        cipher = cryptoFramework.createCipher('SM4|ECB|PKCS5');
      }
      cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, null);
      const outBlob: cryptoFramework.DataBlob = cipher.doFinalSync({ data: new Uint8Array(plainBytes) });
      return this.bytesToHex(Array.from(outBlob.data));
    } catch (e) {
      this.errorMessage = `SM4加密失败: ${e}`;
      return '';
    }
  }

  private stringToBytes(str: string): number[] {
    const bytes: number[] = [];
    for (let i = 0; i < str.length; i++) {
      // 简化处理：仅取低8位，适用于演示
      bytes.push(str.charCodeAt(i) & 0xff);
    }
    return bytes;
  }

  private bytesToHex(bytes: number[]): string {
    const hex = '0123456789abcdef';
    let out = '';
    for (let i = 0; i < bytes.length; i++) {
      const b = bytes[i] & 0xff;
      out += hex.charAt((b >>> 4) & 0x0f) + hex.charAt(b & 0x0f);
    }
    return out;
  }

  private normalizeKeyTo16Bytes(src: number[]): number[] {
    const out = new Array<number>(16).fill(0);
    for (let i = 0; i < 16; i++) {
      out[i] = src[i % src.length] & 0xff;
    }
    return out;
  }

  build() {
    Column({ space: 20 }) {
      SectionHeader('SO原生库漏洞')

      Row({ space: 10 }) {
        this.renderModeButton('硬编码原生密钥', 'insecure');
        this.renderModeButton('服务端密钥分发', 'secure');
      }

      InfoCard({
        body: this.currentMode === 'insecure'
          ? '原因：libentry.so 中硬编码密钥，逆向 SO 即可恢复。'
          : '做法：ArkTS 通过服务端 APIs 动态请求密钥，原生模块不再持久化敏感值。',
        tone: this.currentMode === 'insecure' ? 'warning' : 'success'
      })

      Button(this.currentMode === 'insecure' ? '从.so文件获取密钥' : '向服务端请求密钥')
        .onClick(async () => {
          try {
            if (this.currentMode === 'insecure') {
              this.nativeKey = this.keyService.fetchHardcodedKey();
            } else {
              await this.requestSecureKey();
              return;
            }
            this.errorMessage = '';
          } catch (error) {
            console.error('调用native方法失败:', error);
            this.errorMessage = `错误: ${error}`;
          }
        })

      Text('从原生库获取到的密钥是:')
      Text(this.nativeKey)
        .fontColor(Color.Red)
        .fontSize(18)

      // 明文输入与加密操作
      Text('输入要加密的内容:')
      TextInput({ placeholder: '请输入明文...' })
        .width('100%')
        .onChange((val: string) => {
          this.inputText = val;
        })

      Button('使用SM4加密')
        .onClick(() => {
          try {
            if (!this.nativeKey || this.nativeKey === '点击按钮获取') {
              this.errorMessage = '请先获取密钥';
              return;
            }
            if (!this.inputText || this.inputText.length === 0) {
              this.errorMessage = '请输入明文';
              return;
            }
            const result: string = this.encryptWithKey(this.inputText, this.nativeKey);
            if (result && result.length > 0) {
              this.encryptedText = result;
              this.errorMessage = '';
            } else {
              // encryptWithKey 内部已设置错误信息，这里不清空，给出兜底提示
              if (!this.errorMessage) {
                this.errorMessage = '加密失败';
              }
            }
          } catch (e) {
            console.error('加密失败:', e);
            this.errorMessage = `加密错误: ${e}`;
          }
        })

      if (this.encryptedText) {
        Text('加密后的密文(HEX):')
        Text(this.encryptedText)
          .fontColor(Color.Blue)
          .fontSize(16)
      }

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontColor(Color.Orange)
          .fontSize(14)
      }

      Column() {
        InfoCard({
          title: '操作指引',
          body: this.currentMode === 'insecure'
            ? '1. 反编译 HAP，使用 IDA/Ghidra 查看 libentry.so，定位字符串常量。\n2. 结合 ArkTS 页面观察同一个密钥被直接使用。'
            : '1. 切换至"服务端密钥分发"后，libentry.so 中不再出现明文密钥。\n2. 可扩展为调用 TLS 通道，通过设备证书鉴权。',
          tone: 'default'
        })
      }
      .margin({ top: 30 })
    }
    .padding(20)
    .width('100%')
  }

  async requestSecureKey() {
    try {
      this.errorMessage = '';
      this.nativeKey = await this.keyService.fetchRemoteKey();
    } catch (error) {
      console.error('远程获取密钥失败:', error);
      this.errorMessage = `远程密钥错误: ${error}`;
    }
  }

  @Builder
  renderModeButton(label: string, mode: 'insecure' | 'secure') {
    Button(label)
      .backgroundColor(this.currentMode === mode ? '#007DFF' : '#e0e0e0')
      .fontColor(this.currentMode === mode ? Color.White : Color.Black)
      .onClick(() => {
        this.currentMode = mode;
        if (mode === 'secure') {
          this.nativeKey = '点击按钮获取';
        }
      });
  }
}
