//
//  FMLyricModelConst.h
//  LyricDemo
//
//  Created by lixufeng on 16/10/10.
//  Copyright © 2016年 tencent. All rights reserved.
//

#ifndef FMLyricModelConst_h
#define FMLyricModelConst_h



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



#endif /* FMLyricModelConst_h */
