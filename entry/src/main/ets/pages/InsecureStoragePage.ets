import { promptAction, PromptAction } from '@kit.ArkUI';
import { InfoCard } from '../common/components/InfoCard';
import { SectionHeader } from '../common/components/SectionHeader';
import { StorageDemoService } from '../features/storage/storageDemoService';

@Entry
@Component
struct InsecureStoragePage {
  @State username: string = 'testuser';
  @State password: string = 'Password123';
  @State currentMode: 'insecure' | 'secure' = 'insecure';
  private context = getContext(this);
  private service: StorageDemoService = new StorageDemoService(this.context);

  async onSaveClick() {
    try {
      if (this.currentMode === 'insecure') {
        await this.service.savePlainCredential(this.username, this.password);
        this.getUIContext().getPromptAction().showToast({ message: '已执行：明文写入 & 日志泄露' });
      } else {
        await this.service.saveHashedCredential(this.username, this.password);
        this.getUIContext().getPromptAction().showToast({ message: '已执行：Hash 存储 & 日志脱敏' });
      }
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: `保存失败: ${e}` });
    }
  }

  build() {
    Column({ space: 20 }) {
      SectionHeader('不安全的数据存储 & 日志')

      Row({ space: 10 }) {
        this.renderModeButton('不安全演示', 'insecure');
        this.renderModeButton('安全做法', 'secure');
      }

      InfoCard({
        body: this.currentMode === 'insecure'
          ? '原因：凭据明文写入 Preferences，并将完整凭据记录在 hilog。'
          : '做法：密码仅以 Hash 形式持久化，日志中不输出敏感值。',
        tone: this.currentMode === 'insecure' ? 'warning' : 'success'
      })

      TextInput({ placeholder: '用户名', text: this.username })
        .onChange(val => this.username = val)
      TextInput({
        placeholder: '密码',
        text: this.password
      })
        .type(InputType.Password)
        .onChange(val => this.password = val)

      Button(this.currentMode === 'insecure' ? '执行不安全写入' : '执行安全写入')
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .onClick(() => this.onSaveClick())

      InfoCard({
        title: '操作指引',
        body: this.currentMode === 'insecure'
          ? '1. 执行后在 /data/storage/el2/base/haps/entry/preferences/vuln_credential.xml 找到明文账号。\n2. 使用 hilog 搜索 STORAGE_DEMO 关键字，可看到完整凭据泄露。'
          : '1. 执行后在 secure_credential.xml 中仅包含密码 Hash。\n2. 观察 hilog：日志不再包含敏感字段。',
        tone: 'default'
      })
    }
    .padding(20)
    .width('100%')
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
