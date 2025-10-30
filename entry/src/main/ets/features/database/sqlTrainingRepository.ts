import relationalStore from '@ohos.data.relationalStore';
import hilog from '@ohos.hilog';
import type common from '@ohos.app.ability.common';

const DB_NAME = 'vuln_user.db';
const TABLE_NAME = 'users';
const DOMAIN = 0x2002;
const TAG = 'SQL_TRAINING';

export class SqlTrainingRepository {
  private store: relationalStore.RdbStore | null = null;

  async ensureReady(context: common.Context) {
    if (this.store) {
      return;
    }
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    this.store = await relationalStore.getRdbStore(context, config);
    await this.bootstrap();
  }

  async queryWithConcatenation(input: string): Promise<string> {
    if (!this.store) {
      throw new Error('store not initialized');
    }
    const vulnerableSql = `SELECT * FROM ${TABLE_NAME} WHERE name = '${input}'`;
    hilog.error(DOMAIN, TAG, 'Executing unsafe SQL: %{public}s', vulnerableSql);
    const resultSet = await this.store.querySql(vulnerableSql);
    const formatted = this.formatResult(resultSet);
    resultSet.close();
    return formatted;
  }

  async queryWithParameters(input: string): Promise<string> {
    if (!this.store) {
      throw new Error('store not initialized');
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME).equalTo('name', input);
    const columns = ['id', 'name', 'description'];
    const resultSet = await this.store.query(predicates, columns);
    const formatted = this.formatResult(resultSet);
    resultSet.close();
    return formatted;
  }

  private async bootstrap() {
    if (!this.store) {
      return;
    }
    const createTableSql =
      `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT)`;
    await this.store.executeSql(createTableSql);
    await this.store.executeSql(`DELETE FROM ${TABLE_NAME}`);
    await this.store.executeSql(`INSERT INTO ${TABLE_NAME}(name, description) VALUES ('admin', '系统管理员, 掌握最高权限')`);
    await this.store.executeSql(`INSERT INTO ${TABLE_NAME}(name, description) VALUES ('alice', '普通用户, 财务部门')`);
    await this.store.executeSql(`INSERT INTO ${TABLE_NAME}(name, description) VALUES ('bob', '普通用户, 技术部门')`);
    hilog.info(DOMAIN, TAG, '数据库初始化完成');
  }

  private formatResult(resultSet: relationalStore.ResultSet): string {
    let report = `查询到 ${resultSet.rowCount} 条结果:\n`;
    if (resultSet.rowCount === 0) {
      return report;
    }
    resultSet.goToFirstRow();
    do {
      const id = resultSet.getLong(resultSet.getColumnIndex('id'));
      const name = resultSet.getString(resultSet.getColumnIndex('name'));
      const desc = resultSet.getString(resultSet.getColumnIndex('description'));
      report += `ID: ${id}, Name: ${name}, Desc: ${desc}\n`;
    } while (resultSet.goToNextRow());
    return report;
  }
}
