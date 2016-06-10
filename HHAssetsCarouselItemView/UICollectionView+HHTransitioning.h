#import <UIKit/UIKit.h>
#import <SSignalKit/SSignalKit.h>

@protocol HHTransitionAnimatorLayout <NSObject>

- (void)collectionViewAlmostCompleteTransitioning:(UICollectionView *)collectionView;
- (void)collectionViewDidCompleteTransitioning:(UICollectionView *)collectionView completed:(bool)completed finish:(bool)finish;

@end

@interface UICollectionView (HHTransitioning)

@property (nonatomic, readonly) BOOL isTransitionInProgress;

- (UICollectionViewTransitionLayout *)transitionToCollectionViewLayout:(UICollectionViewLayout *)layout duration:(NSTimeInterval)duration completion:(UICollectionViewLayoutInteractiveTransitionCompletion)completion;
- (CGPoint)toContentOffsetForLayout:(UICollectionViewTransitionLayout *)layout indexPath:(NSIndexPath *)indexPath toSize:(CGSize)toSize toContentInset:(UIEdgeInsets)toContentInset;

- (SSignal *)noOngoingTransitionSignal;

@end
