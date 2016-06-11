//
//  HHAttachmentCarouselItemView.m
//  Demo
//
//  Created by Herui on 6/6/2016.
//  Copyright © 2016 hirain. All rights reserved.
//

#import "HHAssetsCarouselItemView.h"
#import "UICollectionView+HHTransitioning.h"
#import "HHTransitionLayout.h"
#import "HHAttachmentPhotoCell.h"
#import "HHAttachmentAssetCell.h"
#import "HHMediaAssetsUtils.h"

const NSInteger HHAttachmentCameraCellIndex = -1;
const CGSize HHAttachmentCellSize = { 84.0f, 84.0f };
const CGFloat HHAttachmentEdgeInset = 8.0f;

const CGFloat HHAttachmentCarouselHeight = 214.0f;
const CGFloat HHAttachmentCarouselCondensedHeight = 157.0f;

const CGFloat HHAttachmentCarouselCorrection = -114.0f;
const CGFloat HHAttachmentCarouselCondensedCorrection = -57.0f;

const CGFloat HHAttachmentZoomedPhotoHeight = 198.0f;
const CGFloat HHAttachmentZoomedPhotoMaxWidth = 250.0f;

const CGFloat HHAttachmentZoomedPhotoCondensedHeight = 141.0f;
const CGFloat HHAttachmentZoomedPhotoCondensedMaxWidth = 178.0f;

const CGFloat HHAttachmentZoomedPhotoAspectRatio = 1.2626f;

const NSUInteger HHAttachmentDisplayedAssetLimit = 500;

@interface HHAssetsCarouselItemView () <
UICollectionViewDelegate, UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout>
{
    TGMediaAssetsLibrary *_assetsLibrary;
    SMetaDisposable *_assetsDisposable;
    TGMediaAssetFetchResult *_fetchResult;
    
    BOOL _forProfilePhoto;
    
    BOOL _zoomedIn;
    BOOL _zoomingIn;
    CGFloat _zoomingProgress;
    
    SMetaDisposable *_selectionChangedDisposable;
    SMetaDisposable *_itemsSizeChangedDisposable;
    
    UICollectionViewFlowLayout *_smallLayout;
    UICollectionViewFlowLayout *_largeLayout;
    UICollectionView *_collectionView;
    HHMediaAssetsPreheatMixin *_preheatMixin;

    
    UIView *_cameraView;
    
    HHAttachmentSheetButtonItemView *_sendMediaItemView;
    HHAttachmentSheetButtonItemView *_sendFileItemView;
    
    
    NSInteger _pivotInItemIndex;
    NSInteger _pivotOutItemIndex;
    
    CGSize _imageSize;
    
    CGSize _maxPhotoSize;
    CGFloat _carouselHeight;
    
    CGFloat _smallActivationHeight;
    CGSize _smallMaxPhotoSize;
    CGFloat _smallCarouselHeight;
    BOOL _smallActivated;
    BOOL _condensed;
    
    CGFloat _carouselCorrection;
    
}

@end

@implementation HHAssetsCarouselItemView

