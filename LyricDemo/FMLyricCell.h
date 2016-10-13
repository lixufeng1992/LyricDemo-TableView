//
//  FMLyricCell.h
//  LyricDemo
//
//  Created by lixufeng on 16/10/11.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMLyricLabel.h"

@interface FMLyricCell : UITableViewCell

@property(nonatomic, strong, readonly) FMLyricLabel* label;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

+ (NSString*)identifier;

@end
