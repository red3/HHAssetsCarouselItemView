#import <UIKit/UIKit.h>
#import "UICollectionView+HHTransitioning.h"

@interface HHTransitionLayout : UICollectionViewTransitionLayout <HHTransitionAnimatorLayout>

@property (nonatomic) CGPoint toContentOffset;
@property (nonatomic, strong) void(^progressChanged)(CGFloat progress);
@property (nonatomic, strong) void(^transitionAlmostFinished)();

@end
