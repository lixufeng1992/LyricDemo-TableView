//
//  FMSingleLyricModel.h
//  LyricDemo
//
//  Created by lixufeng on 16/9/5.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "FMLyricModelConst.h"

typedef NS_ENUM(NSInteger, LyricType){
    LyricType_UnKnow = -1,
    LyricType_LRC = 0,
    LyricType_QRC = 1,
};


@interface FMLyricWordModel : NSObject <NSCopying>
//字或词
@property (nonatomic, copy, readonly) NSString* word;
//该字或词的开始时间
@property (nonatomic, assign, readonly) NSInteger beginTime;
//该字或词的持续时间
@property (nonatomic, assign, readonly) NSInteger duration;
//字所在的行，从0开始
@property (nonatomic, assign, readonly) NSInteger line;
//字所在行的列序号，从0开始
@property (nonatomic, assign, readonly) NSInteger column;

- (instancetype)initWithWord:(NSString*)word beginTime:(NSInteger)beginTime duration:(NSInteger)duration line:(NSInteger)line column:(NSInteger)column;

@end

@interface FMLyricSentenceModel : NSObject
//句子
@property (nonatomic, copy, readonly) NSString* sentence;
//句子的开始时间
@property (nonatomic, assign, readonly) NSInteger beginTime;
//句子持续时间
@property (nonatomic, assign, readonly) NSInteger duration;
//句子结束时间
@property (nonatomic, assign, readonly) NSInteger endTime;
//句子是第几行，从0开始
@property (nonatomic, assign, readonly) NSInteger line;

@property (nonatomic, strong, readonly) NSArray<FMLyricWordModel*>* relativeWordModels;
@property (nonatomic, strong, readonly) NSArray<FMLyricWordModel*>* absoluteWordModels;
@property (nonatomic, assign, readonly) NSInteger allWordsDuration;

- (instancetype)initWithSentence:(NSString*)sentence beginTime:(NSInteger)beginTime duration:(NSInteger)duration endTime:(NSInteger)endTime line:(NSInteger)line relativeWordModels:(NSArray<FMLyricWordModel*>*)relativeWordModels absoluteWordModels:(NSArray<FMLyricWordModel*>*)absoluteWordModels allWordsDuration:(NSInteger)allWordsDuration;

- (NSArray<FMLyricWordModel*>*)sortedRelativeWordModelsByBeginTime; //得到的relativeWordModels是按照beginTime排序，并且beginTime是相对于本句开始时间的，也就是第一个词的开始时间为0
- (NSArray<FMLyricWordModel*> *)sortedAbsoluteWordModelsByBeginTime; //得到的absoluteWordModels是按照beginTime排序，并且beginTime是绝对开始时间

@end




@interface FMSingleLyricModel : NSObject

//歌词类型（用于QRC格式，QRC可以荷载LRC）
@property (nonatomic, assign, readonly) LyricType lyricType;
@property (nonatomic, copy, readonly) NSString* title; //歌曲标题
@property (nonatomic, copy, readonly) NSString* artist; //演唱者
@property (nonatomic, copy, readonly) NSString* author; //歌词作者
@property (nonatomic, copy, readonly) NSString* album; //专辑
@property (nonatomic, copy, readonly) NSString* creator; //歌词文件创建者
@property (nonatomic, assign, readonly) CGFloat offset; //整体偏移



//针对LRC和QRC格式都可以 3:18.146 --> 198146ms    key：198146   value：FMLyricSentenceMode｛句子，开始时间，持续时间｝
@property (nonatomic, strong) NSMutableDictionary<NSString*, FMLyricSentenceModel*>* sentencseDict;
//只有QRC格式才有值，否则无值  key：198146 value：FMLyricWordModel｛字或词，开始时间，持续时间｝
@property (nonatomic, strong) NSMutableDictionary<NSString*, FMLyricWordModel*>* wordsDict;


- (instancetype)initWithLyritType:(LyricType)lyricType title:(NSString*)title artist:(NSString*)artist album:(NSString*)albun creator:(NSString*)creator offset:(CGFloat)offset;

- (instancetype)initWithLyritType:(LyricType)lyricType title:(NSString*)title artist:(NSString*)artist album:(NSString*)albun creator:(NSString*)creator offset:(CGFloat)offset sentencseDict:(NSMutableDictionary<NSString*, FMLyricSentenceModel*>*)sentencseDict wordsDict:(NSMutableDictionary<NSString*, FMLyricWordModel*>*)wordsDict;

@end
