//
//  FMLyricFullView.m
//  LyricDemo
//
//  Created by lixufeng on 16/9/13.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "FMLyricFullView.h"
#import "FMLyricFileModel.h"
#import "FMLyricCell.h"

@interface FMLyricFullView(){
    NSString* lastUpdateedSentenceBeginTimeKey;
}

#pragma -mark 全部属性
@property (nonatomic, strong, readwrite) UITableView* tableView;

@property (nonatomic, strong, readwrite) FMLyricFileModel* lyricFileModel;
@property (nonatomic, assign, readwrite) NSUInteger lyricIdxToShow;    //要展示第几首歌词
@property (nonatomic, strong, readwrite) FMSingleLyricModel* singleLyricModel;

@property (nonatomic, assign, readwrite) FMTextAlignment textAlignment;

@property (nonatomic, assign, readwrite) BOOL shouldHightenedByWord;

@property (nonatomic, assign, readwrite) CGFloat spaceBetweenSentence;

@property (nonatomic, strong, readwrite) UIFont* curSentenceFont;
@property (nonatomic, strong, readwrite) UIFont* normalSentenceFont;

@property (nonatomic, strong, readwrite) UIColor* highlightedWordsColor;//LRC：当前句颜色，QRC：逐字颜色
@property (nonatomic, strong, readwrite) UIColor* normalSentenceColor;//正常句子底色

@property (nonatomic, assign, readwrite) NSTimeInterval dragFinishDelayTime;
@property (nonatomic, strong, readwrite) UIView* standerLineView;

@property (nonatomic, strong, readwrite) NSArray<NSString*>* sortedBeginTimeKeys;

@property (nonatomic, strong, readwrite) FMLyricLabel* curLineLabel;
@property (nonatomic, assign, readwrite) NSInteger curLine;//歌词逻辑上的第几行


@property (nonatomic, assign, readwrite) BOOL isDraging;
@property (nonatomic, assign, readwrite) CGFloat scrollToTimeMills;

@property (nonatomic, assign, readwrite) LyricType lyricTypeToShow;


@end

@interface FMLyricFullView () < UITableViewDataSource, UITableViewDelegate >

@end

@implementation FMLyricFullView

- (instancetype)initWithFrame:(CGRect)frame{
    
    if(self = [super initWithFrame:frame]){
        
        [self _initTableView];
        [self _initParameters];
        [self _initStanderLineView];
    }
    return self;
}

#pragma -mark 初始化
- (void)_initParameters{
    
    self.lyricIdxToShow = 0;

    self.shouldHightenedByWord = YES;
    
    self.curSentenceFont = [UIFont boldSystemFontOfSize:16];
    self.normalSentenceFont = [UIFont systemFontOfSize:16];
    
    self.highlightedWordsColor = [UIColor greenColor]; //LRC：当前句颜色，QRC：逐字颜色
    self.normalSentenceColor = [UIColor blackColor]; //句子底色
    
    self.spaceBetweenSentence = 16;
    
    self.textAlignment = FMTextAlignmentMiddle;
    
    self.dragFinishDelayTime = 3;
    
    self.isDraging = NO;
    
    self.lyricTypeToShow = self.singleLyricModel.lyricType;
    
}

- (void)_initTableView{
    
    _tableView = [[UITableView alloc] initWithFrame:self.bounds];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.alpha = 1.0;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.showsHorizontalScrollIndicator = NO;
    
    _tableView.allowsSelection = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [_tableView registerClass:[FMLyricCell class] forCellReuseIdentifier:[FMLyricCell identifier]];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self addSubview:_tableView];
}

