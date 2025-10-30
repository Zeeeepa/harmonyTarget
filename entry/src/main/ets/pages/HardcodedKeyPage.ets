import { promptAction, PromptAction } from '@kit.ArkUI';
import { InfoCard } from '../common/components/InfoCard';
import { SectionHeader } from '../common/components/SectionHeader';
import { KeyVault } from '../features/crypto/keyVault';

@Entry
@Component
struct HardcodedKeyPage {
  private readonly vault: KeyVault = new KeyVault();
  @State plainText: string = 'Hello HarmonyOS';
  @State encryptedText: string = '';
  @State runtimeKey: string = '';
  @State currentMode: 'insecure' | 'secure' = 'insecure';
  @State isProcessing: boolean = false;

  xorEncrypt(input: string, key: string): string {
    let output = '';
    for (let i = 0; i < input.length; i++) {
      output += String.fromCharCode(input.charCodeAt(i) ^ key.charCodeAt(i % key.length));
    }
    return output;
  }

  build() {
    Column({ space: 20 }) {
      SectionHeader('硬编码敏感信息 (ArkTS)')

      Row({ space: 10 }) {
        this.renderModeButton('硬编码密钥', 'insecure');
        this.renderModeButton('运行时密钥', 'secure');
      }

      InfoCard({
        body: this.currentMode === 'insecure'
          ? `原因：ArkTS 中持有密钥 "${this.vault.hardcodedKey}"，反编译即可直接读取。`
          : '做法：运行时通过安全随机数生成密钥，不在源码或包体中出现真实密钥。',
        tone: this.currentMode === 'insecure' ? 'warning' : 'success'
      })

      TextInput({ placeholder: '输入要加密的文本', text: this.plainText })
        .onChange(val => this.plainText = val)

      Button(this.currentMode === 'insecure' ? '使用硬编码密钥加密' : '使用运行时密钥加密')
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .onClick(() => this.handleEncrypt())
        .enabled(!this.isProcessing)

      Text('加密结果:')
      Text(this.encryptedText).fontColor(Color.Red)

      InfoCard({
        title: '操作指引',
        body: this.currentMode === 'insecure'
          ? `1. 反编译 HAP 并搜索 "${this.vault.hardcodedKey}"，可直接定位密钥。\n2. 观察另一个硬编码参数：${this.vault.hardcodedMapApiKey}。`
          : '1. 重新打包后搜索源码，运行时密钥不再出现。\n2. 可结合设备安全芯片/远程 KMS 动态下发密钥。',
        tone: 'default'
      })
    }
    .padding(20)
    .width('100%')
  }

  async handleEncrypt() {
    try {
      this.isProcessing = true;
      let key = this.vault.hardcodedKey;
      if (this.currentMode === 'secure') {
        key = this.runtimeKey.length > 0 ? this.runtimeKey : await this.vault.generateRuntimeKey();
        this.runtimeKey = key;
      }
      this.encryptedText = this.xorEncrypt(this.plainText, key);
      this.getUIContext().getPromptAction().showToast({ message: '加密完成' });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `加密失败: ${error}` });
    } finally {
      this.isProcessing = false;
    }
  }

  @Builder
  renderModeButton(label: string, mode: 'insecure' | 'secure') {
    Button(label)
      .backgroundColor(this.currentMode === mode ? '#007DFF' : '#e0e0e0')
      .fontColor(this.currentMode === mode ? Color.White : Color.Black)
      .onClick(() => {
        this.currentMode = mode;
      });
  }
}
