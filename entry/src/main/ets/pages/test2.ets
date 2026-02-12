// PageOne.ets
import { BackComponent } from './test';

export const COLOR1: string = "#80004AAF";
export const COLOR2: string = "#802787D9";
export const BLUR_STYLE_1: BlurStyle = BlurStyle.BACKGROUND_THIN;
export const BLUR_STYLE_2: BlurStyle = BlurStyle.BACKGROUND_THICK;
export const BLUR_STYLE_OPTION_1: BackgroundBlurStyleOptions = {
  colorMode: ThemeColorMode.DARK,
  adaptiveColor: AdaptiveColor.DEFAULT,
  blurOptions: { grayscale: [20, 20] },
  scale: 1
};
export const BLUR_STYLE_OPTION_2: BackgroundBlurStyleOptions = {
  colorMode: ThemeColorMode.LIGHT,
  adaptiveColor: AdaptiveColor.AVERAGE,
  blurOptions: { grayscale: [20, 20] },
  scale: 1
};
export const EFFECT_OPTION_1: BackgroundEffectOptions = {
  radius: 20,
  saturation: 10,
  brightness: 0,
  color: '#66FFFFFF',
  adaptiveColor: AdaptiveColor.DEFAULT,
  blurOptions: { grayscale: [0, 0] },
};
export const EFFECT_OPTION_2: BackgroundEffectOptions = {
  radius: 60,
  saturation: 40,
  brightness: 1,
  color: '#661A1A1A',
  adaptiveColor: AdaptiveColor.AVERAGE,
  blurOptions: { grayscale: [20, 20] },
};

@Builder
export function PageBuilder(name: string, param?: Object) {
  ColorAndBlur();
}

@Component
struct ColorAndBlur {
  @State useColor1: boolean = true;
  @State useBlur1: boolean = true;
  @State useEffect1: boolean = true;

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Center }) {
        BackComponent()
          .width('100%')
          .height('100%')
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Button("switch color")
              .onClick(() => {
                this.useColor1 = !this.useColor1;
              })
          }
          .width('100%')
          .layoutWeight(1)

          Stack({ alignContent: Alignment.Center }) {
            Button("switch blur")
              .onClick(() => {
                this.useBlur1 = !this.useBlur1;
              })
          }
          .width('100%')
          .layoutWeight(1)

          Stack({ alignContent: Alignment.Center }) {
            Button("switch effect")
              .onClick(() => {
                this.useEffect1 = !this.useEffect1;
              })
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
      }.width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    // 开发者可以设置标题栏的背景颜色和背景模糊效果
    .title("Destination Title", {
      backgroundColor: this.useColor1 ? COLOR1 : COLOR2,
      backgroundBlurStyle: this.useBlur1 ? BLUR_STYLE_1 : BLUR_STYLE_2,
      barStyle: BarStyle.STACK,
      backgroundEffect: this.useEffect1 ? EFFECT_OPTION_1 : EFFECT_OPTION_2,
    })
    // 开发者可以设置菜单的背景颜色和背景模糊效果
    .menus([
      { value: "A" },
      { value: "B" },
      { value: "C" },
      { value: "D" },
    ], {
      moreButtonOptions: {
        backgroundEffect: this.useEffect1 ? EFFECT_OPTION_1 : EFFECT_OPTION_2,
      }
    })
    // 开发者可以设置工具栏的背景颜色和背景模糊效果
    .toolbarConfiguration([
      { value: "A" },
      { value: "B" },
      { value: "C" },
      { value: "D" },
      { value: "E" },
      { value: "F" }
    ], {
      backgroundEffect: this.useEffect1 ? EFFECT_OPTION_1 : EFFECT_OPTION_2,
      // 开发者可以设置工具栏的菜单的背景颜色和背景模糊效果
      moreButtonOptions: {
        backgroundEffect: this.useEffect1 ? EFFECT_OPTION_1 : EFFECT_OPTION_2,
      }
    })
  }
}