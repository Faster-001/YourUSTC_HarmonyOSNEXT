# 图片预览组件快速入门

## 目录

- [简介](#简介)
- [约束与限制](#约束与限制)
- [快速入门](#快速入门)
- [API参考](#API参考)
- [示例代码](#示例代码)

## 简介

本组件提供了图片预览的功能，包括滑动预览、双指放大缩小图片。

## 约束与限制

### 环境

- DevEco Studio版本：DevEco Studio 5.0.3 Release及以上
- HarmonyOS SDK版本：HarmonyOS 5.0.3 Release SDK及以上
- 设备类型：华为手机（包括双折叠和阔折叠）
- 系统版本：HarmonyOS 5.0.1(13)及以上

### 权限

- 网络权限：ohos.permission.INTERNET

## 快速入门

1. 安装组件。

   如果是在DevEvo Studio使用插件集成组件，则无需安装组件，请忽略此步骤。

   如果是从生态市场下载组件，请参考以下步骤安装组件。

   a. 解压下载的组件包，将包中所有文件夹拷贝至您工程根目录的XXX目录下。

   b. 在项目根目录build-profile.json5添加module_imagepreview模块。

   ```
   // 项目根目录下build-profile.json5填写module_imagepreview路径。其中XXX为组件存放的目录名
   "modules": [
     {
       "name": "module_imagepreview",
       "srcPath": "./XXX/module_imagepreview"
     }
   ]
   ```

   c. 在项目根目录oh-package.json5添加依赖。

   ```
   // XXX为组件存放的目录名称
   "dependencies": {
     "module_imagepreview": "file:./XXX/module_imagepreview"
   }
   ```
2. 引入组件。

   ```
   import { ImagePreview } from 'module_imagepreview';
   ```

## API参考

### 子组件

无

### 接口

ImagePreview(option: [ImagePreviewOption](#ImagePreviewOption对象说明))

图片预览组件的参数。

**参数：**

| 参数名     | 类型                                            | 是否必填 | 说明       |
|---------|-----------------------------------------------|------|----------|
| options | [ImagePreviewOption](#ImagePreviewOption对象说明) | 否    | 图片预览的参数。 |

### ImagePreviewOption对象说明

| 名称                  | 类型                                                                                                            | 是否必填 | 说明                          |
|---------------------|---------------------------------------------------------------------------------------------------------------|------|-----------------------------|
| isBasicMode         | boolean                                                                                                       | 否    | 是否简单模式，不展示评论、点赞、分享、关注等功能    |
| maskColor           | [ResourceStr](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcestr) | 否    | 遮罩背景色                       |
| startIndex          | number                                                                                                        | 否    | 指定初始显示的图片索引                 |
| swipeDuration       | number                                                                                                        | 否    | 动画时长                        |
| showIndex           | boolean                                                                                                       | 否    | 是否显示页码                      |
| indexFontColor      | number \| string                                                                                              | 否    | 页码字体颜色                      |
| indexFontSize       | [ResourceStr](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/ts-types-V14#resourcestr) | 否    | 页码字体大小                      |
| loop                | boolean                                                                                                       | 否    | 是否循环                        |
| doubleScale         | boolean                                                                                                       | 否    | 节日、节气展示颜色，默认值Color.Red      |
| closeOnClickOverlay | boolean                                                                                                       | 否    | 是否启用双击缩放手势，禁用后，点击时会立即关闭图片预览 |
| closeOnClickImage   | boolean                                                                                                       | 否    | 是否在点击遮罩层后关闭图片预览             |
| maxScale            | number                                                                                                        | 否    | 最大缩放比例                      |
| minScale            | number                                                                                                        | 否    | 最小缩放比例                      |
| authorBuilder       | () => void = () => { }                                                                                        | 否    | 顶部操作栏                       |
| operationBuilder    | () => void = () => { }                                                                                        | 否    | 底部操作栏                       |
| onCloseExpand       | () => void = () => { }                                                                                        | 否    | 关闭操作栏                       |

### 事件

支持以下事件：

#### onImgClick

onImgClick?: (index: number) => void
图片点击事件

#### onImgLongPress

onImgLongPress?: (index: number) => void
图片长按事件

## 示例代码

```ts
import { ImagePreview } from 'module_imagepreview'

@Entry
@ComponentV2
export struct Index {
  @Local imageList: string[] = [
    'https://agc-storage-drcn.platform.dbankcloud.cn/v0/news-hnp2d/news_tra_2.jpg',
    'https://agc-storage-drcn.platform.dbankcloud.cn/v0/news-hnp2d/news_tra_8.jpg',
    'https://agc-storage-drcn.platform.dbankcloud.cn/v0/news-hnp2d/news_tra_3.jpg'
  ]

  build() {
    Button('打开图片预览').onClick(() => {
      ImagePreview.show(this.imageList, {
        startIndex: 1,
      })
    })
  }
}
```