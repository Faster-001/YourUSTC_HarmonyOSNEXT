
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import ScheduleManager from '../utils/Classes/ScheduleManager';
import * as ScheduleStorage from '../utils/ScheduleStorage';
import * as ScheduleSources from '../constants/ScheduleSources';
import { examAttribute } from '../utils/ExamStorage';
import examManager from '../utils/ExamManager';
import * as ExamStorage from '../utils/ExamStorage';
import UnifiedPreferences, { millisecondsPerWeek } from '../utils/UnifyPreference';
import { i18n } from '@kit.LocalizationKit';
import * as TodoStorage from '../utils/TodoStorage';
import { TodoCardItem } from '../todo_info/viewmodel/TodoCardItem';

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

class FormDataClass {
  todayCourse: ScheduleSources.classAttribute[] = [];
  tomorrowCourse: ScheduleSources.classAttribute[] = [];
  title: ResourceStr = '';
  count: number = 0;
  examInfo: examAttribute[] = [];
  todoList: TodoCardItem[] = [];
  lastRefresh: string = '';
  currentTime: number = 0;
  constructor(refreshType: number) {
    const currentTime = new Date();
    this.currentTime = currentTime.getTime();
    if (refreshType === 0) { // 0 → 刷新课表
      ScheduleManager.init();
      this.title = $r("app.string.schedule_card_title");
      const termStartTime: number = ScheduleManager.semesters[ScheduleManager.defaultSemester].beginTime;

      let currentWeek: number = 0;
      if (this.currentTime < termStartTime) {
        currentWeek = 1;
        this.todayCourse = this.tomorrowCourse = [];
      } else if (this.currentTime > termStartTime + ScheduleManager.semesters[ScheduleManager.defaultSemester].totalWeekNum * millisecondsPerWeek) {
        currentWeek = 1;
        this.todayCourse = this.tomorrowCourse =  [];
      } else {
        currentWeek = Math.ceil((this.currentTime - termStartTime) / millisecondsPerWeek);

        // const todayStart: number = new Date(currentTime).setHours(0, 0, 0, 0);
        this.todayCourse = ScheduleManager.getDefaultClassByDay(currentWeek, currentTime.getDay())
        // .filter(item => ScheduleSources.commonClassStamp[item.timeSpan[item.timeSpan.length - 1]][1] + todayStart > this.currentTime)
          .sort((a, b) => a.timeSpan[0] - b.timeSpan[0]);

        this.tomorrowCourse = ScheduleManager.getDefaultClassByDay(currentWeek + (currentTime.getDay() === 6 ? 1 : 0), (currentTime.getDay() + 1) % 7)
          .sort((a, b) => a.timeSpan[0] - b.timeSpan[0]);
      }

      //this.cardListParameter.itemCount = this.todayCourse.length;
      this.count = this.todayCourse.length;
    } else if (refreshType === 1) { // 1 → 刷新考试
      this.title = $r("app.string.exam_detail");
      examManager.readStoredExam();
      this.examInfo = examManager.allExamInfo.filter(item => this.currentTime <= item.endTimeStamp);
      this.count = this.examInfo.length;
    } else if (refreshType === 2) { // 2 → 刷新待办
      this.title = $r("app.string.todo_card_title");
      const unfinished = TodoStorage.getUnfinished();
      unfinished.sort((a, b) => TodoStorage.getEffectiveTime(a.item) - TodoStorage.getEffectiveTime(b.item));
      this.todoList = unfinished.map((entry: TodoStorage.IndexedTodoItem): TodoCardItem => {
        const item = entry.item;
        return {
          text: (item.course ? item.course + '：' : '') + item.text,
          timeDesc: this.todoTimeDescription(item),
          overdue: TodoStorage.getEffectiveTime(item) <= this.currentTime,
          priority: item.priority ?? 0,
          isAssignment: item.type === TodoStorage.TodoType.Assignment,
          done: item.done
        } as TodoCardItem;
      });
      this.count = this.todoList.length;
    }
    this.lastRefresh = '上次刷新: ' + currentTime.toLocaleString('zh-cn', { month: 'short', day: 'numeric', hour: '2-digit', minute: 'numeric', hourCycle: i18n.System.is24HourClock() ? 'h23' : 'h12' });
  }

