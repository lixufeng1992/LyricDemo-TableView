//
//  FMLyricFileModel.m
//  LyricDemo
//
//  Created by lixufeng on 16/9/5.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "FMLyricFileModel.h"
#import "FMSingleLyricModel.h"
#import "GDataXMLNode.h"

@interface FMLyricFileModel () <NSXMLParserDelegate>

{
    //下列属性单纯是为了方法间参数传递，无其他用处
    NSMutableDictionary<NSString *,FMLyricSentenceModel *> * sentencseDict;
    NSMutableDictionary<NSString *,FMLyricWordModel *> * wordsDict;
    
    NSString* title;
    NSString* artist;
    NSString* by;
    CGFloat offset;
    NSString* album;
    NSString* author;
    
    NSMutableString* metaInfo;
    
}
//歌词文件保存时间
@property (nonatomic, strong, readwrite) NSDate* saveTime;
//歌词文件类型
@property (nonatomic, assign ,readwrite) FMLyricFileType lyricFileType;
//本歌词文件保存的歌词数量
@property (nonatomic, assign, readwrite) NSUInteger lyricCount;

//歌词索引，用于QRC中歌词遍历
@property (nonatomic ,assign, readwrite) NSUInteger lyricIdx;
//从本歌词文件中解析出的所有歌词Model
@property (nonatomic, strong, readwrite) NSMutableArray<FMSingleLyricModel*>* lyricModels;

@property (nonatomic, assign, readwrite) BOOL isXML2ParserTurnOn;

@property (nonatomic, assign, readwrite) BOOL isLRCLyicContentSeparatedByNewLine;

@property (nonatomic, strong, readonly) NSString* QRC_sentencePatternTmp;

@property (nonatomic, strong, readonly) NSString* QRC_wordUnitPatternTmp;

@property (nonatomic, strong, readonly) NSString* LRC_sentencePatternTmp;

@property (nonatomic, strong, readonly) NSString* RC_metaInfoPatternImp;

//全屏歌词是否开启折行处理
@property (nonatomic, assign, readwrite) BOOL shouldLongSentenceWrap;
@property (nonatomic, assign, readwrite) NSUInteger maxWordNumPerLine;

//是否过滤空行（只有时间戳，没有对应的句子字符串）
@property (nonatomic, assign, readwrite) BOOL shouldFilterEmptyLine;

@end



@implementation FMLyricFileModel


//禁止外部调用，用initWithLyricFilePath OR initWithLyricContent
- (instancetype)init{
    self = [super init];
    if (self) {
        _lyricModels = [NSMutableArray array];
        _lyricCount = 0;
        _lyricIdx = 1;
        metaInfo = [NSMutableString string];
        _isXML2ParserTurnOn = YES;
        _isLRCLyicContentSeparatedByNewLine = NO;
        _QRC_sentencePatternTmp = @"\\[\\d+,\\d+\\]";
        _QRC_wordUnitPatternTmp = @"\\(\\d+,\\d+\\)";
        _LRC_sentencePatternTmp = @"\\[\\d+:\\d+\\.\\d+\\]";
        _RC_metaInfoPatternImp = @"\\[\\w+:\\w*\\]";
        
        _shouldLongSentenceWrap = YES;
        _maxWordNumPerLine = 17;
        
        _shouldFilterEmptyLine = NO;
    }
    return self;
}

#pragma mark - 构造函数

- (instancetype)initWithLyricFilePath:(NSString *)path{
    
    return [self initWithLyricFilePath:path type:FMLyricFileTypeAuto];
}

- (instancetype)initWithLyricContent:(NSString *)content{
    return [self initWithLyricContent:content type:FMLyricFileTypeAuto];
}

- (instancetype)initWithLyricFilePath:(NSString *)path type:(FMLyricFileType)type{
    self = [self init];
    if(self){
        _lyricFileType = type;
        [self _setupWithPath:path];
    }
    return self;
}

- (instancetype)initWithLyricContent:(NSString *)content type:(FMLyricFileType)type{
    self = [self init];
    if(self){
        _lyricFileType = type;
        [self _setupWithContent:content];
    }
    return self;
}

#pragma mark - 对外接口

- (void)setLongSentenceWrap:(BOOL)shouldLongSentenceWrap{
    _shouldLongSentenceWrap = shouldLongSentenceWrap;
}

- (BOOL)shouldLongSentenceWrap{
    return _shouldLongSentenceWrap;
}

- (void)setMaxWordNumPerLine:(NSUInteger)maxWordNumPerLine{
    if(!self.shouldLongSentenceWrap){
        NSLog(@"设置了每行最大字数，却没打开折行开关(使用%@)",NSStringFromSelector(@selector(setLongSentenceWrap:)));
    }
    _maxWordNumPerLine = maxWordNumPerLine;
}

