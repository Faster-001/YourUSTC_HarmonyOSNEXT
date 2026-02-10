
import { LengthUnit } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { getRandomInt } from '../utils/tools'
import BackgroundImage from '../view/BgImageManager'
import { common } from '@kit.AbilityKit'
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit'


@Entry
@Component
struct About {

  private context = this.getUIContext();
  private iconClickTime: number = 0;
  @State isShowEggImage: boolean = false;
  @State imagePixelMap?: image.PixelMap = undefined;
  @State showUpdateLog: boolean = false;

  private shareController: systemShare.ShareController | undefined = undefined;
  private iconThumbnail: Uint8Array | undefined = undefined;

  async aboutToAppear() {
    this.imagePixelMap = await this.getPixmapFromMedia($r('app.media.nic'))
  }

  aboutToDisappear(): void {
    this.imagePixelMap?.release();
  }

  build() {
    Stack({ alignContent: Alignment.Top}) {
      Scroll() {
        Column() {
          Column() {
            Image($r('app.media.ciallo'))
              .width('90%')
              .draggable(false)
              .constraintSize({ maxWidth: 300 })
              .onClick(() => {
                this.context.getPromptAction().showToast({ message: $r('app.string.egg_hint' + getRandomInt(1, 2).toString()) });
                this.iconClickTime++;
                if (this.iconClickTime >= 7) {
                  this.isShowEggImage = true;
                }
              })
              .bindContentCover(this.isShowEggImage, this.EggImage(), ModalTransition.DEFAULT)

            Text($r('app.string.welcome_to_your_ustc'))
              .fontSize(22)
              .fontColor($r('app.color.normal_text'))
              .fontWeight(FontWeight.Bold)

            Text() {
              Span($r('app.string.version'))
                .onClick(() => { this.showUpdateLog = true; })
              Span('  |  ')
                .decoration(undefined)
                .fontColor(undefined)
              Span($r('app.string.homepage_website'))
                .onClick(() => {
                  this.context.getRouter().pushUrl({
                    url: 'pages/Webview',
                    params: {
                      title: $r('app.string.homepage_website'),
                      url: 'https://dailynic.feixu.site/'
                    }
                  }).catch((err: Error) => {
                    console.error(`Router ERROR: [${err.name}] ${err.message}`)
                  })
                })
              Span('  |  ')
                .decoration(undefined)
                .fontColor(undefined)
              Span($r('app.string.join_qq_group'))
                .onClick(() => {
                  (this.context.getHostContext() as common.UIAbilityContext)
                    .openLink("mqqapi://card/show_pslcard?src_type=internal&version=1&uin=931920982&card_type=group&source=external&jump_from=webapi", { appLinkingOnly: false })
                })
            }
            .margin({ top: 10, bottom: 10 })
            .fontColor($r('app.color.active_text'))
            .decoration({
              type: TextDecorationType.Underline,
              color: $r('app.color.active_text')
            })
            .bindSheet($$this.showUpdateLog, this.UpdateLog(), {
              detents: [SheetSize.LARGE],
              preferType: SheetType.CENTER,
              title: { subtitle: $r('app.string.version'), title: $r('app.string.update_log')},
              backgroundColor: '#00d00721',
              blurStyle: BlurStyle.Regular
            })

            Text() {
              Span($r('app.string.github'))
                .fontColor($r('app.color.active_text'))
                .decoration({
                  type: TextDecorationType.Underline,
                  color: $r('app.color.active_text')
                })
                .onClick(() => {
                  this.context.showAlertDialog({
                    title: $r('app.string.about_to_open_github'),
                    message: $r('app.string.about_to_open_github_failed'),
                    confirm: {
                      value: $r('app.string.ok'),
                      action: () => {
                        (this.context.getHostContext() as common.UIAbilityContext).startAbility({
                          action: 'ohos.want.action.viewData',
                          entities: ['entity.system.browsable'],
                          uri: 'https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT'
                        })
                      }
                    }
                  });
                })

              ImageSpan($r('app.media.GPLv3'))
                .height(20)
                .margin({ left: 10 })
                .objectFit(ImageFit.Fill)
                .verticalAlign(ImageSpanAlignment.BOTTOM)
                .onClick(() => {
                  this.context.getRouter().pushUrl({
                    url: 'pages/Webview',
                    params: {
                      title: $r('app.string.open_source_license'),
                      url: $rawfile('OpenSourceLicense.html')
                    }
                  }).catch((err: Error) => {
                    console.error(`Router ERROR: [${err.name}] ${err.message}`)
                  })
                })
            }

            Row({ space: 15 }) {
              Text($r('app.string.developer_list'))
                .textAlign(TextAlign.Center)
              Text($r('app.string.special_thanks'))
                .textAlign(TextAlign.Center)
            }
            .alignItems(VerticalAlign.Top)
            .margin({ top: 15})

            Text($r('app.string.credits'))
              .textAlign(TextAlign.Center)
              .lineSpacing({ value: 5, unit: LengthUnit.FP })
              .margin({ top: 15, bottom: 15 })

            Text() {
              Span($r('app.string.terms_of_use_and_privacy_policy'))
                .onClick(() => {
                  this.context.getRouter().pushUrl({
                    url: 'pages/Webview',
                    params: {
                      title: $r('app.string.terms_of_use_and_privacy_policy'),
                      url: $rawfile('TermsOfUse.html')
                    }
                  }).catch((err: Error) => {
                    console.error(`Router ERROR: [${err.name}] ${err.message}`)
                  })
                })

              Span('  |  ')
                .decoration(undefined)
                .fontColor(undefined)

              Span($r('app.string.beian_info'))
                .onClick(() => {
                  this.context.getRouter().pushUrl({
                    url: 'pages/Webview',
                    params: {
                      title: $r('app.string.beian_query'),
                      url: 'https://beian.miit.gov.cn/'
                    }
                  }).catch((err: Error) => {
                    console.error(`Router ERROR: [${err.name}] ${err.message}`)
                  })
                })
            }
            .fontSize(12)
            .fontColor($r('app.color.active_text'))
            .decoration({
              type: TextDecorationType.Underline,
              color: $r('app.color.active_text')
            })
          }
          .margin({ top: 20 })
          .padding(10)
          .borderRadius(12)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.normal_background') : undefined)
          .opacity(BackgroundImage.opacityLevel)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .padding({ bottom: 20 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      Row() {
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .height(42)
        .width(42)
        .backgroundBlurStyle(BackgroundImage.blurLevel)
        .onClick(() => {
          this.context.getRouter().back();
        });

        Blank();

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.share'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .height(42)
        .width(42)
        .backgroundBlurStyle(BackgroundImage.blurLevel)
        .onClick(() => {
          if (this.iconThumbnail === undefined) {
            // 获取资源文件内容，返回Uint8Array。
            this.iconThumbnail = ((this.context.getHostContext() as common.UIAbilityContext).resourceManager).getRawFileContentSync('IconThumbnail.png');
          }

          if (this.shareController === undefined) {
            // 构造ShareData，需配置一条有效数据信息
            const shareData = new systemShare.SharedData({
              utd: uniformTypeDescriptor.UniformDataType.TEXT,
              content: '还在为找校园服务入口发愁？试试我正在使用的「妮可之记」鸿蒙版！一站式导航+课表/考试管理，适配HarmonyOS NEXT，科大师生必备～你可以直接在华为应用市场搜索，或者去https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT找到它！',
              title: '妮可之记 for HarmonyOS NEXT',
              thumbnail: this.iconThumbnail,
              description: '专为HarmonyOS NEXT开发，轻松查询课表、考试安排，支持校园服务网页一键访问，开源免费且无任何广告，深度适配鸿蒙系统特性，让你的校园生活更高效。'
            });
            shareData.addRecord({
              utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
              content: 'https://dailynic.feixu.site',
              title: '妮可之记 for HarmonyOS NEXT',
              thumbnail: this.iconThumbnail,
              description: '专为HarmonyOS NEXT开发，轻松查询课表、考试安排，支持校园服务网页一键访问，开源免费且无任何广告，深度适配鸿蒙系统特性，让你的校园生活更高效。'
            });
            this.shareController = new systemShare.ShareController(shareData);
          }
          this.shareController.show(this.context.getHostContext() as common.UIAbilityContext, {
            selectionMode: systemShare.SelectionMode.SINGLE,
            previewMode: systemShare.SharePreviewMode.DETAIL,
          }).then(() => {
            console.info('ShareController show success.');
          }).catch((error: BusinessError) => {
            console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
          });
        });
      }
      .opacity(BackgroundImage.opacityLevel)
      .width('100%')
      .padding({ top: 10, left: 10, right: 10 })
    }
    .backgroundImage(BackgroundImage.pic)
    .backgroundImageSize(ImageSize.Cover)
    .backgroundImagePosition(Alignment.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.normal_background'))
  }

  @Builder
  UpdateLog() {
    List() {
      // ForEach
      ListItem() {
        Column() {
          Text($r('app.string.version_1_0_0_date'))
            .fontWeight(FontWeight.Bolder)
          Row() {
            Text($r('app.string.feat'))
              .fontWeight(FontWeight.Bold)
              .fontSize(14)
              .fontColor($r('app.color.pink'))
              .margin({ right: 5 })
            Divider()
              .layoutWeight(1)
          }
          .margin({ top: 5 })

          Text($r(`app.string.version_1_0_0_feat`))

          Row() {
            Text($r('app.string.fix'))
              .fontWeight(FontWeight.Bold)
              .fontSize(14)
              .fontColor($r('app.color.bright_blue'))
              .margin({ right: 5 })
            Divider()
              .layoutWeight(1)
          }
          .margin({ top: 5 })

          Text($r(`app.string.version_1_0_0_fix`))
        }
        .alignItems(HorizontalAlign.Start)
        .width('95%')
        .padding(16)
        .borderRadius(20)
        .backgroundColor($r('app.color.grid_background'))
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  EggImage() {
    WithTheme({ colorMode: ThemeColorMode.LIGHT }) {
      Row() {
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .height(42)
        .width(42)
        .onClick(() => {
          this.isShowEggImage = false;
          this.iconClickTime = 0;
        })
        Blank();
        SaveButton({ icon: SaveIconStyle.FULL_FILLED })
          .width(42)
          .height(42)
          .iconSize(24)
          .onClick(async (event: ClickEvent, result: SaveButtonOnClickResult, error?) => {
            if (result === SaveButtonOnClickResult.SUCCESS) {
              try {
                let helper = photoAccessHelper.getPhotoAccessHelper(this.context.getHostContext());
                let uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
                let file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
                let imagePackerApi = image.createImagePacker();
                let packOpts: image.PackingOption = { format: 'image/png', quality: 100 };
                imagePackerApi.packToFile(this.imagePixelMap, file.fd, packOpts, (err) => {
                  if (err) {
                    console.error(`Failed to pack the image to file.code ${err.code},message is ${err.message}`);
                  } else {
                    console.info('Succeeded in packing the image to file.');
                    imagePackerApi.release((err) => {
                      if (err) {
                        console.error(`Failed to release the image source instance.code ${err.code},message is ${err.message}`);
                      } else {
                        console.info('Succeeded in releasing the image source instance.');
                        fileIo.close(file.fd);
                      }
                    })
                    this.context.getPromptAction().showToast({ message: $r('app.string.save_image_success') });
                  }
                });
              } catch (error) {
                this.context.getPromptAction().showToast({ message: $r('app.string.save_image_fail') });
              }
            } else {
              this.context.getPromptAction().showToast({ message: $r('app.string.save_image_fail') });
            }
          });
      }
      .linearGradient({
        angle: 45,
        colors: [[0xb1b2cd, 0.0], [0xf9f9fb, 0.75], [0xffffff, 1.0]]
      })
      .width('100%')
      .height('100%')
      .backgroundImage($r('app.media.nic'))
      .backgroundImageSize(ImageSize.Contain)
      .backgroundImagePosition(Alignment.Center)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .alignItems(VerticalAlign.Top)
      .padding({ top: 45, left: 10, right: 10 })
    }
  }

  private async getPixmapFromMedia(resource: Resource) {

    let createPixelMap: image.PixelMap
    try {

      const unit8Array = await this.context.getHostContext()!.resourceManager?.getMediaContent(resource.id)
      const imageSource = image.createImageSource(unit8Array.buffer.slice(0, unit8Array.buffer.byteLength))
      createPixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
      })
      await imageSource.release()
      this.imagePixelMap?.release()

    } catch (error) {

      console.error(`getPixmapFromMedia ERROR: [${error.code}] ${error.message}`)
      return
    }
    return createPixelMap
  }
}
