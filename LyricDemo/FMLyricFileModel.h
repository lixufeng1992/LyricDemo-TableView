//
//  FMLyricFileModel.h
//  LyricDemo
//
//  Created by lixufeng on 16/9/5.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMSingleLyricModel.h"



@interface FMLyricFileModel : NSObject


#pragma -mark 初始化 type＝auto
/**
 *  构造函数
 *
 *  @param path 歌词文件路径
 *
 *  @return LyricModel
 */
- (instancetype)initWithLyricFilePath:(NSString*)path;

/**
 *  构造函数
 *
 *  @param content 歌词字符串
 *
 *  @return LyricMode
 */
- (instancetype)initWithLyricContent:(NSString*)content;


#pragma -mark 初始化 type＝指定
/**
 *  构造函数
 *
 *  @param path 歌词文件路径
 *  @param type 歌词内容类型 @see LyricType
 *
 *  @return LyricModel
 */
- (instancetype)initWithLyricFilePath:(NSString *)path type:(FMLyricFileType)type;

/**
 *  <#Description#>
 *
 *  @param content 歌词字符串
 *  @param type    歌词内容类型 @see LyricType
 *
 *  @return LyricModel
 */
- (instancetype)initWithLyricContent:(NSString *)content type:(FMLyricFileType)type;

/**
 *  根据歌词索引和句子开始时间得到句子模型
 *
 *  @param idx       歌词索引
 *  @param beginTime 开始时间
 *
 *  @return 句子模型
 */
- (FMSingleLyricModel*)getSingleLyricModelWithIndex:(NSInteger)idx;

/**
 *  根据歌词索引和字开始时间得到词模型
 *
 *  @param idx       歌词索引
 *  @param beginTime 开始时间
 *
 *  @return 字或词模型
 */
- (FMLyricWordModel*)getLyricWordModellWithIndex:(NSInteger)idx beginTime:(NSString*)beginTime;

/**
 * 设置长歌词折行处理
 */
- (void)setLongSentenceWrap:(BOOL)shouldLongSentenceWrap;

- (BOOL)shouldLongSentenceWrap;

/**
*  设置折行后，每行的最大字数（只有打开折行开关才有效）
*/
- (void)setMaxWordNumPerLine:(NSUInteger)maxWordNumPerLine;

- (NSUInteger)getMaxWordNumPerLine;

/**
 *  设置是否过滤空行（歌词行只有时间戳，没有对应的句子字符串）
 */
- (void)setFilterEmptyLine:(BOOL)shouldFilterEmptyLine;

- (BOOL)shouldFilterEmptyLine;

@end