- (NSUInteger)getMaxWordNumPerLine{
    return _maxWordNumPerLine;
}

- (void)setFilterEmptyLine:(BOOL)shouldFilterEmptyLine{
    _shouldFilterEmptyLine = shouldFilterEmptyLine;
}

- (BOOL)shouldFilterEmptyLine{
    return _shouldFilterEmptyLine;
}

- (FMSingleLyricModel*)getSingleLyricModelWithIndex:(NSInteger)idx{
    
    if(idx < 0 || idx >= self.lyricCount){
        NSLog(@"解析到歌词数量：%zd,你的idx越界",self.lyricCount);
        return nil;
    }
    FMSingleLyricModel* lyricSingleModel = [self.lyricModels objectAtIndex:idx];
    return lyricSingleModel;
}

- (FMLyricWordModel*)getLyricWordModellWithIndex:(NSInteger)idx beginTime:(NSString*)beginTime{
    
    if(_lyricFileType == FMLyricFileTypeLRC){
        NSLog(@"LRC格式无法提供字词级别的对准精度");
        return nil;
    }
    
    if(idx < 0 || idx >= self.lyricCount){
        NSLog(@"歌词数量：%zd,参数idx越界",self.lyricCount);
        return nil;
    }
    FMSingleLyricModel* lyricSingleModel = [self.lyricModels objectAtIndex:idx];
    FMLyricWordModel* model = [lyricSingleModel.wordsDict objectForKey:beginTime];
    return model;
}

#pragma mark - setup函数

- (void)_setupWithPath:(NSString*)path{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if(![fileManager fileExistsAtPath:path]){
        NSLog(@"歌词文件[%@]不存在",path);
        return;
    }
    if(![fileManager isReadableFileAtPath:path]){
        NSLog(@"歌词文件[%@]不可读",path);
        return;
    }
    NSData* data = [fileManager contentsAtPath:path];
    if(data.length <= 0){
        NSLog(@"歌词文件[%@]内容为空",path);
        return;
    }
    NSString* content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self _setupWithContent:content];
}

- (void)_setupWithContent:(NSString*)fileContent{
    
    if(fileContent.length <= 0){
        NSLog(@"歌词内容为空");
        return;
    }
    switch (_lyricFileType) {
        case FMLyricFileTypeLRC:{
            //LRC格式
            self.isLRCLyicContentSeparatedByNewLine = YES;//LRC文件不会丢失换行符
            [self _parseLRCFileContent:fileContent];
        }
            break;
        case FMLyricFileTypeQRC:{
            //QRC格式,XML解析
            self.isLRCLyicContentSeparatedByNewLine = NO;//QRC文件解析后会丢失换行符
            [self _parseRQCFileContent:fileContent];
        }
        case FMLyricFileTypeAuto:{
            FMLyricFileType mayFileType = [self _getLyricFileTypeFromFileContent:fileContent];
            if(mayFileType == FMLyricFileTypeLRC){
                [self _parseLRCFileContent:fileContent];
            }else if(mayFileType == FMLyricFileTypeQRC){
                [self _parseRQCFileContent:fileContent];
            }else if(mayFileType == FMLyricFileTypeUnKnow){
                NSLog(@"歌词文件类型未识别，请尝试指定类型");
            }else{
                NSLog(@"未知歌词文件类型，请明确指定");
            }
        }
            break;
        default:
            break;
    }
}

//智能解析文件内容
- (FMLyricFileType)_getLyricFileTypeFromFileContent:(NSString*)fileContent{
    
    NSString* lyricFileTypeQRCPatternImpl = @"<\\?\\s*xml*";
    NSString* lyricFileTypeLRCPatternImpl = _LRC_sentencePatternTmp;
    NSRange xmlHeadTagRange = [fileContent rangeOfString:lyricFileTypeQRCPatternImpl options:NSRegularExpressionSearch range:NSMakeRange(0, 100)];
    NSRange lrcHeadRange = [fileContent rangeOfString:lyricFileTypeLRCPatternImpl options:NSRegularExpressionSearch range:NSMakeRange(0, 100)];
    if(xmlHeadTagRange.length > 0){
        _lyricFileType = FMLyricFileTypeQRC;
        NSLog(@"歌词文件类型识别为QRC");
    }else if(lrcHeadRange.length > 0){
        _lyricFileType = FMLyricFileTypeLRC;
        NSLog(@"歌词文件类型识别为LRC");
    }else{
        _lyricFileType = FMLyricFileTypeUnKnow;
        NSLog(@"歌词文件类型未识别");
    }
    return _lyricFileType;
}

#pragma mark - LRC文件解析

