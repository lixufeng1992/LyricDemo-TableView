//
//  FMLyricLabel.m
//  LyricDemo
//
//  Created by lixufeng on 16/9/23.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "FMLyricLabel.h"
#import "FMLyricViewConst.h"

#define kLyrcisAnimationKey @"kLyrcisAnimationKey"
#define kLyricAnimationPropertyKey @"bounds.size.width"

@interface FMLyricLabel ()

@property (nonatomic, strong, readwrite) UILabel* textLabel;
@property (nonatomic, strong, readwrite) UILabel* maskLabel;

@property (nonatomic, strong, readwrite) CALayer* maskLayer;

//当前行是高亮行
@property (nonatomic, assign, readwrite) BOOL shouldHightenedByWord;
@property (nonatomic, strong, readwrite) UIColor* highlightedWordColor;
@property (nonatomic, strong, readwrite) UIColor* curSentenceColor;
@property (nonatomic, strong, readwrite) UIColor* normalSentenceColor;

@property (nonatomic, strong, readwrite) UIFont* highlightenedSentenceFont;
@property (nonatomic, strong, readwrite) UIFont* normalSentenceFont;

@property (nonatomic, assign, readwrite) NSTextAlignment textAlignment;

@property (nonatomic, assign, readwrite) CGFloat lyricDispalayWidth;

@property (nonatomic, assign, readwrite) BOOL isOpenedAnimation;

@end

@implementation FMLyricLabel

