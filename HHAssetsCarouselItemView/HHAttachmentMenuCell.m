//
//  HHAttachmentMenuCell.m
//  Demo
//
//  Created by Herui on 6/6/2016.
//  Copyright © 2016 hirain. All rights reserved.
//

#import "HHAttachmentMenuCell.h"

const CGFloat HHAttachmentMenuCellCornerRadius = 5.5f;


@implementation HHAttachmentMenuCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.clipsToBounds = true;
       
        self.backgroundColor = [UIColor whiteColor];
        
        static dispatch_once_t onceToken;
        static UIImage *cornersImage;
        dispatch_once(&onceToken, ^ {
            CGRect rect = CGRectMake(0, 0, HHAttachmentMenuCellCornerRadius * 2 + 1.0f, HHAttachmentMenuCellCornerRadius * 2 + 1.0f);
            
            UIGraphicsBeginImageContextWithOptions(rect.size, false, 0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextFillRect(context, rect);
            
            CGContextSetBlendMode(context, kCGBlendModeClear);
            
            CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
            CGContextFillEllipseInRect(context, rect);
            
            cornersImage = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(HHAttachmentMenuCellCornerRadius, HHAttachmentMenuCellCornerRadius, HHAttachmentMenuCellCornerRadius, HHAttachmentMenuCellCornerRadius)];
            
            UIGraphicsEndImageContext();
        });
        
        _cornersView = [[UIImageView alloc] initWithImage:cornersImage];
        _cornersView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _cornersView.frame = self.bounds;
        [self addSubview:_cornersView];
    }
    
    return self;
}

@end
