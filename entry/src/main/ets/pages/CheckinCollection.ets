
import BackgroundImage, { presetColor } from '../utils/BgImageManager';
import { CheckInTools } from '../utils/CheckIn'
import { common } from '@kit.AbilityKit';
import { WantAbility } from '../utils/WantAbility';


@Builder
export function CheckinBuilder(name: string, param?: object) {
  CheckinGallery();
}

@Entry
@Component
struct CheckinGallery {

  menuItems: Array<NavigationMenuItem> = [
    {
      value: "获取概率说明",
      icon: $r('app.media.info_circle'),
      action: () => {
        this.showProbabilityNotice = true;
      }
    },
    {
      value: $r('app.string.join_qq_group'),
      icon: $r('app.media.message_on_message'),
      action: () => WantAbility.StartQQ(this.getUIContext().getHostContext() as common.UIAbilityContext)
    }
  ];
  pathStack: NavPathStack = new NavPathStack();
  @State LPercent: number = 0;
  @State RPercent: number = 0;
  build() {
    NavDestination() {
      List() {
        ForEach(CheckInTools.getCollectionStatus(), (item: boolean, index: number) => {
          ListItem() {
            if (item) {
              Row() {
                Text(CheckInTools.CHECK_IN_CONTENT_LIST[index])
                  .layoutWeight(1)
                  .wordBreak(WordBreak.BREAK_ALL)
              }
              .width('100%')
            } else {
              Row() {
                Image($r('app.media.lock'))
                  .width(24)
                  .height(24)
                  .draggable(false)
                  .margin({ right: 8 })
                Text('？？？')
                  .layoutWeight(1)
              }
              .width('100%')
            }
          }
          .margin({ top: 10 })
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
        })


        ListItem() { // 没什么用的小动画(doge)
          Stack({ alignContent: Alignment.Start }) {
            Text($r('app.string.require_more_sentences'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .fontSize(14)

            Row() {
              Row()
                .width(`${this.LPercent}%`)
                .height(70)
                .renderFit(RenderFit.RESIZE_COVER)
              Row()
                .width(`${this.RPercent}%`)
                .backgroundColor(presetColor[BackgroundImage.themeColor].accentColor)
                .height(70)
                .renderFit(RenderFit.RESIZE_COVER)
            }
            .width('100%')
          }
          .height(70)
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .width('100%')
          .onClick(() => {
            this.LPercent = this.RPercent = 0;
            this.getUIContext().keyframeAnimateTo({ iterations: 1 },
              [{
                duration: 500,
                curve: Curve.Ease,
                event: () => {
                  this.RPercent = 100;
                }
              }, {
                duration: 500,
                curve: Curve.Ease,
                event: () => {
                  this.LPercent = 100;
                  this.RPercent = 0;
                }
              }]
            );
            WantAbility.StartQQ(this.getUIContext().getHostContext() as common.UIAbilityContext);
          })
        }
        .margin({ top: 10, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .alignListItem(ListItemAlign.Center)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .padding({ left: 12, right: 12 })
      .bindSheet($$this.showProbabilityNotice, this.probabilityNotice(), {
        title: { title: '获取概率公示' },
        detents: [SheetSize.FIT_CONTENT],
        preferType: SheetType.CENTER,
        backgroundColor: Color.Transparent,
        blurStyle: BlurStyle.Regular,
        showClose: true,
        enableOutsideInteractive: false,
        enableFloatingDragBar: true,
        mode: SheetMode.OVERLAY
      })
    }
    .title({ main: $r('app.string.archive'), sub: $r('app.string.unlock_item_num', CheckInTools.getCollectionNumber(), CheckInTools.CHECK_IN_CONTENT_LIST.length) }, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? BackgroundImage.titleBackgroundColor : undefined
    })
    .menus(this.menuItems)
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }

  @State showProbabilityNotice: boolean = false;

  @Builder noticeTitle(title: string) {
    Text(title)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .margin({ top: 12, bottom: 4 })
  }

  @Builder noticeBody(text: string) {
    Text(text)
      .fontSize(12)
      .lineHeight(19)
      .opacity(0.85)
  }

  // 概率数值需与 utils/CheckIn.ets 中 THEMED_WEIGHT_* 及 weightedPick 的抽取权重保持一致
  @Builder probabilityNotice() {
    Column() {
      this.noticeTitle('〓类别介绍〓')
      this.noticeBody('所有签到词按触发条件可分为：\n1. 特定时间段（通用签到词）：按当前时刻从四个时段池中抽取：半夜（0~4点）、早晨（5~9点）、白天（10~18点）、晚上（19~24点）。同一个签到词可能会出现在多个时段池中\n2. 特定日期（主题签到词）：节日、开学第一天、学期最后一天\n3. 当天的课程和考试（主题签到词）：考试日、有课日、无课日')

      this.noticeTitle('〓抽取规则〓')
      this.noticeBody('1. 每日签到时抽取一次，先判定今日命中的主题，优先级为：特定日期 > 考试日 > 有课日 / 无课日\n2. 命中主题后，按下列概率抽取该主题的签到词；未命中主题或概率落空时，改为抽取当前时段的通用签到词：\n　　· 特定日期、学期开始和结束日：100%\n　　· 考试日：80%\n　　· 有课日 / 无课日：8%\n3. 在所选的签到词池内按权重随机抽取：未收集的签到词权重为 5，已收集的为 1，即未收集的句子被抽中的概率约为已收集的 5 倍')

      this.noticeTitle('〓其他说明〓')
      this.noticeBody('单次抽取结果完全独立，无保底机制。祝早日集齐全部签到词！')
    }
    .padding({ left: 16, right: 16, bottom: 16 })
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
