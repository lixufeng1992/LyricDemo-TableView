//
//  FMLyricPanel.m
//  LyricDemo
//
//  Created by lixufeng on 16/9/13.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "FMLyricFullView.h"
#import "FMConst.h"
#import "FMLyricFileModel.h"
#import "FMLyricLabel.h"


@interface FMLyricFullView(){
    NSString* lastUpdateedSentenceBeginTimeKey;
}

@property (nonatomic, strong, readwrite) UIScrollView* lyricScrollView;

@property (nonatomic, strong, readwrite) FMLyricFileModel* lyricFileModel;
@property (nonatomic, assign, readwrite) NSUInteger lyricIdxToShow;    //要展示第几首歌词
@property (nonatomic, strong, readwrite) FMSingleLyricModel* singleLyricModel;

@property (nonatomic, assign, readwrite) CGFloat lyricDispalayWidth;

@property (nonatomic, assign, readwrite) FMTextAlignment textAlignment;

@property (nonatomic, assign, readwrite) CGFloat curSentenceMarginTop;

@property (nonatomic, assign, readwrite) BOOL shouldHightenedByWord;

@property (nonatomic, assign, readwrite) NSUInteger maxDisplayLineAbove;
@property (nonatomic, assign, readwrite) NSUInteger maxDisplayLineBelow;

@property (nonatomic, assign, readwrite) CGFloat spaceBetweenLine;
@property (nonatomic, assign, readwrite) CGFloat spaceBetweenSentence;

@property (nonatomic, strong, readwrite) UIFont* curSentenceFont;
@property (nonatomic, strong, readwrite) UIFont* normalSentenceFont;

@property (nonatomic, strong, readwrite) UIColor* highlightedWordColor;//逐字颜色
@property (nonatomic, strong, readwrite) UIColor* curSentenceColor; //逐句颜色

@property (nonatomic, strong, readwrite) UIColor* normalSentenceColor;//其它句子颜色

@property (nonatomic, assign, readwrite) NSTimeInterval dragFinishDelayTime;
@property (nonatomic, strong, readwrite) UIView* standerLineView;

@property (nonatomic, strong, readwrite) NSArray<NSString*>* sortedBeginTimeKeys;

@property (nonatomic, strong, readwrite) FMLyricLabel* curLineLabel;
@property (nonatomic, assign, readwrite) NSInteger curLine;

@property (nonatomic, strong, readwrite) NSMutableArray<NSNumber*>* curScrollOffsetYArr;

@property (nonatomic, assign, readwrite) BOOL isDraging;
@property (nonatomic, assign, readwrite) CGFloat scrollToTimeMills;

@end

@interface FMLyricFullView () <UIScrollViewDelegate>

@end

@implementation FMLyricFullView

- (instancetype)initWithFrame:(CGRect)frame{
    
    if(self = [super initWithFrame:frame]){
        
        [self _initLyricScrollView];
        [self _initParameters];
        [self _initStanderLineView];
    }
    return self;
}

- (void)_initParameters{
    
    self.lyricDispalayWidth = self.lyricScrollView.frame.size.width - 40;
    
    self.lyricIdxToShow = 0;
    
    self.curSentenceMarginTop = self.lyricScrollView.frame.size.height * 0.5;
    
    self.shouldHightenedByWord = NO;
    
    self.curSentenceFont = [UIFont boldSystemFontOfSize:11];
    self.normalSentenceFont = [UIFont systemFontOfSize:8];
    
    self.highlightedWordColor = [UIColor greenColor]; //逐字颜色默认未绿色
    self.curSentenceColor = [UIColor yellowColor]; //逐句颜色默认未蓝色
    self.normalSentenceColor = [UIColor whiteColor]; //其它句子颜色默认未白色
    
    self.maxDisplayLineAbove = 5;
    self.maxDisplayLineBelow = 5;
    
    self.spaceBetweenLine = 3.2;
    self.spaceBetweenSentence = 16;
    
    self.textAlignment = FMTextAlignmentMiddle;
    
    self.dragFinishDelayTime = 6;
    
    self.curScrollOffsetYArr = [NSMutableArray array];
 
    self.isDraging = NO;
}

