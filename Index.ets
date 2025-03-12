
@Entry
@Component
struct Index {
  build() {
    Column() {

      Row(){
        Text('面具刺客—伪造检测')
          .width('100%')
          .height(60)
          .fontWeight(FontWeight.Medium)
          .fontSize(25)
          .fontWeight(FontWeight.Medium)
          .margin({bottom:50 })
          .backgroundColor('#ff61b6e3')
          .alignSelf(ItemAlign.Start)  // 置左
      }

      Column(){
        Row(){
          Column()
          {
            Button('+')
              .width(70)
              .height(70)
              .fontSize(30)
              .margin({bottom:20})
            Text('点击添加图片')
              .fontSize(20)
              .fontColor(Color.White)
          }
        }
        .alignItems(VerticalAlign.Center)  // 垂直居中
        .justifyContent(FlexAlign.Center)  // 水平居中
        .backgroundColor(Color.Gray)
        .width('100%')
        .height(400)
        .borderRadius(10)
        .margin({top:15})
      }
      .padding({ left:30, right:30 ,bottom:10})
      .height('100%')
      .width('100%')
      }

  }
}