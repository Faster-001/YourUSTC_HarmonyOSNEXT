import { LinkSet, MultiLink, LINK } from '../constants/Links';
import { hostContext } from '../constants/BasicConstants';
import * as FunctionOrder from '../utils/FunctionOrder';
import BackgroundImage from '../utils/BgImageManager';
import { resetWebName } from './MultiPageMenu';
import { linkPickerDialog, pushRedirect } from '../utils/PageRouter';
import { WantAbility } from '../utils/WantAbility';
import { common } from '@kit.AbilityKit';

/**
 * 搜索结果: 指向 LINK 中的一个具体功能项
 */
export interface SearchResultItem {
  gridIndex: number;
  index: number;
  link: MultiLink;
}

/**
 * 搜索: 将资源型标题解析为实际文本
 */
export function resolveTitle(title: ResourceStr): string {
  if (typeof title === 'string') {
    return title;
  }
  try {
    return hostContext().resourceManager.getStringSync(title.id);
  } catch (err) {
    console.error(`ResolveTitle ERROR: ${JSON.stringify(err)}`);
    return '';
  }
}

/**
 * 搜索: 判断功能项是否命中关键字（名称/拼音/链接/别名，均不区分大小写；
 * 子链接的 subtitle 与 url 一并纳入名称/链接匹配）
 */
export function matchSearch(item: MultiLink, keyword: string): boolean {
  if (resolveTitle(item.title).toLowerCase().includes(keyword)) {
    return true;
  }
  if (item.pinyin !== undefined && item.pinyin.some(p => p.toLowerCase().includes(keyword))) {
    return true;
  }
  if (item.alias !== undefined && item.alias.some(alias => alias.toLowerCase().includes(keyword))) {
    return true;
  }
  for (const addr of item.url) {
    if (addr.subtitle !== undefined && addr.subtitle.toLowerCase().includes(keyword)) {
      return true;
    }
    if (typeof addr.url === 'string' && addr.url.toLowerCase().includes(keyword)) {
      return true;
    }
  }
  return false;
}

/**
 * 搜索: 遍历 LINK 全表，返回命中的功能项（记录其在 LINK 中的位置以便跳转）
 */
export function doSearch(query: string): SearchResultItem[] {
  const results: SearchResultItem[] = [];
  const keyword = query.trim().toLowerCase();
  if (keyword === '') {
    return results;
  }
  LINK.forEach((linkSet: LinkSet, gridIndex: number) => {
    linkSet.set.forEach((item: MultiLink, index: number) => {
      if (matchSearch(item, keyword)) {
        results.push({ gridIndex: gridIndex, index: index, link: item });
      }
    });
  });
  return results;
}

/**
 * 组件: 搜索结果列表
 */
@Component
export struct SearchResultComponent {
  @Prop searchResults: SearchResultItem[];
  @Link copyMostUsedFunc: MultiLink[];
  pageInfo: NavPathStack = new NavPathStack();
  searchResultDialog: CustomDialogController | undefined = undefined;

  /**
   * 搜索: 打开选中的功能项（记录点击次数，与功能页 Grid 行为保持一致）
   */
  openSearchResult(result: SearchResultItem): void {
    const item = result.link;
    if (item.url.length === 0) {
      return;
    }
    resetWebName(item.title);
    FunctionOrder.recordClick(result.gridIndex, result.index);
    FunctionOrder.refreshFunc();
    this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;

    if (item.url.length === 1) {
      pushRedirect(this.pageInfo, item.url[0], item.title);
    } else {
      this.searchResultDialog = new CustomDialogController({
        builder: linkPickerDialog({
          gridIndex: result.gridIndex,
          index: result.index,
          pageInfo: this.pageInfo
        }),
        autoCancel: true,
        gridCount: 3
      });
      this.searchResultDialog.open();
    }
  }

  build() {
    Column() {
      if (this.searchResults.length === 0) {
        Image($r('app.media.dizzy'))
          .width(150)
          .height(150)
          .autoResize(true)
          .margin({ top: 15 })
        Text() {
          Span($r('app.string.no_search_result'))
          Span('\n向我们反馈新链接')
            .fontColor($r('app.color.active_text'))
            .onClick(() => WantAbility.StartQQ(this.getUIContext().getHostContext() as common.UIAbilityContext))
        }
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ bottom: 24 })
      }
      ForEach(this.searchResults, (result: SearchResultItem, index: number) => {
        Column() {
          Row({ space: 12 }) {
            Image(result.link.icon)
              .width(40)
              .height(40)
              .objectFit(ImageFit.Contain)
              .draggable(false)
            Column({ space: 2 }) {
              Text(result.link.title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.normal_text'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(LINK[result.gridIndex].title)
                .fontSize(12)
                .fontColor($r('app.color.transparent_text'))
                .maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 })
          .onClick(() => {
            this.openSearchResult(result);
          })

          if (index < this.searchResults.length - 1) {
            Divider()
              .width('90%')
          }
        }
      }, (result: SearchResultItem) => result.gridIndex + '.' + result.index)
    }
    .width('100%')
    .borderRadius(20)
    .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#0000')
    .backgroundBlurStyle(BackgroundImage.blurLevel)
  }
}
