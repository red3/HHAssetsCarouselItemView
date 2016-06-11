## HHAssetsCarouselItemView


[![Version](https://img.shields.io/cocoapods/v/HHAssetsCarouselItemView.svg?style=flat)](http://cocoapods.org/pods/HHAssetsCarouselItemView)
[![License](https://img.shields.io/cocoapods/l/HHAssetsCarouselItemView.svg?style=flat)](http://cocoapods.org/pods/HHAssetsCarouselItemView)
[![Platform](https://img.shields.io/cocoapods/p/HHAssetsCarouselItemView.svg?style=flat)](http://cocoapods.org/pods/HHAssetsCarouselItemView)

HHAssetsCarouselItemView depends on this repo: [HHAttachmentSheetView](https://github.com/red3/HHAttachmentSheetView), click this link to see more detail about how to use `HHAttachmentSheetView ` in your own project.

**HHAssetsCarouselItemView** enables you to pick a assets in your Photo Library like Messages app.


![image](https://raw.githubusercontent.com/red3/HHAssetsCarouselItemView/master/preview01.gif)

For more details: [blog.coderhr.com](http://blog.coderhr.com)

## Feature

*  Pick a assets in your Photo Library like Messages app.

## Requirements

* Xcode7 or higher
* iOS 6.0 or higher
* ARC
* Objective-C

## Installation

### CocoaPods

```ruby
pod "HHAssetsCarouselItemView"
``` 


## Demo

Open and run the `HHAssetsCarouselItemViewDemo.xcworkspace` in Xcode to see HHAssetsCarouselItemView in action

## Example usage 
```Objective-C

    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:5];
    
    HHAssetsCarouselItemView *assetsItem = [[HHAssetsCarouselItemView alloc] initWithCamera:NO selfPortrait:NO forProfilePhoto:NO assetType:TGMediaAssetPhotoType];
    assetsItem.delegate = self;
   
    [items addObject:assetsItem];
    [items addObject:[[HHAttachmentSheetButtonItemView alloc] initWithTitle:@"Choose Photo" pressed:^ {
        NSLog(@"choose photo");
        
    }]];
    [items addObject:[[HHAttachmentSheetButtonItemView alloc] initWithTitle:@"Take Photo" pressed:^ {
        NSLog(@"choose viedo");
        
    }]];
    [items addObject:[[HHAttachmentSheetButtonItemView alloc] initWithTitle:@"Search Photo" pressed:^ {
        NSLog(@"search photo");
        
    }]];
   
    HHAttachmentSheetButtonItemView *cancelItem = [[HHAttachmentSheetButtonItemView alloc] initWithTitle:@"Cancel" pressed:nil];
    cancelItem.bold = YES;
    [items addObject:cancelItem];
    
    _sheetView = [[HHAttachmentSheetView alloc] initWithItems:items];
    [_sheetView showWithAnimate:YES completion:nil];

    __weak ViewController *weakSelf = self;
    __weak HHAttachmentSheetView *weakSheetView = _sheetView;
    __weak HHAssetsCarouselItemView *weakItemView = assetsItem;
    assetsItem.sendPressed = ^ (TGMediaAsset *assets) {
        __strong HHAttachmentSheetView *strongSheetView = weakSheetView;
        __strong HHAssetsCarouselItemView *strongItemView = weakItemView;
        [strongSheetView hideWithAnimate:YES completion:nil];
        TGMediaAsset *asset = [strongItemView.selectionContext.selectedItems firstObject];
        [[TGMediaAssetImageSignals imageForAsset:asset imageType:TGMediaAssetImageTypeLargeThumbnail size:CGSizeMake(200, 200)] startWithNext:^(UIImage *image) {
            if ([image isKindOfClass:[UIImage class]]) {
                weakSelf.imageView.image = image;
            }
        } completed:nil];
    };
	
    
```


## TODO

* Add more assets type like gif and video.
* Add CameraPreivew.
* Add Carthage support.



## Update Logs


### 2015.06.11 

* First commit, support for CocoaPods.



## Support

* If you have any questions, please [Issues](https://github.com/red3/HHAssetsCarouselItemView/issues/new)  me, thank you. :) 
* Blog: [hirain](http://blog.coderhr.com)
* Buy me a cup of coffee? 👇

<p align="left" >
<img src="http://photo-coder.b0.upaiyun.com/img/alipay.png" width="276" height="360"/>
</p>



## License
`HHAttachmentSheetView ` is available under the MIT license. See the [LICENSE](http://opensource.org/licenses/MIT) file for more info.