- (instancetype)initWithCamera:(bool)hasCamera selfPortrait:(bool)selfPortrait forProfilePhoto:(bool)forProfilePhoto assetType:(TGMediaAssetType)assetType {
    
    self = [super initWithFrame:CGRectZero];
    if (!self) {
        return nil;
    }
    __weak HHAssetsCarouselItemView *weakSelf = self;
    
    _forProfilePhoto = forProfilePhoto;
    
    _assetsLibrary = [TGMediaAssetsLibrary libraryForAssetType:assetType];
    _assetsDisposable = [[SMetaDisposable alloc] init];
    
    if (!forProfilePhoto) {
        _selectionContext = [[TGMediaSelectionContext alloc] init];
        [_selectionContext setItemSourceUpdatedSignal:[_assetsLibrary libraryChanged]];
        _selectionContext.updatedItemsSignal = ^SSignal *(NSArray *items)
        {
            __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return nil;
            
            return [strongSelf->_assetsLibrary updatedAssetsForAssets:items];
        };
        
        _selectionChangedDisposable = [[SMetaDisposable alloc] init];
        [_selectionChangedDisposable setDisposable:[[[_selectionContext selectionChangedSignal] mapToSignal:^SSignal *(id value)
                                                     {
                                                         __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
                                                         if (strongSelf == nil)
                                                             return [SSignal complete];
                                                         
                                                         return [[strongSelf->_collectionView noOngoingTransitionSignal] then:[SSignal single:value]];
                                                     }] startWithNext:^(__unused TGMediaSelectionChange *change)
                                                    {
                                                        __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
                                                        if (strongSelf == nil)
                                                            return;
                                                        
                                                        NSInteger index = [strongSelf->_fetchResult indexOfAsset:(TGMediaAsset *)change.item];
                                                        [strongSelf updateSendButtonsFromIndex:index];
                                                    }]];
        
        //_editingContext = [[TGMediaEditingContext alloc] init];
        SPipe  *cropPipe = [[SPipe alloc] init];

        
        _itemsSizeChangedDisposable = [[SMetaDisposable alloc] init];
        [_itemsSizeChangedDisposable setDisposable:[[cropPipe.signalProducer() deliverOn:[SQueue mainQueue]] startWithNext:^(__unused id next)
                                                    {
                                                        __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
                                                        if (strongSelf == nil)
                                                            return;
                                                        
                                                        if (strongSelf->_zoomedIn)
                                                        {
                                                            [strongSelf->_largeLayout invalidateLayout];
                                                            [strongSelf->_collectionView layoutSubviews];
                                                            
                                                        }
                                                    }]];
    }
    
    
    _smallLayout = [[UICollectionViewFlowLayout alloc] init];
    _smallLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _smallLayout.minimumLineSpacing = HHAttachmentEdgeInset;
    
    _largeLayout = [[UICollectionViewFlowLayout alloc] init];
    _largeLayout.scrollDirection = _smallLayout.scrollDirection;
    _largeLayout.minimumLineSpacing = _smallLayout.minimumLineSpacing;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, _smallLayout.minimumLineSpacing, self.bounds.size.width, HHAttachmentZoomedPhotoHeight) collectionViewLayout:_smallLayout];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.showsHorizontalScrollIndicator = false;
    _collectionView.showsVerticalScrollIndicator = false;
    [_collectionView registerClass:[HHAttachmentPhotoCell class] forCellWithReuseIdentifier:HHAttachmentPhotoCellIdentifier];

    [self addSubview:_collectionView];
    
    if (hasCamera) {
       //  _cameraView = [[UIView alloc] initForSelfPortrait:selfPortrait];
        _cameraView = [[UIView alloc] init];
        _cameraView.backgroundColor = [UIColor grayColor];
        _cameraView.frame = CGRectMake(_smallLayout.minimumLineSpacing, 0, HHAttachmentCellSize.width, HHAttachmentCellSize.height);
        // [_cameraView startPreview];
        [_collectionView addSubview:_cameraView];
    }
    
    _sendMediaItemView = [[HHAttachmentSheetButtonItemView alloc] initWithTitle:@"Send Photo" pressed:^{
        __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
        //NSArray *array = [strongSelf.selectionContext.selectedItems copy];
        
        if (strongSelf != nil && strongSelf.sendPressed != nil) {
            strongSelf.sendPressed(nil);
        }
        
    }];
    _sendMediaItemView.bold = YES;
    _sendMediaItemView.hidden = YES;
    //[_sendMediaItemView setHidden:YES animated:NO];

   
    [self addSubview:_sendMediaItemView];
    

    
    [self setSignal:[[TGMediaAssetsLibrary authorizationStatusSignal] mapToSignal:^SSignal *(NSNumber *statusValue)
                     {
                         __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
                         if (strongSelf == nil)
                             return [SSignal complete];
                         
                         TGMediaLibraryAuthorizationStatus status = statusValue.integerValue;
                         if (status == TGMediaLibraryAuthorizationStatusAuthorized)
                         {
                             return [[strongSelf->_assetsLibrary cameraRollGroup] mapToSignal:^SSignal *(TGMediaAssetGroup *cameraRollGroup)
                                     {
                                         return [strongSelf->_assetsLibrary assetsOfAssetGroup:cameraRollGroup reversed:true];
                                     }];
                         }
                         else
                         {
                             return [SSignal fail:nil];
                         }
                     }]];
    
    
    _preheatMixin = [[HHMediaAssetsPreheatMixin alloc] initWithCollectionView:_collectionView scrollDirection:UICollectionViewScrollDirectionHorizontal];
    _preheatMixin.imageType = TGMediaAssetImageTypeThumbnail;
    _preheatMixin.assetCount = ^NSInteger
    {
        __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return 0;
        
        return [strongSelf collectionView:strongSelf->_collectionView numberOfItemsInSection:0];
    };
    _preheatMixin.assetAtIndex = ^TGMediaAsset *(NSInteger index)
    {
        __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return nil;
        
        return [strongSelf->_fetchResult assetAtIndex:index];
    };
    
    [self _updateImageSize];
    _preheatMixin.imageSize = _imageSize;
    
    [self setCondensed:false];
    
    _pivotInItemIndex = NSNotFound;
    _pivotOutItemIndex = NSNotFound;
    return self;
    
}

