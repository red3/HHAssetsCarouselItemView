#import <UIKit/UIKit.h>

@interface UICollectionView (HHUtils)

- (NSArray *)indexPathsForElementsInRect:(CGRect)rect;
- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect direction:(UICollectionViewScrollDirection)direction removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler;

@end
