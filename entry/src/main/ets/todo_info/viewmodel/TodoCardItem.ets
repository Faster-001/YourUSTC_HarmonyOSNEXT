/**
 * 桌面小组件（待办清单卡片）使用的展示数据。
 * 由 EntryFormAbility 从 TodoStorage 读取原始条目后预处理为纯文本字段，
 * 避免在卡片受限运行环境中执行文件读写与复杂逻辑。
 */
export interface TodoCardItem {
  /** 主标题：含课程前缀，如「高数：完成习题」 */
  text: string;
  /** 时间描述：如「DDL 9-20 22:00」「始 …  止 …」，无时间为空串 */
  timeDesc: string;
  /** 是否已到期未完成（用于时间文本高亮） */
  overdue: boolean;
  /** 重要度 0-10，0 表示未设置（不显示徽章） */
  priority: number;
  /** 是否为作业类型（显示「作业」徽章） */
  isAssignment: boolean;
  /** 是否已完成（主标题加删除线） */
  done: boolean;
}
