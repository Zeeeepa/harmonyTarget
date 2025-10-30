import { promptAction, PromptAction } from '@kit.ArkUI';
import web from '@ohos.web.webview';
import { BusinessError } from '@kit.BasicServicesKit';
import { InfoCard } from '../common/components/InfoCard';
import { SectionHeader } from '../common/components/SectionHeader';

class JsBridge {
  getSensitiveInfo(): string {
    return `设备SN: MOCK_SN_1234567890, API_Level: ${globalThis.ohos_api_version}`;
  }
}

@Entry
@Component
struct WebViewPage {
  @State urlInput: string = 'https://www.baidu.com';
  @State currentMode: 'insecure' | 'secure' = 'insecure';
  webviewController: web.WebviewController = new web.WebviewController();

  aboutToAppear() {
    this.configureBridge();
  }

  build() {
    Column() {
      SectionHeader('WebView 漏洞集合')

      Row({ space: 10 }) {
        this.renderModeButton('无防护', 'insecure');
        this.renderModeButton('安全配置', 'secure');
      }.width('90%').padding({ bottom: 10 })

      InfoCard({
        body: this.currentMode === 'insecure'
          ? '原因：原生对象暴露给任意源页面，输入任何 URL 都能执行 nativeBridge.* 方法。'
          : '做法：限制 URL 白名单，仅暴露必要方法，同时拦截可疑 Scheme。',
        tone: this.currentMode === 'insecure' ? 'warning' : 'success'
      })

      Row({ space: 10 }) {
        TextInput({ placeholder: '输入任意URL并加载', text: this.urlInput })
          .onChange(val => this.urlInput = val)
          .layoutWeight(1)
        Button('加载')
          .onClick(() => {
            if (this.currentMode === 'insecure') {
              this.webviewController.loadUrl(this.urlInput);
              return;
            }
            if (this.isUrlAllowed(this.urlInput)) {
              this.webviewController.loadUrl(this.urlInput);
            } else {
              this.showBlockedToast();
            }
          })
      }.width('90%')

      Web({ src: $rawfile('vuln.html'), controller: this.webviewController })
        .javaScriptAccess(true)
        .onControllerAttached(() => {
          this.configureBridge();
        })
        .layoutWeight(1)

      Column() {
        InfoCard({
          title: '操作指引',
          body: this.currentMode === 'insecure'
            ? '1. 在输入框填入 file:// 或恶意站点，仍可加载。\n2. 打开调试工具执行 nativeBridge.getSensitiveInfo()，可直接拿到敏感数据。'
            : '1. 尝试加载非白名单 URL，应用将拒绝。\n2. 在 JS 中访问未授权方法将抛出异常，观察 native 侧日志。',
          tone: 'default'
        })
      }
      .margin(20)
    }
    .width('100%').height('100%')
  }

  configureBridge() {
    interface WebviewControllerExt {
      deregisterJavaScriptProxy?: (name: string) => void;
    }

    const controller = this.webviewController as WebviewControllerExt;
    if (controller.deregisterJavaScriptProxy) {
      try {
        controller.deregisterJavaScriptProxy('nativeBridge');
      } catch (_) {
        // ignore if proxy not registered
      }
    }
    try {
      const exposedMethods = this.currentMode === 'insecure' ? ['*'] : ['getSensitiveInfo'];
      this.webviewController.registerJavaScriptProxy(new JsBridge(), 'nativeBridge', exposedMethods);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`registerJavaScriptProxy failed, code is ${err.code}, message is ${err.message}`);
    }
  }

  isUrlAllowed(url: string): boolean {
    const allowedHosts = ['www.bing.com', 'cn.bing.com', 'localhost'];
    if (!url || !url.startsWith('https://')) {
      return false;
    }
    const host = url.substring('https://'.length).split('/')[0];
    return allowedHosts.indexOf(host) >= 0;
  }

  showBlockedToast() {
    this.getUIContext().getPromptAction().showToast({ message: 'URL 不在白名单，已阻止加载' });
  }

  @Builder
  renderModeButton(label: string, mode: 'insecure' | 'secure') {
    Button(label)
      .backgroundColor(this.currentMode === mode ? '#007DFF' : '#e0e0e0')
      .fontColor(this.currentMode === mode ? Color.White : Color.Black)
      .onClick(() => {
        this.currentMode = mode;
        this.configureBridge();
      });
  }
}
