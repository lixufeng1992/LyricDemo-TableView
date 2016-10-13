//
//  FMLyricLabel.h
//  LyricDemo
//
//  Created by lixufeng on 16/9/23.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FMLyricLabel : UIView

- (void)setText:(NSString*)text;

- (NSString*)text;

- (void)setTextAlignment:(NSTextAlignment)textAlignment;

- (void)setTextColor:(UIColor*)textColor maskColor:(UIColor*)maskColor;

- (void)setFont:(UIFont*)normalFont;

- (void)startAnimationWithTimesAbsoluteArr:(NSArray<NSNumber*>*)timesAbsoluteArr locationPercentArr:(NSArray<NSNumber*>*)locationPercentArr duration:(CGFloat)duration;

- (void)setLineBreakEnable:(BOOL)enable;

- (CGSize)textSizeWithWidthLimit;

- (CGSize)textSizeWithHeightLimit;

- (CGSize)wordSizeWithHeightLimit:(NSString*)word;

- (void)setLyricDispalayWidth:(CGFloat)lyricDispalayWidth;

- (void)sizeToFit;

- (void)removeAnimation;

- (void)pauseAnimation; //动画暂停，不隐藏

- (void)resumeAnimation; //动画断点开始


//暂时弃用
/*
- (void)showAnimation; //动画show

- (void)hideAnimation; //隐藏动画，动画还在走
 */

- (BOOL)isOpenedAnimation;
 

@end
