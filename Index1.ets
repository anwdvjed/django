import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import modelPredict from './model';
import { resourceManager } from '@kit.LocalizationKit'
let uris: Array<string> = [];
let modelName: string = 'residnnal.ms';
let max: number = 0;
let maxIndex: number = 0;
let maxArray: Array<number> = [];
let maxIndexArray: Array<number> = [];

// 创建图片文件选择实例
let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
let photo_select =() =>{
// 设置选择媒体文件类型为IMAGE，设置选择媒体文件的最大数目
photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
photoSelectOptions.maxSelectNumber = 1;

// 创建图库选择器实例，调用select()接口拉起图库界面进行文件选择。文件选择成功后，返回photoSelectResult结果集。
let photoPicker = new photoAccessHelper.PhotoViewPicker();
photoPicker.select(photoSelectOptions, async (
  err: BusinessError, photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
  if (err) {
    console.error('MS_LITE_ERR: PhotoViewPicker.select failed with err: ' + JSON.stringify(err));
    return;
  }
  console.info('MS_LITE_LOG: PhotoViewPicker.select successfully, ' +
    'photoSelectResult uri: ' + JSON.stringify(photoSelectResult));
  uris = photoSelectResult.photoUris;
  console.info('MS_LITE_LOG: uri: ' + uris);
})
}

let modelInputHeight: number = 256;
let modelInputWidth: number = 256;

// 使用fileIo.openSync接口，通过uri打开这个文件得到fd
let file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_ONLY);
console.info('MS_LITE_LOG: file fd: ' + file.fd);

// 通过fd使用fileIo.readSync接口读取这个文件内的数据
let inputBuffer = new ArrayBuffer(4096000);
let readLen = fileIo.readSync(file.fd, inputBuffer);
console.info('MS_LITE_LOG: readSync data to file succeed and inputBuffer size is:' + readLen);

// 通过PixelMap预处理
let imageSource = image.createImageSource(file.fd);
imageSource.createPixelMap().then((pixelMap) => {
  pixelMap.getImageInfo().then((info) => {
    console.info('MS_LITE_LOG: info.width = ' + info.size.width);
    console.info('MS_LITE_LOG: info.height = ' + info.size.height);
    // 根据模型输入的尺寸，将图片裁剪为对应的size，获取图片buffer数据readBuffer
    pixelMap.scale(256.0 / info.size.width, 256.0 / info.size.height).then(() => {
      pixelMap.crop(
        { x: 16, y: 16, size: { height: modelInputHeight, width: modelInputWidth } }
      ).then(async () => {
        let info = await pixelMap.getImageInfo();
        console.info('MS_LITE_LOG: crop info.width = ' + info.size.width);
        console.info('MS_LITE_LOG: crop info.height = ' + info.size.height);
        // 需要创建的像素buffer大小
        let readBuffer = new ArrayBuffer(modelInputHeight * modelInputWidth * 4);
        await pixelMap.readPixelsToBuffer(readBuffer);
        console.info('MS_LITE_LOG: Succeeded in reading image pixel data, buffer: ' +
        readBuffer.byteLength);
        // 处理readBuffer，转换成float32格式，并进行标准化处理
        const imageArr = new Uint8Array(
          readBuffer.slice(0, modelInputHeight * modelInputWidth * 4));
        console.info('MS_LITE_LOG: imageArr length: ' + imageArr.length);
        let means = [0.485, 0.456, 0.406];
        let stds = [0.229, 0.224, 0.225];
        let float32View = new Float32Array(modelInputHeight * modelInputWidth * 3);
        let index = 0;
        for (let i = 0; i < imageArr.length; i++) {
          if ((i + 1) % 4 == 0) {
            float32View[index] = (imageArr[i - 3] / 255.0 - means[0]) / stds[0]; // B
            float32View[index+1] = (imageArr[i - 2] / 255.0 - means[1]) / stds[1]; // G
            float32View[index+2] = (imageArr[i - 1] / 255.0 - means[2]) / stds[2]; // R
            index += 3;
          }
        }
        console.info('MS_LITE_LOG: float32View length: ' + float32View.length);
        let printStr = 'float32View data:';
        for (let i = 0; i < 20; i++) {
          printStr += ' ' + float32View[i];
        }
        console.info('MS_LITE_LOG: float32View data: ' + printStr);
      })
    })
  });
});
// 完成图像输入和预处理后的buffer数据保存在float32View，具体可见上文图像输入和预处理中float32View的定义和处理。
let inputs: ArrayBuffer[] = [float32View.buffer];
let resMgr: resourceManager.ResourceManager = getContext().getApplicationContext().resourceManager;
resMgr.getRawFileContent(modelName).then(modelBuffer => {
  // predict
  modelPredict(modelBuffer.buffer.slice(0), inputs).then(outputs => {
    console.info('=========MS_LITE_LOG: MS_LITE predict success=====');
    // 结果打印
    for (let i = 0; i < outputs.length; i++) {
      let out = new Float32Array(outputs[i].getData());
      let printStr = outputs[i].name + ':';
      for (let j = 0; j < out.length; j++) {
        printStr += out[j].toString() + ',';
      }
      console.info('MS_LITE_LOG: ' + printStr);
      // 取分类占比的最大值
      max = 0;
      maxIndex = 0;
      maxArray = [];
      maxIndexArray = [];
      let newArray = out.filter(value => value !== max)
      for (let n = 0; n < 5; n++) {
        max = out[0];
        maxIndex = 0;
        for (let m = 0; m < newArray.length; m++) {
          if (newArray[m] > max) {
            max = newArray[m];
            maxIndex = m;
          }
        }
        maxArray.push(Math.round(max * 10000))
        maxIndexArray.push(maxIndex)
        // filter函数，数组过滤函数
        newArray = newArray.filter(value => value !== max)
      }
      console.info('MS_LITE_LOG: max:' + maxArray);
      console.info('MS_LITE_LOG: maxIndex:' + maxIndexArray);
    }
    console.info('=========MS_LITE_LOG END=========');
  })
})

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State flag: boolean = true;
  @State uris: Array<string> = [];
  build() {
    RelativeContainer() {
      Column() {
        Text('伪造检测系统')
          .fontColor(Color.Red)
        Text('                              ')
        Button('图像检测')
          .fontColor(Color.Black)
          .onClick(()=>{
            if(this.flag){
              photo_select()
            }
          })
      }

    }
  }
}