- (void)_parseLRCFileContent:(NSString*)fileContent{
    if(fileContent.length <= 0){
        NSLog(@"歌词内容为空");
        return;
    }
    NSString* lyricContent = fileContent;
    FMSingleLyricModel* singleLyricModel = [self _parseLRCLyricContent:lyricContent];
    [self.lyricModels addObject:singleLyricModel];
    self.lyricCount = 1;//LRC目前只支持一个文件保存一首歌曲
}

- (FMSingleLyricModel*)_parseLRCLyricContent:(NSString*)lyricContent{
    
    if(self.isLRCLyicContentSeparatedByNewLine){
        return [self _parseLRCLyricContent_hasNewLine:lyricContent];
    }else{
        NSLog(@"歌词正文已经被过滤掉了换行符");
        return [self _parseLRCLyricContent_nonNewLine:lyricContent];
    }
}

- (FMSingleLyricModel*)_parseLRCLyricContent_hasNewLine:(NSString*)lyricContent{
    
    sentencseDict = [NSMutableDictionary dictionary];
    wordsDict = nil;
    
    NSArray<NSString*>* lines = [lyricContent componentsSeparatedByString:@"\n"];
    NSUInteger curLineIdx = -1;
    for (__strong NSString* line in lines) {
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if([line isEqualToString:@""]){
            continue;
        }
        NSRange metaInfoRange = [line rangeOfString:_RC_metaInfoPatternImp options:NSRegularExpressionSearch];
        if(metaInfoRange.length > 0){
            metaInfo = [[metaInfo  stringByAppendingString:line] mutableCopy];
        }
        curLineIdx++;
        [self _LRC_parseLine:line curLineIdx:curLineIdx];
    }
    FMSingleLyricModel* singleLyricModel = [[FMSingleLyricModel alloc] initWithLyritType:LyricType_LRC title:title artist:artist album:album creator:by offset:offset sentencseDict:sentencseDict wordsDict:nil];
    return singleLyricModel;
}



- (FMSingleLyricModel*)_parseLRCLyricContent_nonNewLine:(NSString*)lyricContent{
    
    sentencseDict = [NSMutableDictionary dictionary];
    wordsDict = nil;
    
    NSRange lineBeginBracketRange = [lyricContent rangeOfString:_LRC_sentencePatternTmp options:NSRegularExpressionSearch];
    
    //元信息
    NSString* metaInfoString;
    if(lineBeginBracketRange.length > 0){
        NSRange remainedTextRange = NSMakeRange(0, lineBeginBracketRange.location);
        metaInfoString = [lyricContent substringWithRange:remainedTextRange];
    }else{
        metaInfoString = lyricContent;
    }
    metaInfo = [[metaInfo  stringByAppendingString:metaInfoString] mutableCopy];
    
    NSUInteger curLineIdx = -1;
    
    while (lineBeginBracketRange.length > 0) {
        
        //已找到第一个[00:07.00]，尝试找下一个
        NSRange leftStrRange = NSMakeRange(lineBeginBracketRange.location + lineBeginBracketRange.length, lyricContent.length - (lineBeginBracketRange.location + lineBeginBracketRange.length));//TODO
        NSRange nextLineBeginBracketRange = [lyricContent rangeOfString:_LRC_sentencePatternTmp options:NSRegularExpressionSearch range:leftStrRange];
        
        if(nextLineBeginBracketRange.length <= 0){
            //已经到最后一行了
            nextLineBeginBracketRange = NSMakeRange(lyricContent.length, 0);
        }
        
        NSRange lineRange = NSMakeRange(lineBeginBracketRange.location, nextLineBeginBracketRange.location - lineBeginBracketRange.location);
        NSString* line = [lyricContent substringWithRange:lineRange];
        //NSLog(@"line:%@",line);
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //解析每行
        curLineIdx++;
        [self _LRC_parseLine:line curLineIdx:curLineIdx];
        
        lineBeginBracketRange = nextLineBeginBracketRange;
    }
    [self _parseMetaInfo];//每创建一首歌词Model前要首先调用，进行元信息分析
    FMSingleLyricModel* singleLyricModel = [[FMSingleLyricModel alloc] initWithLyritType:LyricType_LRC title:title artist:artist album:album creator:by offset:offset sentencseDict:sentencseDict wordsDict:wordsDict];
    [self _clearMetaInfo];
    return singleLyricModel;
}



