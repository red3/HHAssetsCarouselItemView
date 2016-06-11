//
//  ViewController.m
//  Demo
//
//  Created by Herui on 6/6/2016.
//  Copyright © 2016 hirain. All rights reserved.
//

#import "ViewController.h"
#import <HHAttachmentSheetView/HHAttachmentSheetView.h>
#import "HHAssetsCarouselItemView.h"

@interface ViewController () <HHAssetsCarouselItemViewDelegate>

@property (nonatomic, strong) HHAttachmentSheetView *sheetView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)buttonDidClicked:(UIButton *)sender {
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
   
    
    HHAttachmentSheetButtonItemView *cancelItem = [[HHAttachmentSheetButtonItemView alloc] initWithTitle:@"Cancel" pressed:^{
            NSLog(@"cancel");
    }];
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
        } completed:^{
            //
        }];
       

        
        
    };
    
}

#pragma mark - Delegate
- (void)HHAttachmentCarouselItemViewWillUpdateContent:(HHAssetsCarouselItemView *)itemView {
    
    for (int i=1; i<_sheetView.items.count-1; i++) {
        HHAttachmentSheetItemView *item = _sheetView.items[i];
        item.hidden = !item.isHidden;
        item.alpha = 0;
    }
    [_sheetView reloadItemsWithAnimate:YES updates:^ {
        
        for (int i=1; i<_sheetView.items.count-1; i++) {
            HHAttachmentSheetItemView *item = _sheetView.items[i];
            item.alpha = 1;
        }
        
    } completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
