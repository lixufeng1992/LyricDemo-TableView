//
//  FMLyricCell.m
//  LyricDemo
//
//  Created by lixufeng on 16/10/11.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "FMLyricCell.h"

@interface FMLyricCell()
@property(nonatomic, strong, readwrite) FMLyricLabel* label;
@end

@implementation FMLyricCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        _label = [[FMLyricLabel alloc] initWithFrame:self.bounds];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.contentView addSubview:_label];
        
    }
    return self;
}

- (void)layoutSubviews{
    _label.frame = CGRectMake(20, 0, self.bounds.size.width - 40, self.bounds.size.height);//self.bounds;
}

- (void)updateConstraintsIfNeeded{
    NSLayoutConstraint* leftCons = [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10];
    NSLayoutConstraint* rightCons = [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10];
    NSLayoutConstraint* topCons = [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint* bottomCons = [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];

    [self.contentView addConstraint:leftCons];
    [self.contentView addConstraint:rightCons];
    [self.contentView addConstraint:topCons];
    [self.contentView addConstraint:bottomCons];
    [super updateConstraints];
}


+ (NSString*)identifier{
    return NSStringFromClass([self class]);
}

@end
