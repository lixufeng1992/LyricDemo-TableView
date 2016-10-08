//
//  FMLyricSmallView.m
//  LyricDemo
//
//  Created by lixufeng on 16/9/30.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "FMLyricSmallView.h"
#import "FMLyricLabel.h"
#import "FMLyricFileModel.h"

@interface FMLyricSmallView ()

@property (nonatomic, strong, readwrite) UIScrollView* lyricScrollLine;
@property (nonatomic, strong, readwrite) FMLyricLabel* curLineLabel;


@property (nonatomic, strong, readwrite) FMLyricFileModel* lyricFileModel;
@property (nonatomic, assign, readwrite) NSUInteger lyricIdxToShow;    //要展示第几首歌词
@property (nonatomic, strong, readwrite) FMSingleLyricModel* singleLyricModel;

@property (nonatomic, assign, readwrite) CGFloat lyricDispalayWidth;

@property (nonatomic, assign, readwrite) FMTextAlignment textAlignment;

@property (nonatomic, assign, readwrite) BOOL shouldHightenedByWord;

@property (nonatomic, strong, readwrite) UIFont* curSentenceFont;

@property (nonatomic, strong, readwrite) UIColor* highlightedWordColor;//逐字高亮颜色
@property (nonatomic, strong, readwrite) UIColor* curSentenceColor; //逐句底色
@property (nonatomic, strong, readwrite) UIColor* normalSentenceColor;//其它句子颜色

@property (nonatomic, strong, readwrite) NSArray<NSString*>* sortedBeginTimeKeys;

@property (nonatomic, assign, readwrite) NSInteger curLine;
@property (nonatomic, strong, readwrite) NSString* lastUpdateedSentenceBeginTimeKey;

@property (nonatomic, assign, readwrite) NSInteger midColumn;
@property (nonatomic, assign, readwrite) BOOL shouldHorseRace;
@property (nonatomic, assign, readwrite) NSInteger prevColumn;

@end

@implementation FMLyricSmallView

