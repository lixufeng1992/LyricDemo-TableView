//
//  FMConst.h
//  LyricDemo
//
//  Created by lixufeng on 16/9/13.
//  Copyright © 2016年 tencent. All rights reserved.
//

#ifndef _FMConst_h_
#define _FMConst_h_
#endif /* FMConst_h */

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

//file : FMFullView.h
#define kLineLabelTagInitialNumber 1024
#define kMillSceondsPerSecond   1000.0
#define kSecondsPerMinute 60
#define kStanderLineHeight 20
#define kStanderLineLeftTimeLabelTag 1024
#define kStanderLineRightPlayBtnTag  (kStanderLineLeftTimeLabelTag + 1)

typedef NS_ENUM(NSInteger, FMLyricFileType){
    FMLyricFileTypeUnKnow = -1,   //未知
    FMLyricFileTypeAuto,          //根据内容自动判断
    FMLyricFileTypeLRC,           //LRC格式
    FMLyricFileTypeQRC            //QRC格式
};

typedef NS_ENUM(NSInteger, FMTextAlignment){
    FMTextAlignmentLeft = 0,
    FMTextAlignmentMiddle = 1,
    FMTextAlignmentRight = 2
};