- (void)_LRC_parseLine:(NSString*)line curLineIdx:(NSUInteger)curLineIdx{
    //[19:38.00]你是火 你是风 你是织网的恶魔
    //NSLog(@"line:%@",line);
    NSRange sentenceBeginTimeRange = [line rangeOfString:_LRC_sentencePatternTmp options:NSRegularExpressionSearch];
    
    //[19:38.00]
    NSString* sentenceBeginTimeBracketText = [line substringWithRange:sentenceBeginTimeRange];
    
    NSString* sentence = [line substringFromIndex:sentenceBeginTimeRange.location + sentenceBeginTimeRange.length];
    
    if(self.shouldFilterEmptyLine){//过滤空行
        if(!sentence || [[sentence stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
            NSLog(@"当前歌词行[%zd]为空行，且开启了过滤空行开关，已经过滤",curLineIdx);
            return;
        }
    }
    
    NSRange sentenceBeginTimeLeftBracketRange = [sentenceBeginTimeBracketText rangeOfString:@"["];
    NSRange sentenceBeginTimeRightBracketRange = [sentenceBeginTimeBracketText rangeOfString:@"]"];
    
    NSRange sentenceBeginTimeTextRange = NSMakeRange(sentenceBeginTimeLeftBracketRange.location + 1, sentenceBeginTimeRightBracketRange.location - sentenceBeginTimeLeftBracketRange.location - 1);
    NSString* sentenceBeginTimeText = [sentenceBeginTimeBracketText substringWithRange:sentenceBeginTimeTextRange];
    
    NSString* sentenceBeginTime = [self _LRC_getTimeStampTextWithTime:sentenceBeginTimeText];
    if([self isDigitString:sentenceBeginTime]){
        FMLyricSentenceModel* sentenceModel = [[FMLyricSentenceModel alloc] initWithSentence:sentence beginTime:[sentenceBeginTime intValue] duration:-1 endTime:0 line:curLineIdx relativeWordModels:nil absoluteWordModels:nil allWordsDuration:-1];
        [sentencseDict setObject:sentenceModel forKey:sentenceBeginTime];
    }else{
        NSLog(@"当前行格式有误，句子开始时间必需是数字，歌词行：%zd",curLineIdx);
    }
    
}

#pragma mark － QRC文件解析

- (void)_parseRQCFileContent:(NSString*)fileContent{
    
    NSLog(@"十首歌词长度：%zd",fileContent.length);
    if(fileContent.length > 10 * 6000){
        //文件内容超过十首歌
        self.isXML2ParserTurnOn = NO;
        NSLog(@"采用NSXMLParser SAX解析");
    }else{
        self.isXML2ParserTurnOn = YES;
        NSLog(@"采用GData Dom解析");
    }
    
    if(self.isXML2ParserTurnOn){
        NSError* errorInParser;
        CFAbsoluteTime begin1 = CFAbsoluteTimeGetCurrent();
        GDataXMLDocument* document = [[GDataXMLDocument alloc] initWithXMLString:fileContent options:0 error:&errorInParser];
        GDataXMLElement* rootElement = document.rootElement; //QrcInfos
        NSString* lyricCount;
        for (GDataXMLElement* element in rootElement.children) {
            //element --> QrcHeadInfo, LyricInfo
            if([element.name isEqualToString:@"QrcHeadInfo"]){
                GDataXMLNode* saveTimeNode = [element attributeForName:@"SaveTime"];
                NSString* saveTime = saveTimeNode.stringValue;
                saveTime = [saveTime stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if([self isDigitString:saveTime]){
                    self.saveTime = [NSDate dateWithTimeIntervalSince1970:[saveTime floatValue]];
                }
            }
            if([element.name isEqualToString:@"LyricInfo"]){
                GDataXMLNode* lyricCountNode = [element attributeForName:@"LyricCount"];
                lyricCount = lyricCountNode.stringValue;
                //NSLog(@"count=%@",lyricCount);
                for (GDataXMLElement* childElement in element.children) {
                    NSString* lyricIdxStr = [NSString stringWithFormat:@"Lyric_%zd",self.lyricIdx];
                    if([childElement.name isEqualToString:lyricIdxStr]){
                        GDataXMLNode* lyricTypeNode = [childElement attributeForName:@"LyricType"];
                        GDataXMLNode* lyricContentNode = [childElement attributeForName:@"LyricContent"];
                        LyricType lyricType = [lyricTypeNode.stringValue intValue];
                        NSString* lyricContent = lyricContentNode.stringValue;
                        //得到单首歌曲信息
                        switch (lyricType) {
                            case LyricType_QRC:{
                                FMSingleLyricModel* singleLyricModel = [self _parseQRCLyricContent:lyricContent lyritType:LyricType_QRC];
                                if(singleLyricModel){
                                    [self.lyricModels addObject:singleLyricModel];
                                }else{
                                    NSLog(@"解析当前歌词文件第%zd首歌词错误，返回模型为空",self.lyricIdx + 1);
                                }
                                self.lyricIdx ++;
                            }
                                break;
                            case LyricType_LRC:{
                                FMSingleLyricModel* singleLyricModel = [self _parseLRCLyricContent:lyricContent];
                                if(singleLyricModel){
                                    [self.lyricModels addObject:singleLyricModel];
                                }else{
                                    NSLog(@"解析当前歌词文件第%zd首歌词错误，返回模型为空",self.lyricIdx + 1);
                                }
                                self.lyricIdx ++;
                            }
                                break;
                                
                            default:{
                                NSLog(@"暂不支持其他格式");
                            }
                                break;
                        }
                    }
                }//end of inner for
                
            }//enf of if
            
        }//enf of outer for
        CFAbsoluteTime end1 = CFAbsoluteTimeGetCurrent();
        NSLog(@"采用libxml2耗时：%f",end1 - begin1);
    }else{
        NSData* data = [fileContent dataUsingEncoding:NSUTF8StringEncoding];
        NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
        self.lyricIdx = 1;
        parser.delegate = self;
        [parser parse];
    }
    self.lyricCount = self.lyricModels.count;
}

- (FMSingleLyricModel*)_parseQRCLyricContent:(NSString*)lyricContent lyritType:(LyricType)lyricType{
    
    sentencseDict = [NSMutableDictionary dictionary];
    wordsDict = [NSMutableDictionary dictionary];
    
    NSRange lineBeginBracketRange = [lyricContent rangeOfString:_QRC_sentencePatternTmp options:NSRegularExpressionSearch];
    
    //元信息
    NSString* metaInfoString;
    if(lineBeginBracketRange.length > 0){
        NSRange remainedTextRange = NSMakeRange(0, lineBeginBracketRange.location);
        metaInfoString = [lyricContent substringWithRange:remainedTextRange];
    }else{
        metaInfoString = lyricContent;
    }
    metaInfo = [[metaInfo stringByAppendingString:metaInfoString] mutableCopy];
    
    NSUInteger curLineIdx = -1;
    while (lineBeginBracketRange.length > 0) {
        
        //已找到第一个[1663,106]，尝试找下一个
        NSRange leftStrRange = NSMakeRange(lineBeginBracketRange.location + lineBeginBracketRange.length, lyricContent.length - (lineBeginBracketRange.location + lineBeginBracketRange.length));//TODO
        NSRange nextLineBeginBracketRange = [lyricContent rangeOfString:_QRC_sentencePatternTmp options:NSRegularExpressionSearch range:leftStrRange];
        
        if(nextLineBeginBracketRange.length <= 0){
            //已经到最后一行了
            nextLineBeginBracketRange = NSMakeRange(lyricContent.length, 0);
        }
        
        NSRange lineRange = NSMakeRange(lineBeginBracketRange.location, nextLineBeginBracketRange.location - lineBeginBracketRange.location);
        NSString* line = [lyricContent substringWithRange:lineRange];
        
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //解析每行
        curLineIdx++;
        [self _QRC_parseLine:line curLineIdx:curLineIdx];
        
        lineBeginBracketRange = nextLineBeginBracketRange;
    }
    [self _parseMetaInfo];
    FMSingleLyricModel* singleLyricModel = [[FMSingleLyricModel alloc] initWithLyritType:lyricType title:title artist:artist album:album creator:by offset:offset sentencseDict:sentencseDict wordsDict:wordsDict];
    [self _clearMetaInfo];
    return singleLyricModel;
}

- (void)_QRC_parseLine:(NSString*)line curLineIdx:(NSUInteger)curLineIdx{
    
    NSRange sentenceBeginTimeAndDurationRange = [line rangeOfString:_QRC_sentencePatternTmp options:NSRegularExpressionSearch];
    
    NSString* sentenceBeginTimeAndDuration = [line substringWithRange:sentenceBeginTimeAndDurationRange];
    
    NSRange sentenceTimeLeftBracketRange = [sentenceBeginTimeAndDuration rangeOfString:@"["];
    NSRange sentenceTimeRightBracketRange = [sentenceBeginTimeAndDuration rangeOfString:@"]"];
    NSRange sentenceTimeCommaRange = [sentenceBeginTimeAndDuration rangeOfString:@","];
    
    NSRange sentenceBeginTimeRange = NSMakeRange(sentenceTimeLeftBracketRange.location + 1, sentenceTimeCommaRange.location - sentenceTimeLeftBracketRange.location - 1);
    NSString* sentenceBeginTime = [sentenceBeginTimeAndDuration substringWithRange:sentenceBeginTimeRange];
    
    NSRange sentenceDurationRange = NSMakeRange(sentenceTimeCommaRange.location + 1, sentenceTimeRightBracketRange.location - sentenceTimeCommaRange.location - 1);
    NSString* sentenceDuration = [sentenceBeginTimeAndDuration substringWithRange:sentenceDurationRange];
    
    NSMutableString* sentence = [[NSMutableString alloc] initWithCapacity:12];
    
    line = [line substringFromIndex:sentenceBeginTimeAndDurationRange.location + sentenceBeginTimeAndDurationRange.length];
    
    NSRange wordPrevBracketRange = NSMakeRange(0, 0);
    NSRange wordCurBracketRange = [line rangeOfString:_QRC_wordUnitPatternTmp options:NSRegularExpressionSearch];
    
    NSUInteger curColumnIdx = -1;
    
    NSMutableArray<FMLyricWordModel*>* relativeWordModels = [NSMutableArray array];
    NSMutableArray<FMLyricWordModel*>* absoluteWordModels = [NSMutableArray array];
    NSInteger allWordsDuration = 0;
    while (wordCurBracketRange.length > 0) {
        NSRange wordRange = NSMakeRange(wordPrevBracketRange.location + wordPrevBracketRange.length, wordCurBracketRange.location + wordCurBracketRange.length - (wordPrevBracketRange.location + wordPrevBracketRange.length));
        NSString* wordUnit = [line substringWithRange:wordRange];
        wordUnit = [wordUnit stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //得到了wordUnit--> 一(250,534)
        
        NSRange wordBeginTimeAndDurationRange = [wordUnit rangeOfString:_QRC_wordUnitPatternTmp options:NSRegularExpressionSearch];
        //wordBeginTimeAndDuration --> (250,534)
        NSString* wordBeginTimeAndDuration = [wordUnit substringWithRange:wordBeginTimeAndDurationRange];
        
        NSRange wordTimeleftBracketRange = [wordBeginTimeAndDuration rangeOfString:@"("];
        NSRange wordTImeRightBracketRange = [wordBeginTimeAndDuration rangeOfString:@")"];
        NSRange wordTimeCommaRange = [wordBeginTimeAndDuration rangeOfString:@","];
        
        NSRange wordBeginTimeRange = NSMakeRange(wordTimeleftBracketRange.location + 1, wordTimeCommaRange.location - wordTimeleftBracketRange.location - 1);
        NSString* wordBeginTime = [wordBeginTimeAndDuration substringWithRange:wordBeginTimeRange];
        wordBeginTime = [wordBeginTime stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSRange wordDurationRange = NSMakeRange(wordTimeCommaRange.location + 1, wordTImeRightBracketRange.location - wordTimeCommaRange.location - 1);
        NSString* wordDuration = [wordBeginTimeAndDuration substringWithRange:wordDurationRange];
        wordDuration = [wordDuration stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSString* word = [wordUnit substringToIndex:wordBeginTimeAndDurationRange.location];
        
        if([self isDigitString:wordBeginTime] && [self isDigitString:wordDuration]){
            curColumnIdx++;
            FMLyricWordModel* wordModel = [[FMLyricWordModel alloc] initWithWord:word beginTime:[wordBeginTime intValue] duration:[wordDuration intValue] line:curLineIdx column:curColumnIdx];
            [wordsDict setObject:wordModel forKey:wordBeginTime];
            
            FMLyricWordModel* newWordModel = [[FMLyricWordModel alloc] initWithWord:word beginTime:[wordBeginTime intValue] - [sentenceBeginTime floatValue] duration:[wordDuration intValue] line:curLineIdx column:curColumnIdx];
            [relativeWordModels addObject:newWordModel];
            [absoluteWordModels addObject:wordModel];
            
            allWordsDuration += [wordDuration intValue];
            
        }else{
            NSLog(@"存在非法时间符号，当前行：%@，当前词%@",line,word);
        }
        [sentence appendString:word];
        
        wordPrevBracketRange = wordCurBracketRange;
        wordCurBracketRange = [line rangeOfString:_QRC_wordUnitPatternTmp options:NSRegularExpressionSearch range:NSMakeRange(wordCurBracketRange.location + wordCurBracketRange.length, line.length - (wordCurBracketRange.location + wordCurBracketRange.length))];
    }
    
    NSString* lineRemainedText = [line substringFromIndex:wordPrevBracketRange.location + wordPrevBracketRange.length];
    metaInfo = [[metaInfo stringByAppendingString:lineRemainedText] mutableCopy];
    NSLog(@"sentence:%@,beginTime:%@,duration:%@",sentence,sentenceBeginTime,sentenceDuration);
    if([self isDigitString:sentenceBeginTime] && [self isDigitString:sentenceDuration]){
        NSInteger sentenceEndTime = [sentenceBeginTime intValue] + [sentenceDuration intValue];
        
        FMLyricSentenceModel* sentenceModel = [[FMLyricSentenceModel alloc] initWithSentence:sentence beginTime:[sentenceBeginTime intValue] duration:[sentenceDuration intValue] endTime:sentenceEndTime line:curLineIdx relativeWordModels:relativeWordModels absoluteWordModels:absoluteWordModels allWordsDuration:allWordsDuration];
        
        
        if(self.shouldLongSentenceWrap && (sentenceModel.absoluteWordModels.count > self.maxWordNumPerLine)){  //35
            //单行歌词字数超过17，开始折行处理
            NSLog(@"单行歌词字数超过17，开始折行处理［%@］",sentenceModel.sentence);
            
            NSInteger lineWrapNum = sentenceModel.absoluteWordModels.count / self.maxWordNumPerLine + 1;  //3
            NSInteger wordNumPerWrapLine = sentenceModel.absoluteWordModels.count / lineWrapNum;  //11,最后一行:35-11*2
            NSInteger wordNumForLastWrapLine = sentenceModel.absoluteWordModels.count - wordNumPerWrapLine * (lineWrapNum - 1);
            
            NSArray<FMLyricWordModel*>* sentenceSortedAbsoWordModels = sentenceModel.sortedAbsoluteWordModelsByBeginTime;
            NSArray<FMLyricWordModel*>* sentenceSortedRelaWordModels = sentenceModel.sortedRelativeWordModelsByBeginTime;
            
            for (NSUInteger i = 0; i < lineWrapNum; i++) {
                
                NSArray<FMLyricWordModel*>* wrapSentenceAbsoWordModels;
                NSArray<FMLyricWordModel*>* wrapSentenceRelaWordModels;
                
                if(i != (lineWrapNum - 1)){
                    wrapSentenceAbsoWordModels = [sentenceSortedAbsoWordModels subarrayWithRange:NSMakeRange(i * wordNumPerWrapLine, wordNumPerWrapLine)];
                    wrapSentenceRelaWordModels = [sentenceSortedRelaWordModels subarrayWithRange:NSMakeRange(i * wordNumPerWrapLine, wordNumPerWrapLine)];
                }else{
                    //最后一行
                    wrapSentenceAbsoWordModels = [sentenceSortedAbsoWordModels subarrayWithRange:NSMakeRange(i * wordNumPerWrapLine, wordNumForLastWrapLine)];
                    wrapSentenceRelaWordModels = [sentenceSortedRelaWordModels subarrayWithRange:NSMakeRange(i * wordNumPerWrapLine, wordNumForLastWrapLine)];
                }
                
                NSInteger wrapSentenceBeginTime = wrapSentenceAbsoWordModels.firstObject.beginTime;
                NSInteger wrapSentenceEndTime = wrapSentenceAbsoWordModels.lastObject.beginTime + wrapSentenceAbsoWordModels.lastObject.duration;
                NSMutableString* wrapSentence = [NSMutableString string];
                NSInteger allWrapWordDuration = 0;
                for (NSUInteger j = 0; j < wrapSentenceAbsoWordModels.count; j++) {
                    [wrapSentence appendString:wrapSentenceAbsoWordModels[j].word];
                    
                    allWrapWordDuration += wrapSentenceAbsoWordModels[j].duration;
                }
                
                FMLyricSentenceModel* wrapSentenceModel = [[FMLyricSentenceModel alloc] initWithSentence:wrapSentence beginTime:wrapSentenceBeginTime duration:allWrapWordDuration endTime:wrapSentenceEndTime line:curLineIdx relativeWordModels:wrapSentenceRelaWordModels absoluteWordModels:wrapSentenceAbsoWordModels allWordsDuration:allWrapWordDuration];
                [sentencseDict setObject:wrapSentenceModel forKey:[NSString stringWithFormat:@"%zd", wrapSentenceBeginTime]];
            }
            
        }else{
            [sentencseDict setObject:sentenceModel forKey:sentenceBeginTime];
        }
    }else{
        NSLog(@"存在非法时间符号，当前行：%@",line);
    }
}

#pragma mark -歌曲元信息解析
- (void)_parseMetaInfo{
    //[ti:][ar:汪苏泷][al:一笑倾城][by:][offset:0]
    
    NSString* metaInfoStr = metaInfo;
    metaInfoStr = [metaInfoStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(!metaInfoStr || [metaInfoStr isEqualToString:@""]){
        NSLog(@"当前歌词无元信息");
        return;
    }
    
    NSRange prevMetaInfoUnitRange = NSMakeRange(0, 0);
    NSRange curMetaInfoUnitRange = [metaInfoStr rangeOfString:_RC_metaInfoPatternImp options:NSRegularExpressionSearch];
    
    if(curMetaInfoUnitRange.length <= 0){
        NSLog(@"当前歌曲元信息格式有误");
        return;
    }
    
    while (curMetaInfoUnitRange.length > 0) {
        //[ti:歌曲名]
        NSString* curMetaInfoUnit = [metaInfoStr substringWithRange:curMetaInfoUnitRange];
        
        NSRange leftBracketRange = [curMetaInfoUnit rangeOfString:@"["];
        NSRange rightBracketRange = [curMetaInfoUnit rangeOfString:@"]"];
        NSRange commaRange = [curMetaInfoUnit rangeOfString:@":"];
        
        NSRange keyRange = NSMakeRange(leftBracketRange.location + 1, commaRange.location - leftBracketRange.location - 1);
        NSString* key = [curMetaInfoUnit substringWithRange:keyRange];
        key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSRange valueRange = NSMakeRange(commaRange.location + 1, rightBracketRange.location - commaRange.location - 1);
        NSString* value = [curMetaInfoUnit substringWithRange:valueRange];
        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if([key isEqualToString:@"ti"]){
            title = value;
        }else if([key isEqualToString:@"ar"]){
            artist = value;
        }else if([key isEqualToString:@"by"]){
            by = value;
        }else if([key isEqualToString:@"al"]){
            album = value;
        }else if([key isEqualToString:@"au"]){
            author = value;
        }else if([key isEqualToString:@"offset"]){
            if([self isDigitString:value]){
                offset = [value floatValue];
            }else{
                NSLog(@"第%zd首歌词元信息有误，offset值必需是数字",self.lyricIdx);
            }
        }else{
            NSLog(@"暂不支持的元信息:%@",key);
        }
        
        prevMetaInfoUnitRange = curMetaInfoUnitRange;
        curMetaInfoUnitRange = [metaInfoStr rangeOfString:_RC_metaInfoPatternImp options:NSRegularExpressionSearch range:NSMakeRange(curMetaInfoUnitRange.location + curMetaInfoUnitRange.length, metaInfoStr.length - (curMetaInfoUnitRange.location + curMetaInfoUnitRange.length))];
        
    }
}

-(void)_clearMetaInfo{
    title = nil;
    artist = nil;
    by = nil;
    offset = 0.0;
    album = nil;
    author = nil;
    
    metaInfo = [NSMutableString string];
}


#pragma -mark NSXmlParser Delegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict{
    
    if([elementName isEqualToString:@"QrcHeadInfo"]){
        NSString* saveTime = [attributeDict objectForKey:@"SaveTime"];
        self.saveTime = [NSDate dateWithTimeIntervalSince1970:[saveTime doubleValue]];
    }
    if([elementName isEqualToString:@"LyricInfo"]){
        NSString* lyricCount = [attributeDict objectForKey:@"LyricCount"];
        self.lyricCount = [lyricCount intValue];
    }
    if([elementName isEqualToString:[NSString stringWithFormat:@"Lyric_%zd",self.lyricIdx]]){
        self.lyricIdx ++;
        NSString* lyricTypeText = [attributeDict objectForKey:@"LyricType"];
        NSString* lyricContent = [attributeDict objectForKey:@"LyricContent"];
        LyricType lyricType = [lyricTypeText intValue];
        //得到单首歌曲信息
        switch (lyricType) {
            case LyricType_QRC:{
                FMSingleLyricModel* singleLyricModel = [self _parseQRCLyricContent:lyricContent lyritType:LyricType_QRC];
                if(singleLyricModel){
                    [self.lyricModels addObject:singleLyricModel];
                }else{
                    NSLog(@"解析当前歌词文件第%zd首歌词错误，返回模型为空",self.lyricIdx + 1);
                }
                self.lyricIdx ++;
            }
                break;
            case LyricType_LRC:{
                FMSingleLyricModel* singleLyricModel = [self _parseLRCLyricContent:lyricContent];
                if(singleLyricModel){
                    [self.lyricModels addObject:singleLyricModel];
                }else{
                    NSLog(@"解析当前歌词文件第%zd首歌词错误，返回模型为空",self.lyricIdx + 1);
                }
                self.lyricIdx ++;
            }
                break;
                
            default:{
                NSLog(@"暂不支持其他格式");
            }
                break;
        }
    }
}

#pragma mark - 工具方法
- (NSString*)_LRC_getTimeStampTextWithTime:(NSString*)timeText{
    //time-->05:17.00, return: 毫秒数
    NSRange colonRange = [timeText rangeOfString:@":"];
    NSRange dotRange = [timeText rangeOfString:@"."];
    
    NSRange minuteTextRange = NSMakeRange(0, colonRange.location);
    NSString* minuteText = [timeText substringWithRange:minuteTextRange];
    
    NSRange secondTextRange = NSMakeRange(colonRange.location + 1, dotRange.location - colonRange.location - 1);
    NSString* secondText = [timeText substringWithRange:secondTextRange];
    
    NSString* mSecondText = [timeText substringFromIndex:dotRange.location + 1];
    
    int minute = [minuteText intValue];
    int second = [secondText intValue];
    int mSecond = [mSecondText intValue];
    
    int time = minute * 60 * 1000 + second * 1000 + mSecond * 10;
    
    return [NSString stringWithFormat:@"%zd",time];
}

- (BOOL)isDigitString:(NSString*)string{
    int tmpVal;
    NSScanner* scan = [NSScanner scannerWithString:string];
    return [scan scanInt:&tmpVal] && [scan isAtEnd];
}

@end