- (instancetype)init{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame{
    if(self == [super initWithFrame:frame]){
        [self initLyricScrollLine];
        [self _initParameters];
        [self initCurLineLabel];
    }
    return  self;
}


- (void)initLyricScrollLine{
    self.lyricScrollLine = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.lyricScrollLine.showsVerticalScrollIndicator = NO;
    self.lyricScrollLine.showsHorizontalScrollIndicator = NO;
    self.lyricScrollLine.backgroundColor = [UIColor blackColor];
    self.lyricScrollLine.alpha = 0.8;
    self.lyricScrollLine.contentSize =  CGSizeMake(SCREEN_WIDTH * 3, 0);
    [self addSubview:self.lyricScrollLine];
}

- (void)_initParameters{
    
    self.lyricDispalayWidth = self.lyricScrollLine.frame.size.width - 40;
    
    self.lyricIdxToShow = 0;
    
    self.shouldHightenedByWord = YES;
    
    self.curSentenceFont = [UIFont boldSystemFontOfSize:11];
    
    self.highlightedWordColor = [UIColor greenColor]; //逐字颜色默认未绿色
    self.curSentenceColor = [UIColor yellowColor]; //逐句颜色默认未蓝色
    self.normalSentenceColor = [UIColor whiteColor]; //其它句子颜色默认未白色
    
    self.textAlignment = FMTextAlignmentMiddle;
    
    self.curLine = 0;
    
    self.midColumn = -1;
    self.shouldHorseRace = NO;
    self.prevColumn = -1;
}


- (NSArray<NSString*>*) sortedBeginTimeKeys{
    
    if(!_sortedBeginTimeKeys){
    
        FMSingleLyricModel* singleLyricModel = self.singleLyricModel;
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
    }
    return _sortedBeginTimeKeys;
}



- (void)initCurLineLabel{
    
    FMLyricLabel* labelLine = [[FMLyricLabel alloc] initWithFrame:self.bounds];
        
    [labelLine setLineBreakEnable:NO];
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
        
    self.curLineLabel = labelLine;
    
    [self.lyricScrollLine addSubview:self.curLineLabel];
}



- (void)loadLyricAtPath:(NSString *)lyricPath translateLyricAtPath:(NSString *)translateLyricPath{
    
    [self loadLyricAtPath:lyricPath translateLyricAtPath:translateLyricPath lyricFileType:FMLyricFileTypeAuto];
    
}

- (void)loadLyricContent:(NSString *)lyricContent translateLyricContent:(NSString *)translateLyricContent{
    [self loadLyricContent:lyricContent translateLyricContent:translateLyricContent lyricFileType:FMLyricFileTypeAuto];
}


- (void)loadLyricAtPath:(NSString *)lyricPath translateLyricAtPath:(NSString *)translateLyricPath lyricFileType:(FMLyricFileType)lyricFileType{
    self.lyricFileModel = [[FMLyricFileModel alloc] initWithLyricFilePath:lyricPath type:lyricFileType];
    [self updateCurLabelData];
}


- (void)loadLyricContent:(NSString *)lyricContent translateLyricContent:(NSString *)translateLyricContent lyricFileType:(FMLyricFileType)lyricFileType{
    self.lyricFileModel = [[FMLyricFileModel alloc] initWithLyricContent:lyricContent type:lyricFileType];
    [self updateCurLabelData];
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

- (void)setCurSentenceFont:(UIFont *)curSentenceFont{
    _curSentenceFont = curSentenceFont;
}

- (void)setTextAlignment:(FMTextAlignment)textAlignment{
    _textAlignment = textAlignment;
}


- (void)setShouldHilightenedByWord:(BOOL)shouldHightenedByWord{
    _shouldHightenedByWord = shouldHightenedByWord;
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
    
    NSInteger millProgressTime = (int) (progressTime * kMillSceondsPerSecond);
    NSInteger curLine;
    NSInteger curColumn;
    BOOL isLastColumn = NO;
    
    NSString* matchedBeginTimeKey = [self _getCurSentenceTimeStampWithPregressTime:millProgressTime curLine:&curLine curColumn:&curColumn isLastColumn:&isLastColumn];
    
    if(matchedBeginTimeKey.length <= 0 || curLine < 0 || curColumn < 0){
        NSLog(@"参数progressTime[%f]有误",progressTime);
        return;
    }
    
    self.curLine = curLine;
    
    BOOL stillInSameLine = [self.lastUpdateedSentenceBeginTimeKey isEqualToString:matchedBeginTimeKey];
    
    [self resetCurSentenceColor];
    
    if(stillInSameLine){
        NSLog(@"同一行内，当前行：curLine:%zd,当前列：%zd,text:%@,word:%@",curLine,curColumn,[self.curLineLabel text],[[self.curLineLabel text] substringWithRange:NSMakeRange(curColumn, 1)]);
        
        //跑马灯
        if(self.prevColumn != curColumn){//到下一列了
            if(self.shouldHorseRace && curColumn >= self.midColumn){
                CGPoint contentOffset = self.lyricScrollLine.contentOffset;
                
                CGFloat truncWidth = [self getTruncWidthForCurLine];
                
                if(contentOffset.x < truncWidth){
                    
                    contentOffset.x += [self getColumnWidthWithLine:self.curLine column:curColumn];
                    [UIView animateWithDuration:0.5 animations:^{
                        self.lyricScrollLine.contentOffset = contentOffset;
                    }];
                }
                
            }
            self.prevColumn = curColumn;
        }
        //同一行内：打开 关闭 打开 关闭 循环测试
        if(self.shouldHightenedByWord){
            //在本行逐字开关依然打开
            if(![self.curLineLabel isOpenedAnimation]){
                //本行上没有动画，中间时点击了逐字开关，从curColumn位置开始动画
                [self startLineLabelAnimation:self.curLineLabel fromColumn:curColumn withMatchedBeginTimeKey:matchedBeginTimeKey isLastColumn:isLastColumn];
            }else{
                //本行已经开启了动画，什么都不做
            }
        }else{
            //在本行中间逐字开关被关闭
            if([self.curLineLabel isOpenedAnimation]){
                //本行已经开过动画，这会移除动画
                NSLog(@"在本行中间逐字开关被关闭,本行已经开过动画，现在移除动画");
                [self.curLineLabel removeAnimation];
            }else{
                //本行未开过动画，啥事不做
            }
        }
    }else{
        NSLog(@"到下一行了,更新Label的内容");
        [self updateCurLabelData];
        [self.curLineLabel removeAnimation];//到下一行了，下一行肯定没有加过动画
        if(self.shouldHightenedByWord){
            //本行开始时打开了逐字开关
            [self startLineLabelAnimation:self.curLineLabel fromColumn:0 withMatchedBeginTimeKey:matchedBeginTimeKey isLastColumn:isLastColumn];
        }else{
            //本行开始时未打开逐字开关
        }
        
        self.lastUpdateedSentenceBeginTimeKey = matchedBeginTimeKey;
    }
}

- (void)updateCurLabelData{
    
    NSString* key = self.sortedBeginTimeKeys[self.curLine];
    [self.curLineLabel setText:self.singleLyricModel.sentencseDict[key].sentence];
    //重置contentOffset
    self.lyricScrollLine.contentOffset = CGPointZero;
    if([self.curLineLabel textSizeWithHeightLimit].width > self.lyricScrollLine.frame.size.width){
        //开启跑马灯
        self.shouldHorseRace = YES;
        //重置LineLabel frame
        CGRect frame = self.curLineLabel.frame;
        frame.size.width = [self.curLineLabel textSizeWithHeightLimit].width;
        self.curLineLabel.frame = frame;
        //重置对齐方式
        [self.curLineLabel setTextAlignment:NSTextAlignmentLeft];
        //重新ScrollView 可视范围
        self.lyricScrollLine.contentSize = CGSizeMake([self.curLineLabel textSizeWithHeightLimit].width, 0);
        
        //计算midColumn
        CGFloat midPoint = self.lyricScrollLine.frame.size.width * 0.5;
        
        self.midColumn = [self _getMidColumnIdxWithLine:self.curLine midPoint:midPoint];
        
    }else{
        self.curLineLabel.frame = self.bounds;
        [self.curLineLabel setTextAlignment:NSTextAlignmentCenter];
        self.lyricScrollLine.contentSize = self.bounds.size;
        self.midColumn = -1;
        self.shouldHorseRace = NO;
    }
    
}

- (NSInteger)_getMidColumnIdxWithLine:(NSInteger)line midPoint:(CGFloat)midPoint{
    
    NSInteger midColumn = -1;
    
    NSString* key = self.sortedBeginTimeKeys[line];
    FMLyricSentenceModel* sentenceModel = self.singleLyricModel.sentencseDict[key];
    
    NSArray<FMLyricWordModel*>* sortedWordModels = sentenceModel.sortedRelativeWordModelsByBeginTime;
    CGFloat curSumWidth = 0;
    for (NSInteger i = 0; i < sortedWordModels.count; i++) {
        FMLyricWordModel* wordModel = sortedWordModels[i];
        curSumWidth += [self.curLineLabel wordSizeWithHeightLimit:wordModel.word].width;
        if(curSumWidth >= midPoint){
            midColumn = i;
            break;
        }
    }
    
    return midColumn;
}

- (CGFloat)getColumnWidthWithLine:(NSInteger)line column:(NSInteger)column{
    CGFloat width = 0;
    NSString* key = self.sortedBeginTimeKeys[line];
    FMLyricSentenceModel* sentenceModel = self.singleLyricModel.sentencseDict[key];
    NSArray<FMLyricWordModel*>* sortedWordModels = sentenceModel.sortedRelativeWordModelsByBeginTime;
    if(column < sortedWordModels.count){
        width = [self.curLineLabel wordSizeWithHeightLimit:sortedWordModels[column].word].width;
    }else{
        NSLog(@"传入参数column:[%zd]大于第[%zd]行总共列数",column,line);
    }
    
    return width;
}

- (CGFloat)getTruncWidthForCurLine{
    CGFloat truncWidth = 0;
    if([self.curLineLabel textSizeWithHeightLimit].width > self.lyricScrollLine.frame.size.width){
        truncWidth = [self.curLineLabel textSizeWithHeightLimit].width - self.lyricScrollLine.frame.size.width;
    }
    return truncWidth;
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
            [self resetCurSentenceColor];
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


- (void)resetCurSentenceColor{
    
    if(self.shouldHightenedByWord){
        [self.curLineLabel setTextColor:self.normalSentenceColor maskColor:self.highlightedWordColor];
    }else{
        [self.curLineLabel setTextColor:self.curSentenceColor maskColor:self.highlightedWordColor];
    }

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



- (void)clear{
    
}



@end
