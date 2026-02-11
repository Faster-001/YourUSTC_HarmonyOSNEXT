import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';
import examManager, { examAttribute } from '../../utils/ExamManager';

let localStorage = new LocalStorage();

@Entry(localStorage)
@Component
struct Class_schedule_dailyCard {
  @LocalStorageProp('examInfo') examInfo: examAttribute[] = [];

  @LocalStorageProp('cardListParameter') cardListParameter: CardListParameter = new CardListParameter(
    /* backgroundColor          */ $r('sys.color.ohos_id_color_background'),
    /* title                    */ $r('app.string.schedule_card_title'),
    /* backgroundImage          */ undefined,
    /* backgroundImageSize      */ ImageSize.Auto,
    /* isMask                   */ true,
    /* maskColor                */ $r('app.color.pure_white_or_black'),
    /* isItemCount              */ true,
    /* itemCount                */ this.examInfo.length,
    /* itemCountColor           */ $r('sys.color.ohos_id_color_emphasize'),
    /* itemCountBackgroundColor */ $r('app.color.list_item_count_background'),
    /* titleColor               */ undefined,
    /* isBottomIcon             */ false,
    /* bottomIcon               */ undefined
  )

  @Builder
  cardListBuilder() {
    if (this.examInfo.length === 0) {
      Column() {
        Image($r('app.media.no_exam1'))
          .height(75)
          .interpolation(ImageInterpolation.Medium)
        Text($r('app.string.no_exam_info1'));
      }
      .margin({ top: 12, bottom: 12 });
    } else {
      ForEach(this.examInfo, (singleExam: examAttribute, index: number) => {
        Row() {

          Column() {
            Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.End }) {
              Text(singleExam.name)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ right: 5 })
              Text(singleExam.type)
                .fontSize(16)
            }
            .margin({ bottom: 5 })

            Text(`\udb80\uddb8 ${singleExam.campus} ${singleExam.building} ${singleExam.classroom}`)
              .visibility(singleExam.campus + singleExam.building + singleExam.classroom == '' ? Visibility.None : Visibility.Visible);
            Text(`\udb80\udfdc ${singleExam.date}`)
              .visibility(singleExam.date == '' ? Visibility.None : Visibility.Visible);
          }
          .width('70%')
          .alignItems(HorizontalAlign.Start);
        }
        .width('90%')
        .margin({ top: 7, bottom: 7 })
        .borderRadius(20);

        if (index < this.examInfo.length - 1) {
          Divider().width('90%');
        }
      })
    }
  }

  build() {
    Column() {
      CardListComponent({ cardListParameter: this.cardListParameter }) {
        this.cardListBuilder();
      }
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { message: 'add detail', router: 'pages/ExamDetail'}
      });
    })
  }
}
