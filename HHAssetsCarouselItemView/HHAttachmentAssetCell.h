//
//  HHAttachmentAssetCell.h
//  Demo
//
//  Created by Herui on 6/6/2016.
//  Copyright © 2016 hirain. All rights reserved.
//

#import "HHAttachmentMenuCell.h"
#import <TGMediaAssets/TGMediaAssets.h>

@interface HHAttachmentAssetCell : HHAttachmentMenuCell

@property (nonatomic, readonly) UIImageView *imageView;
- (void)setHidden:(bool)hidden animated:(bool)animated;

@property (nonatomic, readonly) TGMediaAsset *asset;
- (void)setAsset:(TGMediaAsset *)asset signal:(SSignal *)signal;
- (void)setSignal:(SSignal *)signal;

@property (nonatomic, assign) bool isZoomed;

@property (nonatomic, strong) TGMediaSelectionContext *selectionContext;
//@property (nonatomic, strong) TGMediaEditingContext *editingContext;

@end
