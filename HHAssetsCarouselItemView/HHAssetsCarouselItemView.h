//
//  HHAttachmentCarouselItemView.h
//  Demo
//
//  Created by Herui on 6/6/2016.
//  Copyright © 2016 hirain. All rights reserved.
//

#import <HHAttachmentSheetView/HHAttachmentSheet.h>
#import <TGMediaAssets/TGMediaAssets.h>

@protocol HHAssetsCarouselItemViewDelegate;
@interface HHAssetsCarouselItemView : HHAttachmentSheetItemView

- (instancetype)initWithCamera:(bool)hasCamera selfPortrait:(bool)selfPortrait forProfilePhoto:(bool)forProfilePhoto assetType:(TGMediaAssetType)assetType;


@property (nonatomic, strong) NSArray *underlyingViews;
@property (nonatomic, weak) id <HHAssetsCarouselItemViewDelegate> delegate;

@property (nonatomic, readonly) TGMediaSelectionContext *selectionContext;

@property (nonatomic, copy) void (^sendPressed)(TGMediaAsset *currentItem);





@end

@protocol HHAssetsCarouselItemViewDelegate <NSObject>

- (void)HHAttachmentCarouselItemViewWillUpdateContent:(HHAssetsCarouselItemView *)itemView;

@end
