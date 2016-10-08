//
//  FMLyricSmallView.h
//  LyricDemo
//
//  Created by lixufeng on 16/9/30.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMConst.h"

@interface FMLyricSmallView : UIView

- (id)initWithFrame:(CGRect)frame;

- (void)loadLyricAtPath:(NSString *)lyricPath translateLyricAtPath:(NSString *)translateLyricPath;

- (void)loadLyricAtPath:(NSString *)lyricPath translateLyricAtPath:(NSString *)translateLyricPath lyricFileType:(FMLyricFileType)lyricFileType;

- (void)loadLyricContent:(NSString *)lyricContent translateLyricContent:(NSString *)translateLyric;

- (void)loadLyricContent:(NSString *)lyricContent translateLyricContent:(NSString *)translateLyric lyricFileType:(FMLyricFileType)lyricFileType;

- (void)setLyricDisplayWidth:(CGFloat)width;

- (void)setLyricIdxToShow:(NSUInteger)idx;

- (void)setHighlightedWordColor:(UIColor *)highlightedWordColor
               curSentenceColor:(UIColor *)curSentenceColor
            normalSentenceColor:(UIColor *)normalSentenceColor;

- (void)setTextAlignment:(FMTextAlignment)textAlignment;

- (void)setShouldHilightenedByWord:(BOOL)shouldHightenedByWord;

//progessTime:以秒为单位： 198.897000秒
- (void)repaintWithProgressTime:(double)progressTime;

- (void)clear;

- (void)resumeAnimation;

- (void)pauseAnimation;




@end
