import { InfoCard } from '../common/components/InfoCard';
import { SectionHeader } from '../common/components/SectionHeader';
import { NetworkDemoService } from '../features/network/networkDemoService';

@Entry
@Component
struct InsecureNetworkPage {
  @State responseText: string = '等待请求...';
  @State currentMode: 'insecure' | 'secure' = 'insecure';
  private service: NetworkDemoService = new NetworkDemoService();

  async fetchData() {
    this.responseText = '请求中...';
    try {
      const payload = this.currentMode === 'insecure'
        ? await this.service.requestOverHttp()
        : await this.service.requestOverHttps();
      this.responseText = `响应内容:\n${payload}`;
    } catch (err) {
      this.responseText = `请求失败: ${JSON.stringify(err)}`;
    }
  }

  build() {
    Column({ space: 20 }) {
      SectionHeader('不安全的网络通信')

      Row({ space: 10 }) {
        this.renderModeButton('HTTP 明文', 'insecure');
        this.renderModeButton('HTTPS 加密', 'secure');
      }

      InfoCard({
        body: this.currentMode === 'insecure'
          ? '原因：请求通过 http:// 发送，流量可被中间人截获与篡改。'
          : '做法：强制使用 https:// 并校验返回结果，避免敏感参数暴露。',
        tone: this.currentMode === 'insecure' ? 'warning' : 'success'
      })

      Button(this.currentMode === 'insecure' ? '发起 HTTP 请求' : '发起 HTTPS 请求')
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .onClick(() => this.fetchData())

      Scroll() {
        Text(this.responseText)
          .width('100%')
          .padding(10)
          .backgroundColor('#f0f0f0')
          .borderRadius(10)
      }
      .layoutWeight(1)

      InfoCard({
        title: '操作指引',
        body: this.currentMode === 'insecure'
          ? '1. 启动抓包工具，观察 HTTP 请求中 param 参数为明文。\n2. 在代理工具中直接篡改响应，应用仍会信任。'
          : '1. 切换至 HTTPS 后，抓包需导入证书才能解密。\n2. 可进一步在代码中追加证书固定实现完整防护。',
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
        this.responseText = '等待请求...';
      });
  }
}
