import BackgroundImage, { presetColor } from '../utils/BgImageManager';
import MessageDialog from '../view/MessageDialog';
import {
  TodoItem, TodoType, SubmitChannel, IndexedTodoItem, getItems,
  addItem, updateItem, removeItem, filterItems, getEffectiveTime
} from '../utils/TodoStorage';
import ScheduleManager from '../utils/Classes/ScheduleManager';
import * as ScheduleStorage from '../utils/ScheduleStorage';
import { classAttribute } from '../constants/ScheduleSources';
import {
  CounterComponent, CounterType,
  SegmentButton, SegmentButtonOptions, ItemRestriction, SegmentButtonTextItem,
  SegmentButtonItemTuple
} from '@kit.ArkUI';

/** 提交渠道显示名，下标与 SubmitChannel 枚举值对应 */
const CHANNEL_NAMES: string[] = ['BB', 'QQ', '邮箱', '线上', '线下'];

@Builder
export function TodoBuilder(name: string, param?: object) {
  TodoPage();
}

@Entry
@Component
struct TodoPage {

  pathStack: NavPathStack = new NavPathStack();
  msgDialogController?: CustomDialogController;

  /** 当前列表（已过滤、已按有效时间升序），index 为原始数组下标 */
  @State todoList: IndexedTodoItem[] = [];
  /** 过滤类型：-1 全部，其余为 TodoType */
  @State filterType: number = -1;
  /** 分类分段按钮选中项下标（0 全部 / 1 待办 / 2 作业），与 filterType 保持映射同步 */
  @State filterIndexes: number[] = [0];
  /** 分类分段按钮配置，颜色随主题在 refresh 中刷新 */
  @State filterOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [{ text: '全部' }, { text: '待办' }, { text: '作业' }] as ItemRestriction<SegmentButtonTextItem>,
    fontColor: presetColor[BackgroundImage.themeColor].accentColor,
    selectedFontColor: '#ffffff',
    backgroundColor: BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#33ffffff',
    selectedBackgroundColor: presetColor[BackgroundImage.themeColor].accentColor
  });
  @State showSheet: boolean = false;
  /** 正在编辑的条目原始下标，-1 表示新建 */
  @State editingIndex: number = -1;

  /** 课程过滤：'' 表示全部，其余为课程名 */
  @State filterCourse: string = '';
  /** 列表条目中出现过的课程名（用于过滤栏） */
  @State filterCourseNames: string[] = [];
  /** 编辑弹窗草稿：课程分类 */
  @State draftCourse: string = '';
  /** 默认学期课表中的课程名列表（去重），供快速填写 */
  @State courseNames: string[] = [];

  // 编辑弹窗草稿
  @State draftType: TodoType = TodoType.Todo;
  /** 类型分段按钮选中项下标（0 待办事项 / 1 作业），与 draftType 同步 */
  @State draftTypeIndexes: number[] = [0];
  /** 类型分段按钮配置，颜色随主题在 refresh 中刷新 */
  @State draftTypeOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: '待办事项' }, { text: '作业' }] as SegmentButtonItemTuple,
    multiply: false,
    fontColor: presetColor[BackgroundImage.themeColor].accentColor,
    selectedFontColor: '#ffffff',
    backgroundColor: '#33888888',
    selectedBackgroundColor: presetColor[BackgroundImage.themeColor].accentColor
  });
  @State draftText: string = '';
  @State draftBeginEnabled: boolean = false;
  @State draftEndEnabled: boolean = false;
  @State draftDate: string = '2026-01-01';
  @State beginHour: number = 8;
  @State beginMinute: number = 0;
  @State endHour: number = 22;
  @State endMinute: number = 0;
  @State draftChannels: boolean[] = [false, false, false, false, false];

  /** 分段按钮下标 → 过滤类型 */
  filterIndexToType(index: number): number {
    return [-1, TodoType.Todo, TodoType.Assignment][index];
  }

  refresh(): void {
    // SegmentButton 的颜色保存在 options 中，主题变化时需手动同步
    const accent = presetColor[BackgroundImage.themeColor].accentColor;
    this.filterOptions.fontColor = accent;
    this.filterOptions.selectedBackgroundColor = accent;
    this.draftTypeOptions.fontColor = accent;
    this.draftTypeOptions.selectedBackgroundColor = accent;
    this.filterOptions.backgroundColor =
      BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#33ffffff';
    const courseSet: string[] = [];
    getItems().forEach((item: TodoItem): void => {
      if (item.course !== undefined && item.course !== '' && !courseSet.includes(item.course)) {
        courseSet.push(item.course);
      }
    });
    this.filterCourseNames = courseSet;
    if (this.filterCourse !== '' && !courseSet.includes(this.filterCourse)) {
      this.filterCourse = '';
    }
    const list = filterItems((item: TodoItem): boolean =>
      (this.filterType < 0 || item.type === this.filterType) &&
      (this.filterCourse === '' || item.course === this.filterCourse));
    list.sort((a: IndexedTodoItem, b: IndexedTodoItem): number =>
      getEffectiveTime(a.item) - getEffectiveTime(b.item));
    this.todoList = list;
  }

  /** 从默认学期课表中读取课程名列表（去重），供编辑弹窗快速填写 */
  loadCourseNames(): void {
    const names: string[] = [];
    try {
      const semester = ScheduleManager.semesters[ScheduleManager.defaultSemester];
      const courses = ScheduleStorage.getCourses(semester.createTime);
      courses.forEach((c: classAttribute): void => {
        if (c.name !== '' && !names.includes(c.name)) {
          names.push(c.name);
        }
      });
    } catch (e) {
      console.error('Todo: failed to load course names:', JSON.stringify(e));
    }
    this.courseNames = names;
  }

  pad2(value: number): string {
    return value.toString().padStart(2, '0');
  }

  /** 毫秒时间戳 → 'M-d HH:mm' */
  formatTime(ts: number): string {
    const d = new Date(ts);
    return `${d.getMonth() + 1}-${d.getDate()} ${this.pad2(d.getHours())}:${this.pad2(d.getMinutes())}`;
  }

  /** 'yyyy-MM-dd' + 时分 → 毫秒时间戳 */
  buildTime(date: string, hour: number, minute: number): number {
    const parts = date.split('-');
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]),
      hour, minute, 0).getTime();
  }

  /** 打开新建/编辑弹窗 */
  openEditor(indexed?: IndexedTodoItem): void {
    const today = new Date();
    this.draftDate = `${today.getFullYear()}-${this.pad2(today.getMonth() + 1)}-${this.pad2(today.getDate())}`;
    this.beginHour = today.getHours();
    this.beginMinute = 0;
    this.endHour = today.getHours() + 2 > 23 ? 23 : today.getHours() + 2;
    this.endMinute = 0;
    this.draftChannels = [false, false, false, false, false];
    if (indexed === undefined) {
      this.editingIndex = -1;
      this.draftType = TodoType.Todo;
      this.draftText = '';
      this.draftCourse = '';
      this.draftBeginEnabled = false;
      this.draftEndEnabled = false;
    } else {
      const item = indexed.item;
      this.editingIndex = indexed.index;
      this.draftType = item.type;
      this.draftText = item.text;
      this.draftCourse = item.course ?? '';
      if (item.type === TodoType.Assignment) {
        this.draftEndEnabled = item.ddl !== undefined;
        this.draftBeginEnabled = false;
        if (item.ddl !== undefined) {
          const d = new Date(item.ddl);
          this.draftDate = `${d.getFullYear()}-${this.pad2(d.getMonth() + 1)}-${this.pad2(d.getDate())}`;
          this.endHour = d.getHours();
          this.endMinute = d.getMinutes();
        }
        (item.channels ?? []).forEach((ch: SubmitChannel) => {
          this.draftChannels[ch] = true;
        });
      } else {
        this.draftBeginEnabled = item.beginTime !== undefined;
        this.draftEndEnabled = item.endTime !== undefined;
        if (item.beginTime !== undefined) {
          const d = new Date(item.beginTime);
          this.draftDate = `${d.getFullYear()}-${this.pad2(d.getMonth() + 1)}-${this.pad2(d.getDate())}`;
          this.beginHour = d.getHours();
          this.beginMinute = d.getMinutes();
        }
        if (item.endTime !== undefined) {
          const d = new Date(item.endTime);
          this.draftDate = `${d.getFullYear()}-${this.pad2(d.getMonth() + 1)}-${this.pad2(d.getDate())}`;
          this.endHour = d.getHours();
          this.endMinute = d.getMinutes();
        }
      }
    }
    this.draftTypeIndexes = [this.draftType];
    this.showSheet = true;
  }

  /** 组装草稿为 TodoItem；时间未启用的字段返回 undefined */
  buildDraftItem(): TodoItem {
    const item: TodoItem = {
      type: this.draftType,
      text: this.draftText.trim(),
      done: false,
      submitted: false,
      channels: []
    };
    if (this.draftCourse.trim() !== '') {
      item.course = this.draftCourse.trim();
    }
    if (this.draftType === TodoType.Assignment) {
      if (this.draftEndEnabled) {
        item.ddl = this.buildTime(this.draftDate, this.endHour, this.endMinute);
      }
      item.channels = CHANNEL_NAMES
        .map((_: string, i: number): SubmitChannel => i as SubmitChannel)
        .filter((ch: SubmitChannel): boolean => this.draftChannels[ch]);
      item.submitted = false;
    } else {
      if (this.draftBeginEnabled) {
        item.beginTime = this.buildTime(this.draftDate, this.beginHour, this.beginMinute);
      }
      if (this.draftEndEnabled) {
        item.endTime = this.buildTime(this.draftDate, this.endHour, this.endMinute);
      }
    }
    return item;
  }

  saveDraft(): void {
    if (this.draftText.trim() === '') {
      return;
    }
    const newItem = this.buildDraftItem();
    if (this.editingIndex >= 0) {
      updateItem(this.editingIndex, newItem);
    } else {
      addItem(newItem);
    }
    this.showSheet = false;
    this.refresh();
  }

  confirmDelete(): void {
    this.msgDialogController = new CustomDialogController({
      builder: MessageDialog({
        message: '确定删除这条内容吗？',
        onConfirm: () => {
          if (this.editingIndex >= 0) {
            removeItem(this.editingIndex);
          }
          this.showSheet = false;
          this.refresh();
        }
      }),
      autoCancel: true,
      gridCount: 4
    });
    this.msgDialogController.open();
  }

  /** 显式复制一条 TodoItem（ArkTS 禁用 Object.assign 与无类型对象字面量） */
  copyItem(item: TodoItem): TodoItem {
    return {
      type: item.type,
      text: item.text,
      course: item.course,
      beginTime: item.beginTime,
      endTime: item.endTime,
      ddl: item.ddl,
      done: item.done,
      submitted: item.submitted,
      channels: item.channels
    } as TodoItem;
  }

  /** 切换完成状态 */
  toggleDone(indexed: IndexedTodoItem): void {
    const item = this.copyItem(indexed.item);
    item.done = !item.done;
    updateItem(indexed.index, item);
    this.refresh();
  }

  toggleSubmitted(indexed: IndexedTodoItem): void {
    const item = this.copyItem(indexed.item);
    item.submitted = !item.submitted;
    updateItem(indexed.index, item);
    this.refresh();
  }

  /** 条目的时间描述文本 */
  timeDescription(item: TodoItem): string {
    if (item.type === TodoType.Assignment) {
      return item.ddl !== undefined ? `DDL ${this.formatTime(item.ddl)}` : '';
    }
    const parts: string[] = [];
    if (item.beginTime !== undefined) {
      parts.push(`始 ${this.formatTime(item.beginTime)}`);
    }
    if (item.endTime !== undefined) {
      parts.push(`止 ${this.formatTime(item.endTime)}`);
    }
    return parts.join('  ');
  }

  @Builder
  filterBar() {
    Row() {
      SegmentButton({
        options: this.filterOptions,
        selectedIndexes: $filterIndexes,
        onItemClicked: (index: number) => {
          this.filterType = this.filterIndexToType(index);
          this.refresh();
        }
      })
    }
    .width('60%')
    .margin({ top: 8 })
  }

  @Builder
  courseFilterBar() {
    Scroll() {
      Row({ space: 8 }) {
        Text('全部')
          .fontSize(13)
          .fontColor(this.filterCourse === '' ? '#ffffff' :
            presetColor[BackgroundImage.themeColor].accentColor)
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .borderRadius(12)
          .backgroundColor(this.filterCourse === '' ?
            presetColor[BackgroundImage.themeColor].accentColor : '#33888888')
          .onClick(() => {
            this.filterCourse = '';
            this.refresh();
          })
        ForEach(this.filterCourseNames, (name: string) => {
          Text(name)
            .fontSize(13)
            .fontColor(this.filterCourse === name ? '#ffffff' :
              presetColor[BackgroundImage.themeColor].accentColor)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .borderRadius(12)
            .backgroundColor(this.filterCourse === name ?
              presetColor[BackgroundImage.themeColor].accentColor : '#33888888')
            .onClick(() => {
              this.filterCourse = name;
              this.refresh();
            })
        })
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .margin({ top: 8 })
  }

  @Builder
  todoCard(indexed: IndexedTodoItem) {
    Row({ space: 10 }) {
      // 完成/提交状态圆圈
      Stack() {
        Circle()
          .width(24)
          .height(24)
          .fill('#0000')
          .stroke(indexed.item.done || indexed.item.submitted ?
            presetColor[BackgroundImage.themeColor].accentColor : '#66888888')
          .strokeWidth(2)
        if (indexed.item.done || indexed.item.submitted) {
          Image($r('app.media.checkmark'))
            .width(14)
            .height(14)
            .draggable(false)
        }
      }
      .width(28)
      .height(28)
      .onClick(() => this.toggleDone(indexed))

      Column({ space: 3 }) {
        Row({ space: 6 }) {
          Text(indexed.item.type === TodoType.Assignment ? '作业' : '待办')
            .fontSize(11)
            .fontColor('#ffffff')
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .borderRadius(6)
            .backgroundColor(indexed.item.type === TodoType.Assignment ?
              $r('app.color.hour') : $r('app.color.green'))
          if (indexed.item.course !== undefined && indexed.item.course !== '') {
            Text(indexed.item.course)
              .fontSize(11)
              .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
              .borderRadius(6)
              .border({ width: 1, color: presetColor[BackgroundImage.themeColor].accentColor })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.MARQUEE })
          }
          Text(indexed.item.text)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .decoration({
              type: indexed.item.done ? TextDecorationType.LineThrough : TextDecorationType.None,
              color: Color.Gray
            })
            .layoutWeight(1)
        }

        if (this.timeDescription(indexed.item) !== '') {
          Text(this.timeDescription(indexed.item))
            .fontSize(12)
            .fontColor(!indexed.item.done && getEffectiveTime(indexed.item) <= Date.now() ?
              $r('app.color.minute') : $r('app.color.transparent_text'))
        }

        if (indexed.item.type === TodoType.Assignment && indexed.item.channels.length > 0) {
          Row({ space: 5 }) {
            ForEach(indexed.item.channels, (ch: SubmitChannel) => {
              Text(CHANNEL_NAMES[ch])
                .fontSize(10)
                .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .borderRadius(5)
                .border({
                  width: 1,
                  color: presetColor[BackgroundImage.themeColor].accentColor
                })
            })
            Blank()
            Text(indexed.item.submitted ? '已提交' : '未提交')
              .fontSize(11)
              .fontColor(indexed.item.submitted ? $r('app.color.green') : $r('app.color.hour'))
              .onClick(() => this.toggleSubmitted(indexed))
          }
          .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .margin({ top: 8 })
    .borderRadius(16)
    .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .onClick(() => this.openEditor(indexed))
  }

  @Builder
  editorSheet() {
    Column() {
      Row({ space: 5 }) {
        Text(this.editingIndex >= 0 ? '编辑' : '新建')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .margin({ left: 8 })

        if (this.editingIndex >= 0) {
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.trash_red'))
              .width(24)
              .height(24)
              .draggable(false)
          }
          .width(42)
          .height(42)
          .onClick(() => this.confirmDelete())
        }

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .width(24)
            .height(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .onClick(() => {
          this.showSheet = false;
        })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.save'))
            .width(24)
            .height(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .onClick(() => this.saveDraft())
      }
      .width('100%')
      .margin({ bottom: 10 })

      Scroll() {
        Column() {
          // 类型切换
          Row() {
            Text('类型')
              .width(70)
            Row() {
              SegmentButton({
                options: this.draftTypeOptions,
                selectedIndexes: $draftTypeIndexes,
                onItemClicked: (index: number) => {
                  this.draftType = index as TodoType;
                }
              })
            }
            .layoutWeight(1)
          }
          .margin({ bottom: 10 })

          // 内容
          Row() {
            Text('内容')
              .width(70)
            TextInput({ text: this.draftText, placeholder: '要做的事情…' })
              .layoutWeight(1)
              .onChange((input: string) => {
                this.draftText = input;
              })
          }
          .margin({ bottom: 10 })

          // 课程分类
          Row() {
            Text('课程')
              .width(70)
            TextInput({ text: this.draftCourse, placeholder: '课程分类（可留空）' })
              .layoutWeight(1)
              .onChange((input: string) => {
                this.draftCourse = input;
              })
          }
          .margin({ bottom: 6 })

          // 从默认学期课程快速填写
          if (this.courseNames.length > 0) {
            Row() {
              Scroll() {
                Row({ space: 8 }) {
                  ForEach(this.courseNames, (name: string) => {
                    Text(name)
                      .fontSize(13)
                      .fontColor(this.draftCourse === name ? '#ffffff' :
                        presetColor[BackgroundImage.themeColor].accentColor)
                      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                      .borderRadius(12)
                      .backgroundColor(this.draftCourse === name ?
                        presetColor[BackgroundImage.themeColor].accentColor : '#33888888')
                      .onClick(() => {
                        this.draftCourse = this.draftCourse === name ? '' : name;
                      })
                  })
                }
              }
              .scrollable(ScrollDirection.Horizontal)
              .width('100%')
            }
            .margin({ bottom: 10 })
          }

          if (this.draftType === TodoType.Todo) {
            // 待办：开始时间
            Row() {
              Toggle({ type: ToggleType.Checkbox, isOn: this.draftBeginEnabled })
                .onChange((isOn: boolean) => {
                  this.draftBeginEnabled = isOn;
                })
              Text('开始时间')
                .width(60)
              Text(this.draftDate)
                .opacity(this.draftBeginEnabled ? 1 : 0.4)
                .onClick(() => {
                  if (!this.draftBeginEnabled) {
                    return;
                  }
                  this.pickDate();
                })
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.beginHour,
                    min: 0,
                    step: 1,
                    max: 23,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.beginHour = value;
                    }
                  }
                }
              })
              Text(' : ')
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.beginMinute,
                    min: 0,
                    step: 1,
                    max: 59,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.beginMinute = value;
                    }
                  }
                }
              })
            }
            .width('100%')
            .margin({ bottom: 10 })

            // 待办：截止时间
            Row() {
              Toggle({ type: ToggleType.Checkbox, isOn: this.draftEndEnabled })
                .onChange((isOn: boolean) => {
                  this.draftEndEnabled = isOn;
                })
              Text('截止时间')
                .width(60)
              Text(this.draftDate)
                .opacity(this.draftEndEnabled ? 1 : 0.4)
                .onClick(() => {
                  if (!this.draftEndEnabled) {
                    return;
                  }
                  this.pickDate();
                })
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.endHour,
                    min: 0,
                    step: 1,
                    max: 23,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.endHour = value;
                    }
                  }
                }
              })
              Text(' : ')
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.endMinute,
                    min: 0,
                    step: 1,
                    max: 59,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.endMinute = value;
                    }
                  }
                }
              })
            }
            .width('100%')
          } else {
            // 作业：DDL
            Row() {
              Toggle({ type: ToggleType.Checkbox, isOn: this.draftEndEnabled })
                .onChange((isOn: boolean) => {
                  this.draftEndEnabled = isOn;
                })
              Text('DDL')
                .width(60)
              Text(this.draftDate)
                .opacity(this.draftEndEnabled ? 1 : 0.4)
                .onClick(() => {
                  if (!this.draftEndEnabled) {
                    return;
                  }
                  this.pickDate();
                })
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.endHour,
                    min: 0,
                    step: 1,
                    max: 23,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.endHour = value;
                    }
                  }
                }
              })
              Text(' : ')
              CounterComponent({
                options: {
                  type: CounterType.INLINE,
                  inlineOptions: {
                    value: this.endMinute,
                    min: 0,
                    step: 1,
                    max: 59,
                    textWidth: 25,
                    onChange: (value: number) => {
                      this.endMinute = value;
                    }
                  }
                }
              })
            }
            .width('100%')
            .margin({ bottom: 10 })

            // 作业：提交渠道多选
            Column() {
              Text('提交渠道（可多选）')
                .fontSize(14)
                .margin({ bottom: 6 })
              Row({ space: 8 }) {
                ForEach(CHANNEL_NAMES, (name: string, index: number) => {
                  Text(name)
                    .fontSize(13)
                    .fontColor(this.draftChannels[index] ? '#ffffff' : presetColor[BackgroundImage.themeColor].accentColor)
                    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                    .borderRadius(12)
                    .backgroundColor(this.draftChannels[index] ?
                      presetColor[BackgroundImage.themeColor].accentColor : '#33888888')
                    .onClick(() => {
                      this.draftChannels[index] = !this.draftChannels[index];
                    })
                })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }
        }
        .width('100%')
      }
      .align(Alignment.Top)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
    .padding({ top: 16, left: 16, right: 16 })
  }

  pickDate(): void {
    const parts = this.draftDate.split('-');
    DatePickerDialog.show({
      selected: new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])),
      onDateAccept: (value: Date) => {
        this.draftDate =
          `${value.getFullYear()}-${this.pad2(value.getMonth() + 1)}-${this.pad2(value.getDate())}`;
      }
    });
  }

  menuItems: Array<NavigationMenuItem> = [
    {
      value: '新建',
      icon: $r('app.media.plus_square'),
      action: () => {
        this.openEditor();
      }
    }
  ];

  build() {
    NavDestination() {
      Column() {
        this.filterBar()

        if (this.filterCourseNames.length > 0) {
          this.courseFilterBar()
        }

        if (this.todoList.length === 0) {
          Column() {
            Image($r('app.media.list_square_bill'))
              .width(80)
              .draggable(false)
              .opacity(0.6)
            Text('暂无内容，点击右上角新建')
              .fontSize(16)
              .margin({ top: 10 })
              .fontColor($r('app.color.transparent_text'))
          }
          .height('70%')
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.todoList, (indexed: IndexedTodoItem) => {
              ListItem() {
                this.todoCard(indexed)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .padding({ left: 12, right: 12, top: 4 })
        }
      }
      .height('100%')
      .width('100%')
      .bindSheet($$this.showSheet, this.editorSheet(), {
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        preferType: SheetType.CENTER,
        showClose: false,
        scrollSizeMode: ScrollSizeMode.CONTINUOUS,
        backgroundColor: '#0000',
        blurStyle: BlurStyle.Regular
      })
    }
    .title('待办与作业', {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? BackgroundImage.titleBackgroundColor : undefined
    })
    .backButtonIcon($r('app.media.close'))
    .menus(this.menuItems)
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.loadCourseNames();
      this.refresh();
    })
  }
}