- (void)_initStanderLineView{
    self.standerLineView = [[UIView alloc] init];
    self.standerLineView.backgroundColor = self.backgroundColor;
    self.standerLineView.alpha = self.alpha;
    self.standerLineView.frame = CGRectMake(0, self.tableView.bounds.size.height / 2 - kStanderLineHeight / 2, self.tableView.bounds.size.width, kStanderLineHeight);
    [self addSubview:self.standerLineView];
    
    UILabel* leftTimeLabel = [[UILabel alloc] init];
    leftTimeLabel.tag = kStanderLineLeftTimeLabelTag;
    leftTimeLabel.textColor = [UIColor blackColor];
    leftTimeLabel.font = [UIFont systemFontOfSize:12];
    leftTimeLabel.frame = CGRectMake(10, 0, 0, 0);
    [self.standerLineView addSubview:leftTimeLabel];
    
    UIButton* rightPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightPlayBtn.tag = kStanderLineRightPlayBtnTag;
    [rightPlayBtn addTarget:self action:@selector(standerLineRightPlayBtnPressAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightPlayBtn setImage:[UIImage imageNamed:@"icon_standerLineView_rightPlay"] forState:UIControlStateNormal];
    rightPlayBtn.contentMode = UIViewContentModeScaleAspectFit;
    rightPlayBtn.frame = CGRectMake(self.standerLineView.bounds.size.width - 20 , 0, 20, 20);
    [self.standerLineView addSubview:rightPlayBtn];
    
    self.standerLineView.hidden = YES;
    
}

- (NSArray<NSString *> *)sortedBeginTimeKeys{
    if(!_sortedBeginTimeKeys){
        NSArray<NSString*>* allBeginTimeStamp = [self.singleLyricModel.sentencseDict.allKeys copy];
        allBeginTimeStamp = [allBeginTimeStamp sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
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

#pragma -mark 加载接口
- (void)loadLyricAtPath:(NSString *)lyricPath translateLyricAtPath:(NSString *)translateLyricPath{
    
    [self loadLyricAtPath:lyricPath translateLyricAtPath:translateLyricPath lyricFileType:FMLyricFileTypeAuto];
}

- (void)loadLyricContent:(NSString *)lyricContent translateLyricContent:(NSString *)translateLyricContent{
    [self loadLyricContent:lyricContent translateLyricContent:translateLyricContent lyricFileType:FMLyricFileTypeAuto];
}


- (void)loadLyricAtPath:(NSString *)lyricPath translateLyricAtPath:(NSString *)translateLyricPath lyricFileType:(FMLyricFileType)lyricFileType{
    self.lyricFileModel = [[FMLyricFileModel alloc] initWithLyricFilePath:lyricPath type:lyricFileType];
    [self.tableView reloadData];
}


- (void)loadLyricContent:(NSString *)lyricContent translateLyricContent:(NSString *)translateLyricContent lyricFileType:(FMLyricFileType)lyricFileType{
    self.lyricFileModel = [[FMLyricFileModel alloc] initWithLyricContent:lyricContent type:lyricFileType];
    [self.tableView reloadData];
}

#pragma -mark 参数设置接口

- (void)setLyricIdxToShow:(NSUInteger)idx{
    _lyricIdxToShow = idx;
}

- (void)setHighlightedWordsColor:(UIColor *)highlightedWordsColor
             normalSentenceColor:(UIColor *)normalSentenceColor{
    _highlightedWordsColor = highlightedWordsColor;
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

- (void)setShouldHilightenedByWord:(BOOL)shouldHightenedByWord{
    _shouldHightenedByWord = shouldHightenedByWord;
}


- (void)setDragable:(BOOL)dragable{
    [self.tableView setScrollEnabled:dragable];
}

- (void)setStanderLineView:(UIView *)standerLineView{
    
    if(_standerLineView){
        [_standerLineView removeFromSuperview];
    }
    _standerLineView = standerLineView;
    [self addSubview:_standerLineView];
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

- (LyricType)lyricTypeToShow{
    return self.singleLyricModel.lyricType;
}

#pragma -mark stop和resume
//这两个函数play和pause 有Bug：拖动滑块会跳过某一行，过一段时间直接跳到下一行逐字了
- (void)resumeAnimation{
    NSLog(@"点击了开始，从暂停位置开始逐字滚动");
    [self.curLineLabel resumeAnimation];
}

- (void)pauseAnimation{
    NSLog(@"点击了暂停,当前逐字将停止");
    [self.curLineLabel pauseAnimation];
}

#pragma -mark 刷新接口
- (void)repaintWithProgressTime:(double)progressTime{
    //millProgressTime:毫秒;
    if(progressTime < 0){
        NSLog(@"参数progressTime[%f]有误",progressTime);
        return;
    }
    
    if(self.lyricTypeToShow == LyricType_UnKnow){
        NSLog(@"歌词类型未知，无法显示");
        return;
    }
    
    //progressTime = (floorf(progressTime * 1000 + 0.05)) / 1000;
    NSInteger millProgressTime = (NSInteger) (progressTime * kMillSceondsPerSecond);
    
    NSInteger curLine;
    NSInteger curColumn;
    BOOL isLastColumn = NO;
    
    NSString* matchedBeginTimeKey = [self _getCurSentenceTimeStampWithPregressTime:millProgressTime curLine:&curLine curColumn:&curColumn isLastColumn:&isLastColumn];
    
    if(matchedBeginTimeKey.length <= 0 || curLine < 0){
        NSLog(@"第一句还未开始");
        return;
    }
    
    if(curColumn < 0 && self.lyricTypeToShow == LyricType_QRC){
        NSLog(@"第一列还未开始");
        return;
    }
    
    NSInteger rowInModel = curLine;
    NSInteger rowInView = rowInModel + 1;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowInView inSection:0];
    UITableViewCell* curCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if(![curCell isKindOfClass:[FMLyricCell class]]){
        return;
    }
    FMLyricCell* lyricCell = (FMLyricCell*)curCell;
    
    FMLyricLabel* lineLabel = lyricCell.label;
    
    self.curLineLabel = lineLabel;//当前高亮Label
    self.curLine = curLine;
    
    BOOL stillInSameLine = [lastUpdateedSentenceBeginTimeKey isEqualToString:matchedBeginTimeKey];
    
    [self _resetPanelSentenceColor];
    
    if(stillInSameLine){
        if(curColumn >= 0){
            NSLog(@"同一行内，当前行：curLine:%zd,当前列：%zd,text:%@,word:%@",curLine,curColumn,[lineLabel text],[[lineLabel text] substringWithRange:NSMakeRange(curColumn, 1)]);
        }
        //同一行内：打开 关闭 打开 关闭 循环测试
        if(self.lyricTypeToShow == LyricType_QRC){
            if(self.shouldHightenedByWord){
                //在本行逐字开关依然打开
                if(![lineLabel isOpenedAnimation]){
                    //本行上没有动画，中间时点击了逐字开关，从curColumn位置开始动画
                    [self _startLineLabelAnimation:lineLabel fromColumn:curColumn withMatchedBeginTimeKey:matchedBeginTimeKey isLastColumn:isLastColumn];
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
        }
    }else{
        NSLog(@"到下一行了,当前行是：curLine:%zd,text:%@,frame=%@",curLine,[lineLabel text],NSStringFromCGRect(lineLabel.frame));
        //NSLog(@"FullView.frame=%@,scrollView.frame=%@",NSStringFromCGRect(self.frame),NSStringFromCGRect(self.lyricScrollView.frame));
        if(self.lyricTypeToShow == LyricType_QRC){
            if(self.shouldHightenedByWord){
                //本行开始时打开了逐字开关
                if(![lineLabel isOpenedAnimation]){
                    [self _startLineLabelAnimation:lineLabel fromColumn:0 withMatchedBeginTimeKey:matchedBeginTimeKey isLastColumn:isLastColumn];
                }
            }else{
                //本行开始时未打开逐字开关
            }
        }
        
        lastUpdateedSentenceBeginTimeKey = matchedBeginTimeKey;
        if(!self.isDraging){ //在拖动时不要强制滑动
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
}

//公用动画函数
- (void)_startLineLabelAnimation:(FMLyricLabel*)lineLabel fromColumn:(NSInteger)fromColumn withMatchedBeginTimeKey:(NSString*)matchedBeginTimeKey isLastColumn:(BOOL)isLastColumn{
    
    if(fromColumn < 0){
        NSLog(@"fromColumn必须为非负值");
        return;
    }
    
    if(self.lyricTypeToShow == LyricType_LRC || self.lyricTypeToShow == LyricType_UnKnow){
        return; //LRC或者Unknow类型歌词无法逐字控制
    }
    
    if (isLastColumn) {
        if(self.shouldHightenedByWord){
            [self _resetPanelSentenceColor];
        }
        NSLog(@"最后一列，移除动画");
        [lineLabel removeAnimation];
        return;
    }
    
    NSMutableArray<NSNumber *>* timesArr = [NSMutableArray array];
    NSMutableArray<NSNumber *> *locationArr = [NSMutableArray array];
    CGFloat leftDutation = 0;//当前字到句末的剩余时间
    
    //timesAbsoluteArr 字开始时间数组  0  23  984  983
    //locationPercentArr 对应位置     0  0.2  0.8  1.0 每个字的持续时间／总持续时间
    FMLyricSentenceModel* curSentenceModel = [self.singleLyricModel.sentencseDict objectForKey:matchedBeginTimeKey];
    NSArray<FMLyricWordModel*>* curWordModels = [curSentenceModel sortedRelativeWordModelsByBeginTime];//重写wordModels保证按照beginTime排序
    
    //整个句子总时间
    CGFloat allWordsDuration = curSentenceModel.allWordsDuration;
    allWordsDuration = allWordsDuration / kMillSceondsPerSecond;
    
    //句子某个字开始时间
    
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
    
    [lineLabel startAnimationWithTimesAbsoluteArr:timesArr locationPercentArr:locationArr duration:leftDutation];
    
    if(fromColumn == 0){
        NSLog(@"你是从本行开始就开启了动画");
    }else{
        NSLog(@"你是从本行中间位置开启的动画");
    }
}

- (void)_resetPanelSentenceColor{
    
    NSLog(@"准备刷新颜色：第%zd行，text：%@",self.curLine,[self.curLineLabel text]);
    
    NSArray<FMLyricCell*>* visiableCells = self.tableView.visibleCells;
    for (UITableViewCell* cell in visiableCells) {
        if(![cell isKindOfClass:[FMLyricCell class]]){
            continue;
        }
        FMLyricCell* lyricCell = (FMLyricCell*)cell;
        FMLyricLabel* label =  lyricCell.label;
        if (label == self.curLineLabel) {
            if(self.lyricTypeToShow == LyricType_QRC){
                //highlightedWordsColor;//LRC：当前句颜色，QRC：开启逐字（逐字颜色），开启逐行（逐行颜色）
                if(self.shouldHightenedByWord){
                    [label setTextColor:self.normalSentenceColor maskColor:self.highlightedWordsColor];
                }else{
                    [label setTextColor:self.highlightedWordsColor maskColor:self.highlightedWordsColor];
                }
                
            }else{
                [label setTextColor:self.highlightedWordsColor maskColor:self.highlightedWordsColor]; //LRC下maskLabel不显示，设置第二参数无用
            }
        }else{
            [label setTextColor:self.normalSentenceColor maskColor:self.highlightedWordsColor];
            if(self.lyricTypeToShow == LyricType_QRC && [label isOpenedAnimation]){
                [label removeAnimation]; ////不是高亮行的行，如果有动画，则动画移除，再变色
            }
        }
    }
}

- (NSString*)_getCurSentenceTimeStampWithPregressTime:(NSInteger)millProgressTime curLine:(NSInteger *)curLine curColumn:(NSInteger*)curColumn isLastColumn:(BOOL*)isLastColumn{
    //pregressTime:毫秒  return：毫秒
    NSString* mattchedBeginTimeKey;
    
    NSUInteger count = _sortedBeginTimeKeys.count;
    NSInteger expLineIdx = -1;
    NSInteger expColumnIdx = -1;
    
    for (NSUInteger i = 0; i < count; i++) {
        if(ABS(millProgressTime - [_sortedBeginTimeKeys[i] intValue]) < 100){
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
        
        if(self.lyricTypeToShow == LyricType_QRC){
            
            FMSingleLyricModel* singleLyricModel =  [self.lyricFileModel getSingleLyricModelWithIndex:_lyricIdxToShow];
            FMLyricSentenceModel* curSentenceModel = singleLyricModel.sentencseDict[mattchedBeginTimeKey];
            
            *isLastColumn = NO;
            NSArray<FMLyricWordModel*>* sortedWordModels = [curSentenceModel sortedAbsoluteWordModelsByBeginTime];
            for (int i = 0; i < sortedWordModels.count; i++) {
                if(ABS(millProgressTime - sortedWordModels[i].beginTime) < 100){
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
            *curColumn = -1;
        }
    }else{
        mattchedBeginTimeKey = nil;
        *curColumn = -1;
    }
    
    return mattchedBeginTimeKey;
}

#pragma -mark TableVewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.sortedBeginTimeKeys.count + 2;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSInteger rowInView = indexPath.row;
    
    UITableViewCell* cell;
    
    if(rowInView == 0 || (rowInView == self.sortedBeginTimeKeys.count + 1)){
        cell = [[UITableViewCell alloc] init];
    }else{
        
        cell = [tableView dequeueReusableCellWithIdentifier:[FMLyricCell identifier]];
        NSInteger rowInModel = rowInView - 1;
        [self configCell:(FMLyricCell*)cell Inrow:rowInModel];
    }
    
    return cell;
}

- (void)configCell:(FMLyricCell*)cell Inrow:(NSInteger)rowInModel{
    
    if(rowInModel < 0 || rowInModel >= self.sortedBeginTimeKeys.count){
        return;
    }
    
    [cell.label setLineBreakEnable:YES];
    
    switch (self.textAlignment) {
        case FMTextAlignmentLeft:
            [cell.label setTextAlignment:NSTextAlignmentLeft];
            break;
        case FMTextAlignmentMiddle:
            [cell.label setTextAlignment:NSTextAlignmentCenter];
            break;
        case FMTextAlignmentRight:
            [cell.label setTextAlignment:NSTextAlignmentRight];
            break;
        default:
            [cell.label setTextAlignment:NSTextAlignmentCenter];
            break;
    }
    
    [cell.label setTextColor:self.normalSentenceColor maskColor:self.normalSentenceColor];
    [cell.label setFont:self.normalSentenceFont];
    
    [cell.label removeAnimation];//cell重用问题fix
    
    NSString* key = self.sortedBeginTimeKeys[rowInModel];
    [cell.label setText:self.singleLyricModel.sentencseDict[key].sentence];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger rowInView = indexPath.row;
    if(rowInView == 0 || (rowInView == self.sortedBeginTimeKeys.count + 1)){
        return self.tableView.bounds.size.height / 2 - 22;
    }
    return 44;
}

#pragma - mark UIScrollViewDelegate
//刷新下一行时会自动滚到当前行，当滑动面板结束三秒后回到当前行
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_scrollToCurrentSentence) object:nil];
    
    self.isDraging = YES;
    
    NSLog(@"拖动了歌词面板，");
    self.standerLineView.hidden = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    NSLog(@"ScrollView正在滚动,offsetY:%f",scrollView.contentOffset.y);
    
    UILabel* leftTimeLabel = (UILabel*)[self.standerLineView viewWithTag:kStanderLineLeftTimeLabelTag];
    
    NSInteger curRowInView =  [self _getcurLineNumWhenScrollTo:scrollView.contentOffset.y];/*滚动过程中，歌词面板中间位置是哪一行*/
    NSLog(@"Scroll:curRowInView=%zd",curRowInView);
    NSInteger rowInModel = curRowInView - 1;
    if(rowInModel < 0){
        rowInModel = 0;
    }
    if(rowInModel >= self.sortedBeginTimeKeys.count){
        rowInModel = self.sortedBeginTimeKeys.count - 1;
    }
    NSInteger scrollToTimeMills = [_sortedBeginTimeKeys[rowInModel] intValue];//毫秒
    self.scrollToTimeMills = scrollToTimeMills;
    
    NSInteger minutes = scrollToTimeMills / kMillSceondsPerSecond / kSecondsPerMinute;
    NSInteger seconds = scrollToTimeMills / (int)kMillSceondsPerSecond % (int)kSecondsPerMinute;
    NSString* timeText = [NSString stringWithFormat:@"%02zd:%02zd",minutes, seconds];
    leftTimeLabel.text = timeText;
    [leftTimeLabel sizeToFit];
    
    //[self _resetPanelSentenceColor]; //解决Cell重用导致高亮颜色消失问题
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if(!decelerate){//生硬拖动，没有减速过程
        [self performSelector:@selector(_scrollToCurrentSentence) withObject:nil afterDelay:self.dragFinishDelayTime];
        //self.isDraging = NO;
        NSLog(@"Scroll:scrollViewDidEndDragging");
    }
}
//在一次拖动减速过程未结束再次拖动时不会调用，只会在彻底拖动结束后才会调用
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    //self.isDraging = NO;
    [self performSelector:@selector(_scrollToCurrentSentence) withObject:nil afterDelay:self.dragFinishDelayTime];
    NSLog(@"Scroll:scrollViewDidEndDecelerating");
}

#pragma -mark StanderView 右侧按钮事件
- (void)standerLineRightPlayBtnPressAction:(UIButton*)sender{
    CGFloat scrollToTimeSecond = self.scrollToTimeMills / kMillSceondsPerSecond;
    [self repaintWithProgressTime:scrollToTimeSecond];
    NSLog(@"传给播放器的参数：%f",scrollToTimeSecond);
    if([self.delegate conformsToProtocol:@protocol(FMLyricViewDelegate)] &&
       [self.delegate respondsToSelector:@selector(lyricView:didEndDraggingToProgress:)]){
        [self.delegate lyricView:self didEndDraggingToProgress:scrollToTimeSecond];
    }
}

- (void)_scrollToCurrentSentence{
    
    NSLog(@"拖动结束，返回当前行：%zd",self.curLine);
    self.isDraging = NO;
    self.standerLineView.hidden = YES;
    
    NSInteger rowInView = self.curLine + 1;
    
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowInView inSection:0];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (NSInteger)_getcurLineNumWhenScrollTo:(CGFloat)scrollOffsetY{
    
    CGRect rect = CGRectMake(0, self.tableView.bounds.size.height / 2 + scrollOffsetY, self.tableView.bounds.size.width, 1);
    
    NSArray<NSIndexPath*>* indexPathArr = [self.tableView indexPathsForRowsInRect:rect];
    
    NSInteger rowInView = indexPathArr.firstObject.row;
    
    return rowInView;
}

@end
