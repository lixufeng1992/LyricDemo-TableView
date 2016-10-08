//
//  FMLyricSingleViewController.m
//  LyricDemo
//
//  Created by lixufeng on 16/9/30.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "FMLyricSingleViewController.h"
#import "FMLyricSmallView.h"

@interface FMLyricSingleViewController (){
    
}

@property (nonatomic, strong, readwrite) FMLyricSmallView* smallLyicView;

@property (nonatomic, strong, readwrite) UIButton* rollSwitcher;
@property (nonatomic, strong, readwrite) UIButton* pauseOrBeginSwitcher;

@property (nonatomic, strong, readwrite) NSTimer* timer;
@property (nonatomic, assign, readwrite) CGFloat curSecond;

@end

@implementation FMLyricSingleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear: animated];
    
    [self initLyricPanel];
    
    [self initPauseBeginSwitcher];
    [self initRollSwitcher];
    
    [self beginScrollLyric];
    
}

- (void)initLyricPanel{
    CGRect lyricPanelFrame = CGRectMake(SCREEN_WIDTH / 3, 200, SCREEN_WIDTH / 3, 30);
    _smallLyicView = [[FMLyricSmallView alloc] initWithFrame:lyricPanelFrame];
    _smallLyicView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"glance_bg"]];
    _smallLyicView.alpha = 0.6;
    [self.view addSubview:_smallLyicView];
}

//逐字／逐行开关
- (void)initRollSwitcher{
    
    _rollSwitcher = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 30, SCREEN_HEIGHT / 2 - 30, 30, 30)];
    [_rollSwitcher setTitle:@"逐字" forState:UIControlStateNormal];
    [_rollSwitcher setTitle:@"逐行" forState:UIControlStateSelected];
    _rollSwitcher.titleLabel.font = [UIFont systemFontOfSize:10];
    _rollSwitcher.layer.borderWidth = 1.5;
    
    _rollSwitcher.clipsToBounds = YES;
    _rollSwitcher.layer.cornerRadius = 15;
    _rollSwitcher.layer.masksToBounds = YES;
    [_rollSwitcher setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_rollSwitcher setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _rollSwitcher.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_rollSwitcher];
    [_rollSwitcher setSelected:NO];
    
    [_rollSwitcher addTarget:self action:@selector(rollSwitcherPressUp:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)initPauseBeginSwitcher{
    _pauseOrBeginSwitcher = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 + 5, SCREEN_HEIGHT / 2  - 30, 30, 30)];
    [_pauseOrBeginSwitcher setTitle:@"开始" forState:UIControlStateNormal];
    [_pauseOrBeginSwitcher setTitle:@"暂停" forState:UIControlStateSelected];
    _pauseOrBeginSwitcher.titleLabel.font = [UIFont systemFontOfSize:10];
    _pauseOrBeginSwitcher.layer.borderWidth = 1.5;
    
    _pauseOrBeginSwitcher.clipsToBounds = YES;
    _pauseOrBeginSwitcher.layer.cornerRadius = 15;
    _pauseOrBeginSwitcher.layer.masksToBounds = YES;
    [_pauseOrBeginSwitcher setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_pauseOrBeginSwitcher setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _pauseOrBeginSwitcher.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_pauseOrBeginSwitcher];
    [_pauseOrBeginSwitcher setSelected:NO];
    
    [_pauseOrBeginSwitcher addTarget:self action:@selector(pauseOrPlayPressUp:) forControlEvents:UIControlEventTouchUpInside];
}

//逐行／换行切换
- (void)rollSwitcherPressUp:(UIButton*)sender{
    
    [sender setSelected:!sender.selected];
    if([sender isSelected]){
        [self.smallLyicView setShouldHilightenedByWord:YES];
    }else{
        [self.smallLyicView setShouldHilightenedByWord:NO];
    }
}
//暂停／开始切换
- (void)pauseOrPlayPressUp:(UIButton*)sender{
    [sender setSelected:!sender.selected];
    if([sender isSelected]){//开始
        [self startTimer];
        [self.smallLyicView resumeAnimation];
    }else{
        [self stopTimer]; //播放器暂停
        [self.smallLyicView pauseAnimation]; //歌词暂停
    }
}



- (void)beginScrollLyric{
    
    NSString* docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"docPath:%@",docPath);
    
    NSString* fileName = @"lyric.qrc";
    NSString* lyricFilepath = [docPath stringByAppendingPathComponent:fileName];
    
    [_smallLyicView setLyricIdxToShow:3];
    [_smallLyicView loadLyricAtPath:lyricFilepath translateLyricAtPath:nil];
    
    //[self startTimer];
    
}

//模拟播放器，给一个时间出来
- (void)startTimer{
    __weak typeof(self) weakSelf = self;
    NSLog(@"计时器开始");
    _timer = [NSTimer timerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        NSLog(@"第%f秒",weakSelf.curSecond);
        [_smallLyicView repaintWithProgressTime:weakSelf.curSecond];
        weakSelf.curSecond += 0.1;
        
    }];
    
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
}

- (void)stopTimer{
    if([_timer isValid]){
        [_timer invalidate];
    }
    _timer = nil;
    NSLog(@"销毁计时器");
}


@end
