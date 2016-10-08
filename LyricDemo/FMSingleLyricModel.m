//
//  FMSingleLyricModel.m
//  LyricDemo
//
//  Created by lixufeng on 16/9/5.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "FMSingleLyricModel.h"



@interface FMSingleLyricModel ()

//歌词类型（用于QRC格式，QRC可以荷载LRC）
@property (nonatomic, assign, readwrite) LyricType lyricType;
@property (nonatomic, copy, readwrite) NSString* title; //歌曲标题
@property (nonatomic, copy, readwrite) NSString* artist; //演唱者
@property (nonatomic, copy, readwrite) NSString* author; //歌词作者
@property (nonatomic, copy, readwrite) NSString* album; //专辑
@property (nonatomic, copy, readwrite) NSString* creator; //歌词文件创建者
@property (nonatomic, assign, readwrite) CGFloat offset; //整体偏移



@end

@implementation FMLyricWordModel

- (instancetype)initWithWord:(NSString *)word beginTime:(NSInteger)beginTime duration:(NSInteger)duration line:(NSInteger)line column:(NSInteger)column{
    if(self = [super init]){
        _word = [word copy];
        _beginTime = beginTime;
        _duration = duration;
        _line = line;
        _column = column;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    FMLyricWordModel* newWordModel = [[FMLyricWordModel alloc] initWithWord:_word beginTime:_beginTime duration:_duration line:_line column:_column];
    return newWordModel;
}

@end

@implementation FMLyricSentenceModel

- (instancetype)initWithSentence:(NSString *)sentence beginTime:(NSInteger)beginTime duration:(NSInteger)duration endTime:(NSInteger)endTime line:(NSInteger)line relativeWordModels:(NSArray<FMLyricWordModel *> *)relativeWordModels absoluteWordModels:(NSArray<FMLyricWordModel *> *)absoluteWordModels allWordsDuration:(NSInteger)allWordsDuration{
    if(self = [super init]){
        _sentence = [sentence copy];
        _beginTime = beginTime;
        _duration = duration;
        _endTime = endTime;
        _line = line;
        _relativeWordModels = relativeWordModels;
        _absoluteWordModels = absoluteWordModels;
        _allWordsDuration = allWordsDuration;
    }
    return self;
}

- (NSArray<FMLyricWordModel*> *)sortedRelativeWordModelsByBeginTime{
    
    return [_relativeWordModels sortedArrayUsingComparator:^NSComparisonResult(FMLyricWordModel* first, FMLyricWordModel* second) {
        
        if(first.beginTime > second.beginTime){
            return NSOrderedDescending;
        }else if(first.beginTime < second.beginTime){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
        
    }];
}

- (NSArray<FMLyricWordModel*> *)sortedAbsoluteWordModelsByBeginTime{
    
    return [_absoluteWordModels sortedArrayUsingComparator:^NSComparisonResult(FMLyricWordModel* first, FMLyricWordModel* second) {
        
        if(first.beginTime > second.beginTime){
            return NSOrderedDescending;
        }else if(first.beginTime < second.beginTime){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
        
    }];
}

@end

@implementation FMSingleLyricModel

- (instancetype)initWithLyritType:(LyricType)lyricType title:(NSString*)title artist:(NSString*)artist album:(NSString*)albun creator:(NSString*)creator offset:(CGFloat)offset{
    return [self initWithLyritType:lyricType title:title artist:artist album:albun creator:artist offset:offset sentencseDict:nil wordsDict:nil];
}

- (instancetype)initWithLyritType:(LyricType)lyricType title:(NSString*)title artist:(NSString*)artist album:(NSString*)albun creator:(NSString*)creator offset:(CGFloat)offset sentencseDict:(NSMutableDictionary<NSString*, FMLyricSentenceModel*>*)sentencseDict wordsDict:(NSMutableDictionary<NSString*, FMLyricWordModel*>*)wordsDict{
    if(self = [super init]){
        _lyricType = lyricType;
        _title = [title copy];
        _artist = [artist copy];
        _album = [albun copy];
        _creator = [creator copy];
        _offset = offset;
        _sentencseDict = sentencseDict;
        _wordsDict = wordsDict;
    }
    
    return self;
}

@end

