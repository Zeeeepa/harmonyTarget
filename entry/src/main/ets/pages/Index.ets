import router from '@ohos.router';
import { promptAction, PromptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { vulnerabilityCatalog } from '../core/data/vulnerabilityCatalog';
import type { VulnerabilityMeta } from '../core/models/Vulnerability';
import { InfoCard } from '../common/components/InfoCard';

@Entry
@Component
struct Index {
  private vulnerabilityList: VulnerabilityMeta[] = vulnerabilityCatalog;

  build() {
    Row() {
      Column() {
        Text('HarmonyOS 安全靶场')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .padding({ top: 20, bottom: 20 })

        List({ space: 12 }) {
          ForEach(this.vulnerabilityList, (item: VulnerabilityMeta) => {
            ListItem() {
              this.buildListItem(item)
            }
            .onClick(() => {
              this.onRouteTo(item);
            })
          })
        }
        .width('90%')
        .layoutWeight(1)
      }
      .width('100%')
    }
    .height('100%')
  }

  // 抽离出Dialog显示函数
  showDialog(title: string, message: string) {
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: title,
        message: message,
        buttons: [{ text: '好的', color: '#007DFF' }]
      });
    } catch (error) {
      const err = error as BusinessError;
      console.error(`showDialog failed, code is ${err.code}, message is ${err.message}`);
    }
  }

  @Builder
  buildListItem(item: VulnerabilityMeta) {
    Column() {
      Text(item.title).fontSize(18).fontWeight(FontWeight.Bold).width('100%').textAlign(TextAlign.Start)
      InfoCard({
        body: `漏洞成因：${item.insecureSummary}\n安全做法：${item.secureHint}`,
        tone: 'warning'
      })
    }
    .padding(15).backgroundColor(Color.White).borderRadius(10).shadow({ radius: 5, color: '#1F000000' })
  }

  onRouteTo(item: VulnerabilityMeta) {
    if (!item.targetPage || item.targetPage === '#') {
      if (item.exposeDialog) {
        this.showDialog(item.exposeDialog.title, item.exposeDialog.message);
      }
      return;
    }
    if (item.targetPage === '##') {
      if (item.exposeDialog) {
        this.showDialog(item.exposeDialog.title, item.exposeDialog.message);
      }
      return;
    }
    router.pushUrl({ url: item.targetPage });
  }
}
