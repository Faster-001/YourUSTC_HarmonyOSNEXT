
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import * as ScheduleSources from '../constants/ScheduleSources';
import scheduleManager from '../utils/TimeTable';
import examManager, { examAttribute } from '../utils/ExamManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import UnifiedPreferences, { SCHEDULE_KEY, UID_KEY } from '../utils/UnifyPreference'
import { CardListParameter } from '../class_schedule_daily/viewmodel/CardListParameter';

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

class FormDataClass {
  todayCourse: ScheduleSources.classAttribute[] = [];
  tomorrowCourse: ScheduleSources.classAttribute[] = [];
  cardListParameter: CardListParameter = new CardListParameter(
    /* backgroundColor          */ $r('sys.color.ohos_id_color_background'),
    /* title                    */ $r('app.string.schedule_card_title'),
    /* backgroundImage          */ undefined,
    /* backgroundImageSize      */ ImageSize.Auto,
    /* isMask                   */ true,
    /* maskColor                */ $r('app.color.pure_white_or_black'),
    /* isItemCount              */ true,
    /* itemCount                */ 0,
    /* itemCountColor           */ $r('sys.color.ohos_id_color_emphasize'),
    /* itemCountBackgroundColor */ $r('app.color.list_item_count_background'),
    /* titleColor               */ undefined,
    /* isBottomIcon             */ false,
    /* bottomIcon               */ undefined
  )
  examInfo: examAttribute[] = [];
  lastRefresh: string = '';
  constructor(refreshType: number) {
    if (refreshType === 0) { // 0 → 刷新课表
      scheduleManager.getFormattedSchedule();
      if (!scheduleManager.isTermEnd) {
        this.todayCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
        this.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed +
          (scheduleManager.today == 5 ? 1 : 0)][(scheduleManager.today + 1) % 7];
      }
      this.cardListParameter.itemCount = this.todayCourse.length;
    } else if (refreshType === 1) { // 1 → 刷新考试
      this.cardListParameter.title = $r("app.string.exam_detail");
      examManager.readStoredExam();
      this.examInfo = examManager.allExamInfo;
      this.cardListParameter.itemCount = this.examInfo.length;
    }
    const now = scheduleManager.currentTime;
    this.lastRefresh = `上次刷新: ${now.getMonth() + 1}月${now.getDate()}日${now.getHours()}:${now.getMinutes().toString().padStart(2, '0')}`
  }
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    // Called to return a FormBindingData object.
    const formName = want.parameters![formInfo.FormParam.NAME_KEY].toString();
    UnifiedPreferences.init(this.context)
    let data: FormDataClass = new FormDataClass(formName.includes('schedule') ? 0 : 1);
    return formBindingData.createFormBindingData(data);
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string) {
    // Called to notify the form provider to update a specified form.
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${JSON.stringify(message)}`);

    UnifiedPreferences.init(this.context)
    const eventSource: string = JSON.parse(message).msgTest
    let formData = new FormDataClass(eventSource === 'schedule' ? 0 : 1);

    const formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    formProvider.updateForm(formId, formInfo).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
      console.info('FormAbility updateForm success')
    }).catch((error: Error) => {
      hilog.error(DOMAIN_NUMBER, TAG, `Operation updateForm failed. Cause: ${JSON.stringify(error)}`);
    });
  }

  onRemoveForm(formId: string) {
    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
}
