import { promptAction, PromptAction } from '@kit.ArkUI';
import window from '@ohos.window';
import { InfoCard } from '../common/components/InfoCard';
import { SectionHeader } from '../common/components/SectionHeader';

@Entry
@Component
struct SecurePaymentPage {
  private win: window.Window | undefined = undefined;

  async aboutToAppear() {
    try {
      let windowClass = await window.getTopWindow(getContext(this));
      this.win = windowClass;
      // VULNERABILITY (from a feature perspective): 开启防截屏
      await this.win.setWindowPrivacyMode(true);
      this.getUIContext().getPromptAction().showToast({ message: '防截屏模式已开启' });
    } catch (exception) {
      console.error('Failed to set privacy mode. Cause: ' + JSON.stringify(exception));
    }
  }

  async aboutToDisappear() {
    // 离开页面时恢复，避免影响其他页面
    if (this.win) {
      try {
        await this.win.setWindowPrivacyMode(false);
      } catch (exception) {
        console.error('Failed to reset privacy mode. Cause: ' + JSON.stringify(exception));
      }
    }
  }

  build() {
    Column({ space: 20 }) {
      SectionHeader('模拟支付 (安全特性)')

      InfoCard({
        body: '场景：展示如何打开防录屏、使用安全键盘、在支付场景保持前台保护。未开启这些能力会导致截屏泄露、键盘被劫持等风险。',
        tone: 'success'
      })

      Text('支付金额').width('100%').textAlign(TextAlign.Start)
      TextInput({ text: '100.00' })
        .type(InputType.Number) // 使用数字安全键盘

      Text('支付密码').width('100%').textAlign(TextAlign.Start)
      TextInput({ placeholder: '请输入6位密码' })
        .type(InputType.Password) // 使用密码安全键盘
        .maxLength(6)

      Button('确认支付')
        .width('80%')
        .onClick(() => {
          this.getUIContext().getPromptAction().showToast({ message: '模拟支付成功' });
        })

      Column() {
        InfoCard({
          title: '操作指引',
          body: '1. 当前页面禁止截屏，尝试抓取屏幕将得到黑屏。\n2. 点击密码输入框，系统弹出安全键盘。\n3. 切换到后台时观察卡片提示，作为安全态感知示例。',
          tone: 'default'
        })
      }
      .margin({ top: 30 })
    }
    .padding(20).width('100%')
  }
}