- (void)_initLyricScrollView{
    
    CGRect lyricScrollViewFrame = self.bounds;
    _lyricScrollView = [[UIScrollView alloc] initWithFrame:lyricScrollViewFrame];
    _lyricScrollView.backgroundColor = [UIColor blackColor];
    _lyricScrollView.alpha = 0.8;
    _lyricScrollView.delegate = self;
    [self addSubview:_lyricScrollView];
}

- (void)_initStanderLineView{
    self.standerLineView = [[UIView alloc] init];
    self.standerLineView.backgroundColor = self.backgroundColor;
    self.standerLineView.alpha = self.alpha;
    self.standerLineView.frame = CGRectMake(0, self.curSentenceMarginTop, self.bounds.size.width, kStanderLineHeight);
    [self addSubview:self.standerLineView];
    
    UILabel* leftTimeLabel = [[UILabel alloc] init];
    leftTimeLabel.tag = kStanderLineLeftTimeLabelTag;
    leftTimeLabel.textColor = [UIColor whiteColor];
    leftTimeLabel.font = [UIFont systemFontOfSize:12];
    leftTimeLabel.frame = CGRectMake(10, 0, 0, 0);
    [self.standerLineView addSubview:leftTimeLabel];
    
    UIButton* rightPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightPlayBtn.tag = kStanderLineRightPlayBtnTag;
    [rightPlayBtn addTarget:self action:@selector(standerLineRightPlayBtnPressAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightPlayBtn setImage:[UIImage imageNamed:@"icon_standerLineView_rightPlay"] forState:UIControlStateNormal];
    rightPlayBtn.contentMode = UIViewContentModeScaleAspectFit;
    rightPlayBtn.frame = CGRectMake(self.standerLineView.bounds.size.width - 20 - 10, 0, 20, 20);
    [self.standerLineView addSubview:rightPlayBtn];
    
    self.standerLineView.hidden = YES;
    
}

- (void)layoutLyricPanel{
    
    FMSingleLyricModel* singleLyricModel = [self.lyricFileModel getSingleLyricModelWithIndex:_lyricIdxToShow];
    
    NSUInteger allCntOfLines = singleLyricModel.sentencseDict.count;
    
    NSArray<NSString*>* allBeginTimeStamp = [singleLyricModel.sentencseDict.allKeys copy];
    allBeginTimeStamp = [allBeginTimeStamp sortedArrayUsingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
        int first = [obj1 intValue];
        int second = [obj2 intValue];
        if(first > second){
            return NSOrderedDescending;
        }else if(first < second){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
    }];

    _sortedBeginTimeKeys = allBeginTimeStamp;
    
    //CGFloat maginBottom = 10;
    
    CGFloat curLabelY = self.curSentenceMarginTop;
    
    CGFloat curScrollOffsetY = 0;
    
    for (int i = 0; i < allCntOfLines; i++) {
        
        FMLyricLabel* labelLine = [[FMLyricLabel alloc] initWithFrame:CGRectMake(20, 0, self.bounds.size.width - 40, 30)];
        
        [labelLine setLineBreakEnable:YES];
        [labelLine setLyricDispalayWidth:self.lyricDispalayWidth];
        
        switch (self.textAlignment) {
            case FMTextAlignmentLeft:
                [labelLine setTextAlignment:NSTextAlignmentLeft];
                break;
            case FMTextAlignmentMiddle:
                [labelLine setTextAlignment:NSTextAlignmentCenter];
                break;
            case FMTextAlignmentRight:
                [labelLine setTextAlignment:NSTextAlignmentRight];
                break;
            default:
                [labelLine setTextAlignment:NSTextAlignmentCenter];
                break;
        }
        
        labelLine.tag = i + kLineLabelTagInitialNumber;
        
        NSString* key = allBeginTimeStamp[i];
        [labelLine setText:singleLyricModel.sentencseDict[key].sentence];
        
        CGSize textSize = [labelLine textSizeWithWidthLimit];
        
        CGFloat labelH = textSize.height;
        //CGFloat labelW = textSize.width;
        
        //CGFloat labelX;
        CGFloat labelY;
        
        if(textSize.width <= self.lyricDispalayWidth){
            
            //labelX = (self.lyricScrollView.frame.size.width - textSize.width) * 0.5;
        }else{
            NSLog(@"有折行");
            //labelX = 20;
            //labelW = self.lyricScrollView.frame.size.width - 20 * 2;
        }
        
        labelY = curLabelY;
        curLabelY += (labelH + self.spaceBetweenSentence);
        
        //NSLog(@"i=%zd,当前Lable的高度：%f,当前Lable的Y：%f",i,labelH,labelY);
        
        CGRect labelFrame = labelLine.frame;
        //labelFrame.origin.x = labelX;
        labelFrame.origin.y = labelY;
        //labelFrame.size.width = labelW;
        labelFrame.size.height = labelH;
        labelLine.frame = labelFrame;
        
        [self.curScrollOffsetYArr addObject:@(curScrollOffsetY)];
        
        curScrollOffsetY += (labelH + self.spaceBetweenSentence);
        
        [self.lyricScrollView addSubview:labelLine];
        
    }
    self.lyricScrollView.contentSize = CGSizeMake(0, curLabelY + (self.lyricScrollView.frame.size.height - self.curSentenceMarginTop));
    
 }


- (void)loadLyricAtPath:(NSString *)lyricPath translateLyricAtPath:(NSString *)translateLyricPath{
    
    [self loadLyricAtPath:lyricPath translateLyricAtPath:translateLyricPath lyricFileType:FMLyricFileTypeAuto];
    
}

- (void)loadLyricContent:(NSString *)lyricContent translateLyricContent:(NSString *)translateLyricContent{
    [self loadLyricContent:lyricContent translateLyricContent:translateLyricContent lyricFileType:FMLyricFileTypeAuto];
}


- (void)loadLyricAtPath:(NSString *)lyricPath translateLyricAtPath:(NSString *)translateLyricPath lyricFileType:(FMLyricFileType)lyricFileType{
    self.lyricFileModel = [[FMLyricFileModel alloc] initWithLyricFilePath:lyricPath type:lyricFileType];
    [self layoutLyricPanel];
}


- (void)loadLyricContent:(NSString *)lyricContent translateLyricContent:(NSString *)translateLyricContent lyricFileType:(FMLyricFileType)lyricFileType{
    self.lyricFileModel = [[FMLyricFileModel alloc] initWithLyricContent:lyricContent type:lyricFileType];
    [self layoutLyricPanel];
}

- (void)setLyricDisplayWidth:(CGFloat)width{
    _lyricDispalayWidth = width;
}

- (void)setLyricIdxToShow:(NSUInteger)idx{
    _lyricIdxToShow = idx;
}

- (void)setHighlightedWordColor:(UIColor *)highlightedWordColor
               curSentenceColor:(UIColor *)curSentenceColor
            normalSentenceColor:(UIColor *)normalSentenceColor{
    _highlightedWordColor = highlightedWordColor;
    _curSentenceColor = curSentenceColor;
    _normalSentenceColor = normalSentenceColor;
}

- (void)setCurSentenceFont:(UIFont *)curSentenceFont
                  normalSentenceFont:(UIFont *)normalSentenceFont{
    _curSentenceFont = curSentenceFont;
    _normalSentenceFont = normalSentenceFont;
}

- (void)setTextAlignment:(FMTextAlignment)textAlignment{
    _textAlignment = textAlignment;
}

- (void)setCurSentenceMarginTop:(CGFloat)marginTop{
    _curSentenceMarginTop = marginTop;
}


- (void)setShouldHilightenedByWord:(BOOL)shouldHightenedByWord{
    _shouldHightenedByWord = shouldHightenedByWord;
}

- (void)setMaxDisplayLineAbove:(NSUInteger)maxDisplayLineAbove{
    _maxDisplayLineAbove = maxDisplayLineAbove;
}

- (void)setMaxDisplayLineBelow:(NSUInteger)maxDisplayLineBelow{
    _maxDisplayLineBelow = maxDisplayLineBelow;
}

- (void)setDragable:(BOOL)dragable{
    [self.lyricScrollView setScrollEnabled:dragable];
}


- (void)setStanderLineView:(UIView *)standerLineView{
    
    if(_standerLineView){
        [_standerLineView removeFromSuperview];
    }
    _standerLineView = standerLineView;
    [self addSubview:_standerLineView];
}

- (void)setSpaceBetweenLine:(CGFloat)spaceBetweenLine{
    _spaceBetweenLine = spaceBetweenLine;
}

- (void)setSpaceBetweenSentence:(CGFloat)spaceBetweenSentence{
    _spaceBetweenSentence = spaceBetweenSentence;
}

- (void)setDragFinishDelay:(NSTimeInterval)dragFinishDelayTime{
    _dragFinishDelayTime = dragFinishDelayTime;
}

- (FMSingleLyricModel*)singleLyricModel{
    return  [self.lyricFileModel getSingleLyricModelWithIndex:_lyricIdxToShow];
}


//这两个函数play和pause 有Bug：拖动滑块会跳过某一行，过一段时间直接跳到下一行逐字了
- (void)resumeAnimation{
    NSLog(@"点击了开始，从暂停位置开始逐字滚动");
    [self.curLineLabel resumeAnimation];
}

- (void)pauseAnimation{
    NSLog(@"点击了暂停,当前逐字将停止");
    [self.curLineLabel pauseAnimation];
}

- (void)repaintWithProgressTime:(double)progressTime{
    //millProgressTime:毫秒;
    NSInteger millProgressTime = (int) (progressTime * kMillSceondsPerSecond);
    
    NSInteger curLine;
    NSInteger curColumn;
    BOOL isLastColumn = NO;
    
    NSString* matchedBeginTimeKey = [self _getCurSentenceTimeStampWithPregressTime:millProgressTime curLine:&curLine curColumn:&curColumn isLastColumn:&isLastColumn];
    
    if(matchedBeginTimeKey.length <= 0 || curLine < 0 || curColumn < 0){
        NSLog(@"参数progressTime[%f]有误",progressTime);
        return;
    }
    
    FMLyricLabel* lineLabel = (FMLyricLabel*)[self.lyricScrollView viewWithTag:curLine + kLineLabelTagInitialNumber];
    self.curLineLabel = lineLabel;//当前高亮Label
    self.curLine = curLine;
    
    BOOL stillInSameLine = [lastUpdateedSentenceBeginTimeKey isEqualToString:matchedBeginTimeKey];
    
    [self resetPanelSentenceColor];
    
    if(stillInSameLine){
        NSLog(@"同一行内，当前行：curLine:%zd,当前列：%zd,text:%@,word:%@",curLine,curColumn,[lineLabel text],[[lineLabel text] substringWithRange:NSMakeRange(curColumn, 1)]);
        //同一行内：打开 关闭 打开 关闭 循环测试
        if(self.shouldHightenedByWord){
           //在本行逐字开关依然打开
            if(![lineLabel isOpenedAnimation]){
                //本行上没有动画，中间时点击了逐字开关，从curColumn位置开始动画
                [self startLineLabelAnimation:lineLabel fromColumn:curColumn withMatchedBeginTimeKey:matchedBeginTimeKey isLastColumn:isLastColumn];
            }else{
               //本行已经开启了动画，什么都不做
            }
        }else{
            //在本行中间逐字开关被关闭
            if([lineLabel isOpenedAnimation]){
                //本行已经开过动画，这会移除动画
                NSLog(@"在本行中间逐字开关被关闭,本行已经开过动画，现在移除动画");
                [lineLabel removeAnimation];
            }else{
                //本行未开过动画，啥事不做
            }
        }
    }else{
        NSLog(@"到下一行了,当前行是：curLine:%zd,text:%@",curLine,[lineLabel text]);
        
        if(self.shouldHightenedByWord){
            //本行开始时打开了逐字开关
            if(![lineLabel isOpenedAnimation]){
                [self startLineLabelAnimation:lineLabel fromColumn:0 withMatchedBeginTimeKey:matchedBeginTimeKey isLastColumn:isLastColumn];
            }
        }else{
            //本行开始时未打开逐字开关
        }
        
        lastUpdateedSentenceBeginTimeKey = matchedBeginTimeKey;
        
        if(curLine >= 0 && curLine < self.curScrollOffsetYArr.count){
            CGFloat offsetY = [self.curScrollOffsetYArr[curLine] floatValue];
            [UIView animateWithDuration:1 animations:^{
                self.lyricScrollView.contentOffset = CGPointMake(0, offsetY);
            }];
        }

    }
    
}
//公用动画函数
- (void)startLineLabelAnimation:(FMLyricLabel*)lineLabel fromColumn:(NSInteger)fromColumn withMatchedBeginTimeKey:(NSString*)matchedBeginTimeKey isLastColumn:(BOOL)isLastColumn{
    NSMutableArray<NSNumber *>* timesArr = [NSMutableArray array];
    NSMutableArray<NSNumber *> *locationArr = [NSMutableArray array];
    
    //timesAbsoluteArr 字开始时间数组  0  23  984  983
    //locationPercentArr 对应位置     0  0.2  0.8  1.0 每个字的持续时间／总持续时间
    FMLyricSentenceModel* curSentenceModel = [self.singleLyricModel.sentencseDict objectForKey:matchedBeginTimeKey];
    NSArray<FMLyricWordModel*>* curWordModels = [curSentenceModel sortedRelativeWordModelsByBeginTime];//重写wordModels保证按照beginTime排序
    
    //整个句子总时间
    CGFloat allWordsDuration = curSentenceModel.allWordsDuration;
    allWordsDuration = allWordsDuration / kMillSceondsPerSecond;
    
    //句子某个字开始时间
    CGFloat leftDutation = 0;//当前字到句末的剩余时间
    for (NSInteger i = fromColumn; i < curWordModels.count; i++) {
        FMLyricWordModel* curWordModel = curWordModels[i];
        leftDutation += curWordModel.duration;
    }
    leftDutation = leftDutation / kMillSceondsPerSecond;
    
    //当前位置所占句子百分比
    CGFloat curLocationPoint = (allWordsDuration - leftDutation) / allWordsDuration;;
   
    
    for (NSInteger i = fromColumn; i < curWordModels.count; i++) {
        
        FMLyricWordModel* tmpWordModel = curWordModels[i];
        
        CGFloat beginTimeSecond = (float)(tmpWordModel.beginTime) / kMillSceondsPerSecond;
        [timesArr addObject:@(beginTimeSecond)];
        
        [locationArr addObject:@(curLocationPoint)];
        CGFloat curWordDuration = (float)tmpWordModel.duration / kMillSceondsPerSecond;
        CGFloat locationPercent = (float)curWordDuration / allWordsDuration;
        curLocationPoint += locationPercent;
        
    }
    CGFloat finalEndTimePoint = curWordModels.lastObject.beginTime + curWordModels.lastObject.duration;
    finalEndTimePoint = finalEndTimePoint / kMillSceondsPerSecond;
    [timesArr addObject:@(finalEndTimePoint)];//最后一个词的开始时间＋最后一个词的持续时间)
    [locationArr addObject:@(curLocationPoint)];
    
    if (isLastColumn) {
        if(self.shouldHightenedByWord){
            [self resetPanelSentenceColor];
        }
        NSLog(@"最后一列，移除动画");
        [lineLabel removeAnimation];
        return;
    }
    
    [lineLabel startAnimationWithTimesAbsoluteArr:timesArr locationPercentArr:locationArr duration:leftDutation];
    
    //[lineLabel showAnimation];
    
    if(fromColumn == 0){
        NSLog(@"你是从本行开始就开启了动画");
    }else{
        NSLog(@"你是从本行中间位置开启的动画");
    }
}

/**
 刷新面板所有Label颜色时，
   如果逐字开关打开：当前行higtedColor设置(maskLabel)，
                  其它行Label设置为normalColor
   如果逐字开关关闭：当前行textLabel设置为curSentenColor
                  其它行Label设置为normalColor
 
 
 */

- (void)resetPanelSentenceColor{
    
    //NSLog(@"准备刷新颜色：第%zd行，text：%@",curLine,[lineLabel text]);
    
    [self.lyricScrollView.subviews enumerateObjectsUsingBlock:^(UIView* subview, NSUInteger idx, BOOL* stop) {
        if([subview isKindOfClass:[FMLyricLabel class]]){
            FMLyricLabel* label = (FMLyricLabel*)subview;
            
            if (label == self.curLineLabel) {
                if(self.shouldHightenedByWord){
                    [label setTextColor:self.normalSentenceColor maskColor:self.highlightedWordColor];
                }else{
                    [label setTextColor:self.curSentenceColor maskColor:self.highlightedWordColor];
                }
            }else{
                [label setTextColor:self.normalSentenceColor maskColor:self.highlightedWordColor];
            }
            
            //不是高亮行的行，如果有动画，则动画移除，再变色
           if((label != self.curLineLabel) && [label isOpenedAnimation]){
               [label removeAnimation];
           }
            
        }
    }];
}

- (void)clear{
    [self.lyricScrollView.subviews enumerateObjectsUsingBlock:^(UIView* subview, NSUInteger idx, BOOL* stop) {
        [subview removeFromSuperview];
        
    }];
}

- (NSString*)_getCurSentenceTimeStampWithPregressTime:(NSInteger)millProgressTime curLine:(NSInteger *)curLine curColumn:(NSInteger*)curColumn isLastColumn:(BOOL*)isLastColumn{
    //pregressTime:毫秒  return：毫秒
    NSString* mattchedBeginTimeKey;
    
    NSUInteger count = _sortedBeginTimeKeys.count;
    NSInteger expLineIdx = -1;
    NSInteger expColumnIdx = -1;

    for (NSUInteger i = 0; i < count; i++) {
        if(millProgressTime == [_sortedBeginTimeKeys[i] intValue]){
            expLineIdx = i;
            break;
        }else if(millProgressTime < [_sortedBeginTimeKeys[i] intValue]){
            expLineIdx = i - 1; // i=0->-1, 从第一句开始算起
            break;
        }else{
            if(i == (count - 1)){
                expLineIdx = i;
                break;
            }
        }
    }
    if(expLineIdx >= 0){
        mattchedBeginTimeKey = _sortedBeginTimeKeys[expLineIdx];
        *curLine = expLineIdx;
        
        FMSingleLyricModel* singleLyricModel =  [self.lyricFileModel getSingleLyricModelWithIndex:_lyricIdxToShow];
        FMLyricSentenceModel* curSentenceModel = singleLyricModel.sentencseDict[mattchedBeginTimeKey];
        
        *isLastColumn = NO;
        NSArray<FMLyricWordModel*>* sortedWordModels = [curSentenceModel sortedAbsoluteWordModelsByBeginTime];
        for (int i = 0; i < sortedWordModels.count; i++) {
            if(millProgressTime == sortedWordModels[i].beginTime){
                expColumnIdx = i;
                break;
            }else if(millProgressTime < sortedWordModels[i].beginTime){
                expColumnIdx = i - 1;
                break;
            }else{
                if(i == (sortedWordModels.count - 1)){
                    expColumnIdx = i;
                    *isLastColumn = YES;
                    break;
                }
            }
        }
        
        *curColumn = expColumnIdx;
        
    }else{
        mattchedBeginTimeKey = nil;
        *curLine = -1;
        *curColumn = -1;
    }
    
    return mattchedBeginTimeKey;
}

#pragma - mark UIScrollViewDelegate
//刷新下一行时会自动滚到当前行，当滑动面板结束三秒后回到当前行
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    if(self.isDraging){
        return;
    }
    
    self.isDraging = YES;
    
    NSLog(@"拖动了歌词面板，");
    self.standerLineView.alpha = 0.0;
    self.standerLineView.hidden = NO;
    [UIView animateWithDuration:0.5 animations:^{
        self.standerLineView.alpha = 1.0;
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    NSLog(@"ScrollView正在滚动,offsetY:%f",scrollView.contentOffset.y);
    
    UILabel* leftTimeLabel = (UILabel*)[self.standerLineView viewWithTag:kStanderLineLeftTimeLabelTag];
    
    NSInteger curLine =  [self getcurLineNumWhenScrollTo:scrollView.contentOffset];
    NSInteger scrollToTimeMills = [_sortedBeginTimeKeys[curLine] intValue];//毫秒  /*滚动过程中，歌词面板中间位置是哪一行*/
    self.scrollToTimeMills = scrollToTimeMills;
    
    NSInteger minutes = scrollToTimeMills / kMillSceondsPerSecond / kSecondsPerMinute;
    NSInteger seconds = scrollToTimeMills / (int)kMillSceondsPerSecond % (int)kSecondsPerMinute;
    NSString* timeText = [NSString stringWithFormat:@"%02zd:%02zd",minutes, seconds];
    leftTimeLabel.text = timeText;
    [leftTimeLabel sizeToFit];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if(!decelerate){//生硬拖动，没有减速过程
         [self performSelector:@selector(scrollToCurrentSentence) withObject:nil afterDelay:self.dragFinishDelayTime];
         self.isDraging = NO;
    }
}
//在一次拖动减速过程未结束再次拖动时不会调用，只会在彻底拖动结束后才会调用
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
     self.isDraging = NO;
    [self performSelector:@selector(scrollToCurrentSentence) withObject:nil afterDelay:self.dragFinishDelayTime];
}

- (void)standerLineRightPlayBtnPressAction:(UIButton*)sender{
    CGFloat scrollToTimeSecond = self.scrollToTimeMills / kMillSceondsPerSecond;
    [self repaintWithProgressTime:scrollToTimeSecond];
    NSLog(@"传给播放器的参数：%f",scrollToTimeSecond);
    if([self.delegate conformsToProtocol:@protocol(FMLyricViewDelegate)] &&
       [self.delegate respondsToSelector:@selector(lyricView:didEndDraggingToProgress:)]){
            [self.delegate lyricView:self didEndDraggingToProgress:scrollToTimeSecond];
    }
}

- (void)scrollToCurrentSentence{
    NSLog(@"拖动结束，返回当前行");
    if(!self.isDraging){
        [UIView animateWithDuration:1.5 animations:^{
            self.standerLineView.alpha = 0.0;
        } completion:^(BOOL finished) {
            if(finished){
                self.standerLineView.hidden = YES;
            }
        }];
     }
   
    CGFloat offsetY = [self.curScrollOffsetYArr[self.curLine] floatValue];
    [UIView animateWithDuration:1.0 animations:^{
        self.lyricScrollView.contentOffset = CGPointMake(0, offsetY);
    }];
    
}

- (NSInteger)getcurLineNumWhenScrollTo:(CGPoint)scrollOffset{
    
    NSInteger idx = 0;
    CGFloat scrollOffsetY = scrollOffset.y;
    if(scrollOffsetY <= 0){
        return idx;
    }
    if(scrollOffsetY >= [self.curScrollOffsetYArr.lastObject floatValue]){
        return self.curScrollOffsetYArr.count - 1;
    }
    
    CGFloat curDiff = MAXFLOAT;
    CGFloat tmp = 0;
    while( ( tmp = ABS([self.curScrollOffsetYArr[idx] floatValue] - scrollOffsetY) ) < curDiff ){
        curDiff = tmp;
        idx ++;
        if(idx >= self.curScrollOffsetYArr.count){
            break;
        }
    }
    idx--;//结果
    return idx;
}

@end