- (void)setSignal:(SSignal *)signal
{
    __weak HHAssetsCarouselItemView *weakSelf = self;
    [_assetsDisposable setDisposable:[[[signal mapToSignal:^SSignal *(id value)
                                        {
                                            __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
                                            if (strongSelf == nil)
                                                return [SSignal complete];
                                            
                                            return [[strongSelf->_collectionView noOngoingTransitionSignal] then:[SSignal single:value]];
                                        }] deliverOn:[SQueue mainQueue]] startWithNext:^(id next)
                                      {
                                          __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
                                          if (strongSelf == nil)
                                              return;
                                          
                                          if ([next isKindOfClass:[TGMediaAssetFetchResult class]])
                                          {
                                              TGMediaAssetFetchResult *fetchResult = (TGMediaAssetFetchResult *)next;
                                              strongSelf->_fetchResult = fetchResult;
                                              [strongSelf->_collectionView reloadData];
                                          }
                                          else if ([next isKindOfClass:[TGMediaAssetFetchResultChange class]])
                                          {
                                              TGMediaAssetFetchResultChange *change = (TGMediaAssetFetchResultChange *)next;
                                              strongSelf->_fetchResult = change.fetchResultAfterChanges;
                                              [HHMediaAssetsCollectionViewIncrementalUpdater updateCollectionView:strongSelf->_collectionView withChange:change completion:nil];
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^
                                                             {
                                                                 [strongSelf scrollViewDidScroll:strongSelf->_collectionView];
                                                             });
                                          }
//
                                      }]];
}

- (void)updateSendButtonsFromIndex:(NSInteger)index
{
   
    __block NSInteger photosCount = 0;
    __block NSInteger videosCount = 0;
    __block NSInteger gifsCount = 0;
    
    [_selectionContext enumerateSelectedItems:^(id<TGMediaSelectableItem> item)
     {
         TGMediaAsset *asset = (TGMediaAsset *)item;
         if (![asset isKindOfClass:[TGMediaAsset class]])
             return;
         
         switch (asset.type)
         {
             case TGMediaAssetVideoType:
                 videosCount++;
                 break;
                 
             case TGMediaAssetGifType:
                 gifsCount++;
                 break;
                 
             default:
                 photosCount++;
                 break;
         }
     }];
    
    NSInteger totalCount = photosCount + videosCount + gifsCount;
    bool activated = (totalCount > 0);
    if ([self zoomedModeSupported])
        [self setZoomedMode:activated animated:true index:index];
    else
        [self setSelectedMode:activated animated:true];
   
    
    if (totalCount == 0)
        return;
    
    if (photosCount > 0 && videosCount == 0 && gifsCount == 0)
    {
       
    }
    else if (videosCount > 0 && photosCount == 0 && gifsCount == 0)
    {
      
    }
    else if (gifsCount > 0 && photosCount == 0 && videosCount == 0)
    {
       
    }
    else
    {
        
    }
    
    if (totalCount == 1) {
        
    } else {
        
    }
}