  /** 毫秒时间戳 → 'M-d HH:mm'（与 Todo 页面保持一致） */
  private todoFormatTime(ts: number): string {
    const d = new Date(ts);
    const pad = (n: number): string => (n < 10 ? '0' + n : '' + n);
    return `${d.getMonth() + 1}-${d.getDate()} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
  }

  /** 条目的时间描述文本（与 Todo 页面保持一致） */
  private todoTimeDescription(item: TodoStorage.TodoItem): string {
    if (item.type === TodoStorage.TodoType.Assignment) {
      return item.ddl !== undefined ? `DDL ${this.todoFormatTime(item.ddl)}` : '';
    }
    const parts: string[] = [];
    if (item.beginTime !== undefined) {
      parts.push(`始 ${this.todoFormatTime(item.beginTime)}`);
    }
    if (item.endTime !== undefined) {
      parts.push(`止 ${this.todoFormatTime(item.endTime)}`);
    }
    return parts.join('  ');
  }
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    // Called to return a FormBindingData object.
    UnifiedPreferences.init(this.context);
    ScheduleStorage.init(this.context);
    ExamStorage.init(this.context);
    TodoStorage.init(this.context);
    // console.log(JSON.stringify(want.parameters))

    const formName: string = want.parameters![formInfo.FormParam.NAME_KEY].toString();
    let formType: number = 1;
    if (formName === 'class_schedule_daily') {
      formType = 0;
    } else if (formName === 'todo_info') {
      formType = 2;
    }
    UnifiedPreferences.putSync('CardType_id' + want.parameters![formInfo.FormParam.IDENTITY_KEY], formType);
    return formBindingData.createFormBindingData(new FormDataClass(formType));
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string/*, param: Record<string, object>*/) {
    /* param 没用。参数示例如右：{"form_connect_id":224930369,"moduleName":"","ohos.extra.param.key.form_user_id":100}
     测试时的formId为1489478270
    */
    // Called to notify the form provider to update a specified form.
    UnifiedPreferences.init(this.context);
    ScheduleStorage.init(this.context);
    ExamStorage.init(this.context);
    TodoStorage.init(this.context);
    const formType: number = UnifiedPreferences.getNumberSync('CardType_id' + formId, -1);

    if (formType !== -1) {
      let formData = new FormDataClass(formType);

      formProvider.updateForm(formId, formBindingData.createFormBindingData(formData)).then(() => {
        hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
        console.info('FormAbility updateForm success');
      }).catch((error: Error) => {
        hilog.error(DOMAIN_NUMBER, TAG, `Operation updateForm failed. Cause: ${JSON.stringify(error)}`);
      });
    }
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${JSON.stringify(message)}`);

    UnifiedPreferences.init(this.context);
    ScheduleStorage.init(this.context);
    ExamStorage.init(this.context);
    TodoStorage.init(this.context);
    const eventSource: string = JSON.parse(message).msgTest;
    const refreshType: number = eventSource === 'schedule' ? 0 : (eventSource === 'todo' ? 2 : 1);
    let formData = new FormDataClass(refreshType);

    formProvider.updateForm(formId, formBindingData.createFormBindingData(formData)).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
      console.info('FormAbility updateForm success')
    }).catch((error: Error) => {
      hilog.error(DOMAIN_NUMBER, TAG, `Operation updateForm failed. Cause: ${JSON.stringify(error)}`);
    });
  }

  onRemoveForm(formId: string) {
    UnifiedPreferences.init(this.context);
    ScheduleStorage.init(this.context);
    ExamStorage.init(this.context);
    UnifiedPreferences.deleteSync('CardType_id' + formId);
    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
}