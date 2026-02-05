import { webview } from '@kit.ArkWeb';
import UnifiedPreferences from '../utils/UnifyPreference';
import { setUSTCLink, setHUSTLink } from '../constants/Links';

@Entry
@Component
struct Declaration {
  @State agreePolitic: boolean = false;
  @State chooseSchool: number = -1;
  @State showSheet: boolean = false;
  @State knowIndependence: boolean = false;
  private webController: webview.WebviewController = new webview.WebviewController();

  onBackPress(): boolean {
    return true;
  }

  build() {
    Stepper() {
      // 同意用户协议和隐私政策
      StepperItem() {
        Column() {
          Column({ space: 7 }) {
            Image($r('app.media.icon_round'))
              .height(80)
              .width(80)
            Text($r('app.string.welcome_to_your_ustc'))
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 10 })
          }

          Row() {
            Checkbox()
              .onChange((value: boolean) => {
                this.agreePolitic = value;
              })
            Text() {
              Span($r('app.string.read_privacy_policy'))
              Span($r('app.string.terms_of_use_and_privacy_policy'))
                .fontColor($r('app.color.active_text'))
                .onClick(() => {
                  this.showSheet = true;
                })
                .decoration({
                  type: TextDecorationType.Underline,
                  color: $r('app.color.active_text')
                })
            }
          }
        }
        .justifyContent(FlexAlign.SpaceAround)
        .padding(15)
        .height('90%')
        .width('90%')
        .bindSheet($$this.showSheet, this.agreementSheet(), {
          detents: [SheetSize.LARGE],
          preferType: SheetType.CENTER
        })
      }
      .status(this.agreePolitic ? ItemState.Normal: ItemState.Disabled)

      StepperItem() {
        Column({ space: 7 }) {
          Text($r('app.string.no_association1'))
            .fontSize(24)
            .fontWeight(FontWeight.Bolder)
          Scroll() {
            Text($r('app.string.no_association2'))
              .fontColor($r('app.color.red'))
          }
          Text($r('app.string.no_association3'))
            .copyOption(CopyOptions.InApp)
          TextArea()
            .maxLines(4)
            .onChange((value: string) => {
              if (value === '我已知晓并承认“妮可之记”由中科大学生独立开发，与华中科技大学和中国科学技术大学官方无任何关联') {
                this.knowIndependence = true;
              }
            })
          Text($r('app.string.no_association4'))
            .fontColor($r('app.color.green'))
            .visibility(this.knowIndependence ? Visibility.Visible : Visibility.Hidden)
        }
        .justifyContent(FlexAlign.Center)
        .padding(15)
        .height('90%')
        .width('90%')
      }
      .status(this.knowIndependence ? ItemState.Normal : ItemState.Disabled)

      StepperItem() {
        Column({ space: 7 }) {
          Text($r('app.string.choose_school'))
            .fontSize(24)
            .fontWeight(FontWeight.Bolder)
          Select([{ value: '华中科技大学' }, { value: '中国科学技术大学' }])
            .onSelect((index: number) => {
              this.chooseSchool = index;
            })
          Text($r('app.string.will_support_school'))
            .fontSize(12)
            .fontColor($r('app.color.transparent_text'))
        }
        .justifyContent(FlexAlign.Center)
        .padding(15)
        .height('90%')
        .width('90%')
      }
      .nextLabel('妮可，启动！')
      .status(this.chooseSchool === -1 ? ItemState.Disabled : ItemState.Normal)
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onFinish(() => {
      switch (this.chooseSchool) {
        case 0:
          UnifiedPreferences.putSync('school', 'HUST');
          setHUSTLink();
          break;
        case 1:
          UnifiedPreferences.putSync('school', 'USTC');
          setUSTCLink();
          break;
      }
      UnifiedPreferences.putSync('InitialLaunch', false);
      this.getUIContext().getRouter().back();
    })
  }

  @Builder
  agreementSheet() {
    Web({ src: $rawfile('TermsOfUse.html'), controller: this.webController })
      .height('100%')
      .width('100%')
      .darkMode(WebDarkMode.Auto)
      .backgroundColor($r('app.color.normal_background'))
  }
}