- (void)setSelectedMode:(bool)selected animated:(bool)animated
{
    // [self.underlyingViews.firstObject setHidden:selected animated:animated];
    //[_sendMediaItemView setHidden:!selected animated:animated];
    [self.underlyingViews.firstObject setHidden:selected];
    [_sendMediaItemView setHidden:!selected];
}

- (void)setCondensed:(bool)condensed
{
    _condensed = condensed;
    
    CGFloat delta = -423;
    if (condensed) {
        _maxPhotoSize = CGSizeMake(HHAttachmentZoomedPhotoCondensedMaxWidth, HHAttachmentZoomedPhotoCondensedHeight);
        _carouselHeight = HHAttachmentCarouselCondensedHeight;
        _carouselCorrection = HHAttachmentCarouselCondensedCorrection;
        delta += 48;
    } else {
        _maxPhotoSize = CGSizeMake(HHAttachmentZoomedPhotoMaxWidth, HHAttachmentZoomedPhotoHeight);
        _carouselHeight = HHAttachmentCarouselHeight;
        _carouselCorrection = HHAttachmentCarouselCorrection;
    }
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    _smallActivationHeight = screenSize.width;
    
    CGFloat screenDelta = screenSize.width + delta;
    
    _smallCarouselHeight = MAX(111, _carouselHeight + screenDelta);
    CGFloat smallHeight = MAX(95, _maxPhotoSize.height + screenDelta);
    _smallMaxPhotoSize = CGSizeMake(ceil(smallHeight * HHAttachmentZoomedPhotoAspectRatio), smallHeight);
    
    CGRect frame = _collectionView.frame;
    frame.size.height = _maxPhotoSize.height;
    _collectionView.frame = frame;
}


- (void)setZoomedMode:(bool)zoomed animated:(bool)animated index:(NSInteger)index
{
    if (zoomed == _zoomedIn) {
        if (_zoomedIn) {
            [self centerOnItemWithIndex:index animated:animated];
        }
        
        return;
    }
    
    _zoomedIn = zoomed;
    _zoomingIn = true;
    _collectionView.userInteractionEnabled = false;
    
    
    if ([self.delegate respondsToSelector:@selector(HHAttachmentCarouselItemViewWillUpdateContent:)]) {
        [self.delegate HHAttachmentCarouselItemViewWillUpdateContent:self];
    }
    
    if (zoomed)
        _pivotInItemIndex = index;
    else
        _pivotOutItemIndex = index;
    
    UICollectionViewFlowLayout *toLayout = _zoomedIn ? _largeLayout : _smallLayout;
    
    [self _updateImageSize];
    
    __weak HHAssetsCarouselItemView *weakSelf = self;
    HHTransitionLayout *layout = (HHTransitionLayout *)[_collectionView transitionToCollectionViewLayout:toLayout duration:0.3f completion:^(__unused BOOL completed, __unused BOOL finished)
                                                        {
                                                            __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
                                                            if (strongSelf == nil)
                                                                return;
                                                            
                                                            strongSelf->_zoomingIn = false;
                                                            strongSelf->_collectionView.userInteractionEnabled = true;
                                                            [strongSelf centerOnItemWithIndex:index animated:false];
                                                        }];
    layout.progressChanged = ^(CGFloat progress)
    {
        __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        strongSelf->_zoomingProgress = progress;
        // [strongSelf requestMenuLayoutUpdate];
        [strongSelf _layoutButtonItemViews];
        [strongSelf setCameraZoomedIn:strongSelf->_zoomedIn progress:progress];
    };
    layout.transitionAlmostFinished = ^
    {
        __strong HHAssetsCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        strongSelf->_pivotInItemIndex = NSNotFound;
        strongSelf->_pivotOutItemIndex = NSNotFound;
    };
    
    CGPoint toOffset = [_collectionView toContentOffsetForLayout:layout indexPath:[NSIndexPath indexPathForRow:index inSection:0] toSize:_collectionView.bounds.size toContentInset:[self collectionView:_collectionView layout:toLayout insetForSectionAtIndex:0]];
    layout.toContentOffset = toOffset;
    
    for (HHAttachmentSheetButtonItemView *itemView in self.underlyingViews) {
        itemView.hidden = zoomed;
        // [itemView setHidden:zoomed animated:animated];
    }
    //_sendFileItemView.hidden = !zoomed;
    _sendMediaItemView.hidden = !zoomed;
    //[_sendMediaItemView setHidden:!zoomed animated:YES];
    
//    [_sendMediaItemView setHidden:!zoomed animated:animated];
//    [_sendFileItemView setHidden:!zoomed animated:animated];
    
    [self _updateVisibleItems];
}

