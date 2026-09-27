import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';
import * as ScheduleSources from '../../constants/ScheduleSources'

let localStorage = new LocalStorage();

// 兼容 #AARRGGBB / #ARGB / #RRGGBB 三种色值串，取出左侧色条可用的颜色
function courseBarColor(color: string): string {
  if (color.length === 9) {
    return `#${color.slice(3)}`;
  }
  if (color.length === 5) {
    return `#${color.slice(2)}`;
  }
  return color;
}

@Entry(localStorage)
@Component
struct Class_schedule_dailyCard {
  @LocalStorageProp('todayCourse') todayCourse: ScheduleSources.classAttribute[] = [];
  @LocalStorageProp('tomorrowCourse') tomorrowCourse: ScheduleSources.classAttribute[] = [];
  @LocalStorageProp('title') title: ResourceStr = '';
  @LocalStorageProp('count') count: number = 0;

  @LocalStorageProp('cardListParameter') cardListParameter: CardListParameter = new CardListParameter(
    /* backgroundColor          */ $r('sys.color.ohos_id_color_background'),
    /* title                    */ $r('app.string.schedule_card_title'),
    /* backgroundImage          */ undefined,
    /* backgroundImageSize      */ ImageSize.Auto,
    /* isItemCount              */ true,
    /* itemCount                */ this.todayCourse.length,
    /* itemCountColor           */ $r('sys.color.ohos_id_color_emphasize'),
    /* itemCountBackgroundColor */ $r('app.color.list_item_count_background'),
    /* titleColor               */ undefined,
    /* isBottomIcon             */ false,
    /* bottomIcon               */ undefined
  )

  // 单条课程：窄列里课程名在上，教师/教室/时间在下，课程色作为左侧色条
  @Builder
  courseItem(course: ScheduleSources.classAttribute) {
    Column() {
      Text() {
        Span(course.name)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
        if (course.location !== '')
          Span(` @${course.location}`)
            .fontSize(11)
      }

      Text(`\udb81\uddf3 ${course.teacher}`)
        .fontSize(11)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .visibility(course.teacher == '' ? Visibility.None : Visibility.Visible)

      Text(`\udb80\udfdc ${ScheduleSources.commonClassTime[course.timeSpan[0]][0]}~${ScheduleSources.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
        .fontSize(11)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 5, right: 4, top: 2, bottom: 2 })
    .border({
      width: { left: 3 },
      color: { left: courseBarColor(course.color) }
    })
    .margin({ top: 3, bottom: 3 })
  }

  @Builder
  todayColumn() {
    Column() {
      Text($r('app.string.today_label'))
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.green'))
        .maxLines(1)
        // .margin({ bottom: 4 })

      if (this.todayCourse.length === 0) {
        Column() {
          Image($r('app.media.no_course_today'))
            .height(40)
            .interpolation(ImageInterpolation.Medium)
            .opacity(0.9)
          Text($r('app.string.no_class_today'))
            .fontSize(11)
            .textAlign(TextAlign.Center)
            .opacity(0.7)
            .margin({ top: 6 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 12 })
      } else {
        ForEach(this.todayCourse, (course: ScheduleSources.classAttribute) => {
          this.courseItem(course)
        })
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  tomorrowColumn() {
    Column() {
      Text($r('app.string.tomorrow_label'))
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.pink'))
        .maxLines(1)
        // .margin({ bottom: 4 })

      ForEach(this.tomorrowCourse, (course: ScheduleSources.classAttribute) => {
        this.courseItem(course)
      })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  cardListBuilder() {
    ListItem() {
      Row() {
        this.todayColumn()

        if (this.tomorrowCourse.length > 0) {
          this.tomorrowColumn()
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
  }

  build() {
    Column() {
      CardListComponent({ cardListParameter: this.cardListParameter, title: this.title, count: this.count }) {
        this.cardListBuilder();
      }
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { message: 'add detail', router: 'Schedule'}
      });
    })
  }
}
