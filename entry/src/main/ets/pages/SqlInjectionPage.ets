import { promptAction, PromptAction } from '@kit.ArkUI';
import { InfoCard } from '../common/components/InfoCard';
import { SectionHeader } from '../common/components/SectionHeader';
import { SqlTrainingRepository } from '../features/database/sqlTrainingRepository';

@Entry
@Component
struct SqlInjectionPage {
  @State searchName: string = '';
  @State searchResult: string = '尚未查询';
  @State currentMode: 'insecure' | 'secure' = 'insecure';
  private repository: SqlTrainingRepository = new SqlTrainingRepository();

  async aboutToAppear() {
    try {
      await this.repository.ensureReady(getContext(this));
    } catch (e) {
      this.searchResult = `数据库初始化失败: ${JSON.stringify(e)}`;
    }
  }

  async onSearch() {
    try {
      const resultStr = this.currentMode === 'insecure'
        ? await this.repository.queryWithConcatenation(this.searchName)
        : await this.repository.queryWithParameters(this.searchName);
      this.searchResult = resultStr;
    } catch (e) {
      this.searchResult = `查询失败: ${JSON.stringify(e)}`;
    }
  }

  build() {
    Column({ space: 20 }) {
      SectionHeader('SQLite SQL注入漏洞')

      Row({ space: 10 }) {
        this.renderModeButton('拼接查询', 'insecure');
        this.renderModeButton('参数化查询', 'secure');
      }

      InfoCard({
        body: this.currentMode === 'insecure'
          ? '原因：用户输入直接拼接进 SQL，可构造 \' OR \'1\'=\'1 实现注入。'
          : '做法：使用 RdbPredicates 绑定参数，数据库驱动负责转义。',
        tone: this.currentMode === 'insecure' ? 'warning' : 'success'
      })

      TextInput({ placeholder: '输入用户名搜索', text: this.searchName })
        .onChange(val => this.searchName = val)

      Button(this.currentMode === 'insecure' ? '执行拼接查询' : '执行安全查询')
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .onClick(() => this.onSearch())

      Scroll() {
        Text(this.searchResult)
          .width('100%')
          .padding(10)
          .backgroundColor('#f0f0f0')
          .borderRadius(10)
      }.layoutWeight(1)

      InfoCard({
        title: '操作指引',
        body: this.currentMode === 'insecure'
          ? '1. 输入 \' OR \'1\'=\'1 并执行，所有用户将被枚举。\n2. 结合 hilog，可看到完整的拼接 SQL。'
          : '1. 输入同样的 payload，结果应为空。\n2. 检查日志：不再打印构造 SQL。可继续扩展白名单、最小权限等策略。',
        tone: 'default'
      })
    }
    .padding(20).width('100%')
  }

  @Builder
  renderModeButton(label: string, mode: 'insecure' | 'secure') {
    Button(label)
      .backgroundColor(this.currentMode === mode ? '#007DFF' : '#e0e0e0')
      .fontColor(this.currentMode === mode ? Color.White : Color.Black)
      .onClick(() => {
        this.currentMode = mode;
        this.searchResult = '尚未查询';
      });
  }
}