- (void)_updateImageSize
{
    _imageSize = [self imageSizeForThumbnail:!_zoomedIn];
}


- (bool)zoomedModeSupported
{
    return [TGMediaAssetsLibrary usesPhotoFramework];
}

- (CGSize)imageSizeForThumbnail:(bool)forThumbnail
{
    CGFloat scale = 2.0;
    if (forThumbnail)
        return CGSizeMake(HHAttachmentCellSize.width * scale, HHAttachmentCellSize.height * scale);
    else
        return CGSizeMake(floor(HHAttachmentZoomedPhotoMaxWidth * scale), floor(HHAttachmentZoomedPhotoMaxWidth * scale));
}

- (void)centerOnItemWithIndex:(NSInteger)index animated:(bool)animated
{
    [_collectionView setContentOffset:[self contentOffsetForItemAtIndex:index] animated:animated];
}

- (CGPoint)contentOffsetForItemAtIndex:(NSInteger)index
{
    CGRect cellFrame = [_collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]].frame;
    
    CGFloat x = cellFrame.origin.x - (_collectionView.frame.size.width - cellFrame.size.width) / 2.0f;
    CGFloat contentOffset = MAX(0.0f, MIN(x, _collectionView.contentSize.width - _collectionView.frame.size.width));
    
    return CGPointMake(contentOffset, 0);
}

- (void)setCameraZoomedIn:(bool)zoomedIn progress:(CGFloat)progress
{
    if (_cameraView == nil)
        return;
    
    CGFloat size = HHAttachmentCellSize.height;
    progress = zoomedIn ? progress : 1.0f - progress;
    _cameraView.frame = CGRectMake(_smallLayout.minimumLineSpacing - (size + _smallLayout.minimumLineSpacing) * progress, 0, HHAttachmentCellSize.width + (size - HHAttachmentCellSize.width) * progress, HHAttachmentCellSize.height + (size - HHAttachmentCellSize.height) * progress);
    //[_cameraView setZoomedProgress:progress];
}

- (void)_updateVisibleItems
{
    for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems)
    {
        TGMediaAsset *asset = [_fetchResult assetAtIndex:indexPath.row];
        HHAttachmentAssetCell *cell = (HHAttachmentAssetCell *)[_collectionView cellForItemAtIndexPath:indexPath];
        if (cell.isZoomed != _zoomedIn)
        {
            cell.isZoomed = _zoomedIn;
            [cell setSignal:[self _signalForItem:asset refresh:true onlyThumbnail:false]];
        }
    }
}

