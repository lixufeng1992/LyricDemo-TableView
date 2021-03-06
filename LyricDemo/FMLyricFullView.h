//
//  FMLyricFullView.h
//  LyricDemo
//
//  Created by lixufeng on 16/9/13.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMLyricViewConst.h"
#import "FMLyricLabel.h"
#import "FMLyricModelConst.h"


@class FMLyricFullView;

@protocol FMLyricViewDelegate <NSObject>

@optional

- (void)lyricView:(FMLyricFullView*)lyricView didEndDraggingToProgress:(CGFloat)progressTime;

- (void)lyricViewDidDragging:(FMLyricFullView*)lyricView;

- (void)lyricViewWillBeginDragging:(FMLyricFullView*)lyricView;

@end


@interface FMLyricFullView : UIView


@property(nonatomic, weak) id<FMLyricViewDelegate> delegate;


- (id)initWithFrame:(CGRect)frame;

- (void)loadLyricAtPath:(NSString *)lyricPath translateLyricAtPath:(NSString *)translateLyricPath;

- (void)loadLyricAtPath:(NSString *)lyricPath translateLyricAtPath:(NSString *)translateLyricPath lyricFileType:(FMLyricFileType)lyricFileType;

- (void)loadLyricContent:(NSString *)lyricContent translateLyricContent:(NSString *)translateLyric;

- (void)loadLyricContent:(NSString *)lyricContent translateLyricContent:(NSString *)translateLyric lyricFileType:(FMLyricFileType)lyricFileType;

- (void)setLyricIdxToShow:(NSUInteger)idx;

- (void)setHighlightedWordsColor:(UIColor *)highlightedWordsColor
             normalSentenceColor:(UIColor *)normalSentenceColor;

- (void)setCurSentenceFont:(UIFont *)curSentenceFont
        normalSentenceFont:(UIFont *)normalSentenceFont;

- (void)setTextAlignment:(FMTextAlignment)textAlignment;

- (void)setShouldHilightenedByWord:(BOOL)shouldHightenedByWord;

- (void)setDragable:(BOOL)dragable;

- (void)setSpaceBetweenSentence:(CGFloat)spaceBetweenSentence;

- (void)setDragFinishDelay:(NSTimeInterval)delay;

//progessTime:以秒为单位： 198.897000秒
- (void)repaintWithProgressTime:(double)progressTime;

- (void)resumeAnimation;

- (void)pauseAnimation;

@end