- (instancetype)init{
    if(self = [self initWithFrame:CGRectZero]){
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    
    if(self = [super initWithFrame:frame]){
        [self addSubview:self.textLabel];
        [self addSubview:self.maskLabel];
        [self setupDefault];
    }
    return self;
    
}

- (void)setupDefault {
    
    self.highlightedWordColor = [UIColor greenColor]; //逐字颜色默认未绿色
    self.curSentenceColor = [UIColor blueColor]; //逐句颜色默认未蓝色
    self.normalSentenceColor = [UIColor whiteColor]; //其它句子颜色默认未白色
    
    self.highlightenedSentenceFont = [UIFont boldSystemFontOfSize:16.0f];
    self.normalSentenceFont = [UIFont boldSystemFontOfSize:15];
    
    self.textAlignment = NSTextAlignmentCenter;
    
    self.textLabel.textColor = _normalSentenceColor;
    self.textLabel.font = _normalSentenceFont;
    self.textLabel.textAlignment = _textAlignment;
    
    self.maskLabel.textColor = _normalSentenceColor;
    self.maskLabel.font = _normalSentenceFont;
    self.maskLabel.textAlignment = _textAlignment;
    
    self.isOpenedAnimation = NO;
    self.shouldHightenedByWord = NO;
    
    CALayer *maskLayer = [CALayer layer];
    maskLayer.anchorPoint = CGPointMake(0, 0.5);
    maskLayer.position = CGPointMake(0, CGRectGetHeight(self.bounds) / 2);
    maskLayer.bounds = CGRectMake(0, 0, 0, CGRectGetHeight(self.bounds));
    maskLayer.backgroundColor = [UIColor whiteColor].CGColor;
    self.maskLabel.layer.mask = maskLayer;
    self.maskLayer = maskLayer;
    
}

- (void)setTextColor:(UIColor*)textColor maskColor:(UIColor*)maskColor{
    _textLabel.textColor = textColor;
    _maskLabel.textColor = maskColor;
}

- (void)setHighlightedWordColor:(UIColor *)highlightedWordColor
               curSentenceColor:(UIColor *)curSentenceColor
     normalSentenceColor:(UIColor *)normalSentenceColor{
    
    _highlightedWordColor = highlightedWordColor;
    _curSentenceColor = curSentenceColor;
    _normalSentenceColor = normalSentenceColor;
    
    _maskLabel.textColor = _highlightedWordColor;
    if(self.shouldHightenedByWord){
        _textLabel.textColor = _normalSentenceColor;;
    }else{
        _textLabel.textColor = _curSentenceColor;
    }
}

- (void)setShouldHilightenedByWord:(BOOL)shouldHightenedByWord{
    _shouldHightenedByWord = shouldHightenedByWord;
}

- (void)setLineBreakEnable:(BOOL)enable{
    if(enable){
        self.textLabel.numberOfLines = 0;
        self.maskLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.maskLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }else{
        self.textLabel.numberOfLines = 1;
        self.maskLabel.numberOfLines = 1;
    }
}

- (void)setText:(NSString*)text{
    self.textLabel.text = text;
    self.maskLabel.text = text;
}


- (void)setFrame:(CGRect)frame{
    super.frame = frame;
    self.textLabel.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.maskLabel.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}

- (NSString*)text{
    return self.textLabel.text;
}

- (void)setHighlitenedFont:(UIFont*)hightenedFont normalFont:(UIFont*)normalFont{
    
    _highlightenedSentenceFont = hightenedFont;
    _normalSentenceFont = normalFont;
    
    self.textLabel.font = _highlightenedSentenceFont;
    self.maskLabel.font = _normalSentenceFont;
}

- (UIFont*)font{
    return self.textLabel.font;
}

- (CGSize)textSizeWithWidthLimit{
    NSDictionary *attribute = @{NSFontAttributeName:self.font};
    CGSize textSize = [self.text boundingRectWithSize:CGSizeMake(self.lyricDispalayWidth, 0) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
    return textSize;
}

- (CGSize)textSizeWithHeightLimit{
    NSDictionary *attribute = @{NSFontAttributeName:self.font};
    CGSize textSize = [self.text boundingRectWithSize:CGSizeMake(0, self.bounds.size.height) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
    return textSize;
}

- (CGSize)wordSizeWithHeightLimit:(NSString*)word{
    NSDictionary *attribute = @{NSFontAttributeName:self.font};
    CGSize wordSize = [word boundingRectWithSize:CGSizeMake(0, self.bounds.size.height) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
    return wordSize;
}

- (void)setLyricDispalayWidth:(CGFloat)lyricDispalayWidth{
    _lyricDispalayWidth = lyricDispalayWidth;
}

- (void)sizeToFit{
    [self.textLabel sizeToFit];
    [self.maskLabel sizeToFit];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment{
    self.textLabel.textAlignment = textAlignment;
    self.maskLabel.textAlignment = textAlignment;
}

//timesAbsoluteArr 字开始时间数组  0  23  984  983
//locationPercentArr 对应位置     0  0.2  0.8  1.0
- (void)startAnimationWithTimesAbsoluteArr:(NSArray<NSNumber*>*)timesAbsoluteArr locationPercentArr:(NSArray<NSNumber*>*)locationPercentArr duration:(CGFloat)duration{
    
    if(self.isOpenedAnimation){
        NSLog(@"本Label已经添加过动画了，不要再冲重复添加");
    }
    
    //self.isOpenedAnimation = NO;
    
    if(timesAbsoluteArr.count != locationPercentArr.count){
        NSLog(@"时间数组和位置数字长度不同，将被截断");
    }
    NSUInteger totalSampleCnt = MIN(timesAbsoluteArr.count, locationPercentArr.count);
    
    CAKeyframeAnimation* keyFrameAnimation = [CAKeyframeAnimation animationWithKeyPath:kLyricAnimationPropertyKey];
    
    NSMutableArray<NSNumber*>* keyTimesArr = [NSMutableArray arrayWithCapacity:totalSampleCnt];
    NSMutableArray<NSNumber*>* valuesArr = [NSMutableArray arrayWithCapacity:totalSampleCnt];
    
    CGFloat originalPointTime = [[timesAbsoluteArr firstObject] floatValue];//原点时间
    for (NSUInteger i = 0; i < totalSampleCnt; i++) {
        
        CGFloat timePersent = ([timesAbsoluteArr[i] floatValue] - originalPointTime) / duration;
        [keyTimesArr addObject:@(timePersent)];
        
        CGFloat valueAbsolute = [locationPercentArr[i] floatValue] * CGRectGetWidth(self.bounds);
        [valuesArr addObject:@(valueAbsolute)];
    }
    
    keyFrameAnimation.keyTimes = keyTimesArr;
    keyFrameAnimation.values = valuesArr;
    
    keyFrameAnimation.duration = duration;
    
    keyFrameAnimation.calculationMode = kCAAnimationLinear;
    keyFrameAnimation.fillMode = kCAFillModeForwards;
    
    keyFrameAnimation.removedOnCompletion = NO;
    
    [self removeAnimation];
    
    [self.maskLayer addAnimation:keyFrameAnimation forKey:kLyrcisAnimationKey];
    
    self.isOpenedAnimation = YES;
    
    NSLog(@"开始动画，传进来的参数：timesAbsoluteArr=%@,locationPercentArr=%@,duration=%f",timesAbsoluteArr,locationPercentArr,duration);
    
    NSLog(@"动画开始，动画参数：keyTimes=%@,values=%@,duration=%f,"
                            "titleLabel.textColor=%@,titleLabel.bgColor=%@,"
                            "maskLabel.textColor=%@,maskLabel.bgColor=%@",
                            keyFrameAnimation.keyTimes,keyFrameAnimation.values,keyFrameAnimation.duration,
                            _textLabel.textColor,_textLabel.backgroundColor,
                            _maskLabel.textColor,_maskLabel.backgroundColor
          
          );
    
    NSLog(@"当前Lable的bounds=%@",NSStringFromCGRect(self.maskLabel.bounds));
}

//当前Label上是否已经添加过动画
- (BOOL)isOpenedAnimation{
    return _isOpenedAnimation;
}

- (void)removeAnimation{
    self.isOpenedAnimation = NO;
    [self.maskLayer removeAllAnimations];
}

//暂停／开始键
- (void)pauseAnimation{
    CFTimeInterval pausedTime = [self.maskLayer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.maskLayer.speed = 0.0;
    self.maskLayer.timeOffset = pausedTime;
}
//暂停／开始键
- (void)resumeAnimation{
    
    CAAnimation* keyFrameAnima = [self.maskLayer animationForKey:kLyrcisAnimationKey];
    if(!keyFrameAnima){
        NSLog(@"当前行无动画，无法断点开始");
        return;
    }
    
    CFTimeInterval pausedTime = [self.maskLayer timeOffset];
    self.maskLayer.speed = 1.0;
    self.maskLayer.timeOffset = 0.0;
    self.maskLayer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [self.maskLayer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.maskLayer.beginTime = timeSincePause;
}

//逐行／逐字键
- (void)showAnimation{
    self.maskLabel.hidden = NO;
    //self.maskLayer.hidden = NO;
}
//逐行／逐字键
- (void)hideAnimation{
    self.maskLabel.hidden = YES;
    //self.maskLayer.hidden = YES;
}

- (UILabel *)textLabel{
    if(!_textLabel){
        _textLabel = [[UILabel alloc] initWithFrame:self.bounds];
    }
    return _textLabel;
}

- (UILabel *)maskLabel{
    if(!_maskLabel){
        _maskLabel = [[UILabel alloc] initWithFrame:self.bounds];
    }
    return _maskLabel;
}


@end