- (SSignal *)_signalForItem:(TGMediaAsset *)asset refresh:(bool)refresh onlyThumbnail:(bool)onlyThumbnail
{
    bool thumbnail = onlyThumbnail || !_zoomedIn;
    CGSize imageSize = onlyThumbnail ? [self imageSizeForThumbnail:true] : _imageSize;
    
    TGMediaAssetImageType screenImageType = refresh ? TGMediaAssetImageTypeLargeThumbnail : TGMediaAssetImageTypeFastLargeThumbnail;
    TGMediaAssetImageType imageType = thumbnail ? TGMediaAssetImageTypeAspectRatioThumbnail : screenImageType;
    
    SSignal *assetSignal = [TGMediaAssetImageSignals imageForAsset:asset imageType:imageType size:imageSize];
    return assetSignal;
//    if (_editingContext == nil)
//        return assetSignal;
//    
//    SSignal *editedSignal =  thumbnail ? [_editingContext thumbnailImageSignalForItem:asset] : [_editingContext fastImageSignalForItem:asset withUpdates:true];
//    return [editedSignal mapToSignal:^SSignal *(id result)
//            {
//                if (result != nil)
//                    return [SSignal single:result];
//                else
//                    return assetSignal;
//            }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = _collectionView.frame;
    frame.size.width = self.frame.size.width;
    frame.size.height = _smallActivated ? _smallMaxPhotoSize.height :  _maxPhotoSize.height;
    if (!CGRectEqualToRect(frame, _collectionView.frame))
    {
        _collectionView.frame = frame;
        
        [_smallLayout invalidateLayout];
        [_largeLayout invalidateLayout];
    }
    
    [self _layoutButtonItemViews];
}

- (void)_layoutButtonItemViews
{
    CGFloat docker;
    if (_zoomedIn) {
        docker = [_sendMediaItemView preferredHeight];
    } else {
        docker = 0;
    }
    _sendMediaItemView.frame = CGRectMake(0, [self preferredHeight] - docker, self.frame.size.width, [_sendMediaItemView preferredHeight]);
    
//    _sendMediaItemView.frame = CGRectMake(0, 214, self.frame.size.width, [_sendMediaItemView preferredHeight]);

    // _sendFileItemView.frame = CGRectMake(0, CGRectGetMaxY(_sendMediaItemView.frame), self.frame.size.width, [_sendFileItemView preferredHeight]);
}



- (CGFloat)preferredHeight {
    CGFloat progress = _zoomingIn ? _zoomingProgress : 1.0f;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    return [self _preferredHeightForZoomedIn:_zoomedIn progress:progress screenHeight:screenHeight];
}

- (CGFloat)_preferredHeightForZoomedIn:(bool)zoomedIn progress:(CGFloat)progress screenHeight:(CGFloat)screenHeight
{
    if (zoomedIn) {
        return 214 + 50;
    } else {
        return 100;
    }
//    progress = zoomedIn ? progress : 1.0f - progress;
//    //progress = zoomedIn ? 1.0f : 1.0f - progress;
//
//    CGFloat carouselHeight = _carouselHeight;
//    if (fabs(screenHeight - _smallActivationHeight) < FLT_EPSILON)
//        carouselHeight = _smallCarouselHeight;
//    
//    return 100.0f + (carouselHeight - 100.0f) * progress;
}

#pragma mark - UICollectionDelegate && UICollectionDataSource
- (NSInteger)collectionView:(UICollectionView *)__unused collectionView numberOfItemsInSection:(NSInteger)__unused section
{
    return MIN(_fetchResult.count, HHAttachmentDisplayedAssetLimit);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    
    TGMediaAsset *asset = [_fetchResult assetAtIndex:index];
    NSString *cellIdentifier = nil;
    switch (asset.type)
    {
//        case TGMediaAssetVideoType:
//            cellIdentifier = HHAttachmentVideoCellIdentifier;
//            break;
//            
//        case TGMediaAssetGifType:
//            if (_forProfilePhoto)
//                cellIdentifier = TGAttachmentPhotoCellIdentifier;
//            else
//                cellIdentifier = TGAttachmentGifCellIdentifier;
//            break;
            
        default:
            cellIdentifier = HHAttachmentPhotoCellIdentifier;
            break;
    }
    
    HHAttachmentAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    NSInteger pivotIndex = NSNotFound;
    NSInteger limit = 0;
    if (_pivotInItemIndex != NSNotFound)
    {
        if (self.frame.size.width <= 320)
            limit = 2;
        else
            limit = 3;
        
        pivotIndex = _pivotInItemIndex;
    }
    else if (_pivotOutItemIndex != NSNotFound)
    {
        pivotIndex = _pivotOutItemIndex;
        
        if (self.frame.size.width <= 320)
            limit = 3;
        else
            limit = 5;
    }
    
    if (!(pivotIndex != NSNotFound && (indexPath.row < pivotIndex - limit || indexPath.row > pivotIndex + limit)))
    {
        cell.selectionContext = _selectionContext;
        // cell.editingContext = _editingContext;
        
        if (![asset isEqual:cell.asset] || cell.isZoomed != _zoomedIn)
        {
            cell.isZoomed = _zoomedIn;
            [cell setAsset:asset signal:[self _signalForItem:asset refresh:[cell.asset isEqual:asset] onlyThumbnail:false]];
        }
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_zoomedIn)
    {
        CGSize maxPhotoSize = _maxPhotoSize;
        if (_smallActivated)
            maxPhotoSize = _smallMaxPhotoSize;
        
        if (_pivotInItemIndex != NSNotFound && (indexPath.row < _pivotInItemIndex - 2 || indexPath.row > _pivotInItemIndex + 2))
            return CGSizeMake(maxPhotoSize.height, maxPhotoSize.height);
        
        TGMediaAsset *asset = [_fetchResult assetAtIndex:indexPath.row];
        if (asset != nil)
        {
            CGSize dimensions = asset.dimensions;
            if (dimensions.width < 1.0f)
                dimensions.width = 1.0f;
            if (dimensions.height < 1.0f)
                dimensions.height = 1.0f;
            
//            id<TGMediaEditAdjustments> adjustments = [_editingContext adjustmentsForItem:asset];
//            if ([adjustments cropAppliedForAvatar:false] || ([adjustments isKindOfClass:[TGVideoEditAdjustments class]] && [(TGVideoEditAdjustments *)adjustments rotationApplied]))
//            {
//                dimensions = adjustments.cropRect.size;
//                
//                bool sideward = TGOrientationIsSideward(adjustments.cropOrientation, NULL);
//                if (sideward)
//                    dimensions = CGSizeMake(dimensions.height, dimensions.width);
//            }
            
            CGFloat width = MIN(maxPhotoSize.width, ceil(dimensions.width * maxPhotoSize.height / dimensions.height));
            return CGSizeMake(width, maxPhotoSize.height);
        }
        
        return CGSizeMake(maxPhotoSize.height, maxPhotoSize.height);
    }
    
    return HHAttachmentCellSize;
}

- (bool)hasCameraInCurrentMode
{
    return (!_zoomedIn && _cameraView != nil);
}

- (CGFloat)_heightCorrectionForZoomedIn:(bool)zoomedIn progress:(CGFloat)progress
{
    progress = zoomedIn ? progress : 1.0f - progress;
    return _carouselCorrection * progress;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout insetForSectionAtIndex:(NSInteger)__unused section
{
    CGFloat edgeInset = _smallLayout.minimumLineSpacing;
    CGFloat leftInset = [self hasCameraInCurrentMode] ? 2 * edgeInset + 84.0f : edgeInset;
    CGFloat additionalInset = _smallActivated ? _maxPhotoSize.height - _smallMaxPhotoSize.height : 0.0f;
    CGFloat bottomInset = _zoomedIn ? 0.0f : -([self _heightCorrectionForZoomedIn:true progress:1.0f] + additionalInset);
    
    return UIEdgeInsetsMake(0, leftInset, bottomInset, edgeInset);
}



- (CGFloat)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)__unused section
{
    return _smallLayout.minimumLineSpacing;
}

- (UICollectionViewTransitionLayout *)collectionView:(UICollectionView *)__unused collectionView transitionLayoutForOldLayout:(UICollectionViewLayout *)fromLayout newLayout:(UICollectionViewLayout *)toLayout
{
    return [[HHTransitionLayout alloc] initWithCurrentLayout:fromLayout nextLayout:toLayout];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)__unused scrollView
{
    if (_zoomingIn)
        return;
    
//    if (!_zoomedIn)
//        [_preheatMixin update];
    
    for (UICollectionViewCell *cell in _collectionView.visibleCells)
    {
        if ([cell isKindOfClass:[HHAttachmentAssetCell class]])
            [(HHAttachmentAssetCell *)cell setNeedsLayout];
    }
}






@end
