//
//  FMLyricViewController.m
//  LyricDemo
//
//  Created by lixufeng on 16/9/13.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "FMLyricViewController.h"
#import "FMLyricFullView.h"
#import "FMConst.h"
#import "FMLyricFileModel.h"


#define SLIDER_HEIGHT 60

@interface FMLyricViewController ()

@property (nonatomic, strong, readwrite) FMLyricFullView* lyricPanel;
@property (nonatomic, strong, readwrite) UISlider* slider;

@property (nonatomic, strong, readwrite) UIButton* rollSwitcher;
@property (nonatomic, strong, readwrite) UIButton* pauseOrBeginSwitcher;

@property (nonatomic, strong, readwrite) NSTimer* timer;
@property (nonatomic, assign, readwrite) CGFloat curSecond;


@end

@implementation FMLyricViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear: animated];
    
    [self initLyricPanel];
    [self initSlider];
    [self initRollSwitcher];
    [self initPauseBeginSwitcher];
    
    [self beginScrollLyric];
    
    [self.view bringSubviewToFront:_rollSwitcher];
    [self.view bringSubviewToFront:_pauseOrBeginSwitcher];
    
}


- (void)initLyricPanel{
    CGRect lyricPanelFrame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - SLIDER_HEIGHT);
    _lyricPanel = [[FMLyricFullView alloc] initWithFrame:lyricPanelFrame];
    _lyricPanel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"glance_bg"]];
    _lyricPanel.alpha = 0.6;
    [self.view addSubview:_lyricPanel];
    
}

- (void)initSlider{
    
    CGRect sliderFrame = CGRectMake(0, SCREEN_HEIGHT - SLIDER_HEIGHT, SCREEN_WIDTH, SLIDER_HEIGHT);
    _slider = [[UISlider alloc] initWithFrame:sliderFrame];
    
    [_slider setMinimumValue:0.0];
    [_slider setMaximumValue:1.0];
    
    _slider.continuous = NO;//拖动滑块是否联动
    [_slider addTarget:self action:@selector(sliderMove:) forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:_slider];
    
}

//逐字／逐行开关
- (void)initRollSwitcher{
    
    _rollSwitcher = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.lyricPanel.frame) - 44, CGRectGetMaxY(self.lyricPanel.frame) - 44, 30, 30)];
    [_rollSwitcher setTitle:@"逐字" forState:UIControlStateNormal];
    [_rollSwitcher setTitle:@"逐行" forState:UIControlStateSelected];
    _rollSwitcher.titleLabel.font = [UIFont systemFontOfSize:10];
    _rollSwitcher.layer.borderWidth = 1.5;
    
    _rollSwitcher.clipsToBounds = YES;
    _rollSwitcher.layer.cornerRadius = 15;
    _rollSwitcher.layer.masksToBounds = YES;
    [_rollSwitcher setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [_rollSwitcher setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    _rollSwitcher.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_rollSwitcher];
    [_rollSwitcher setSelected:NO];
    
    [_rollSwitcher addTarget:self action:@selector(rollSwitcherPressUp:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)initPauseBeginSwitcher{
    _pauseOrBeginSwitcher = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.lyricPanel.frame) - 75, CGRectGetMaxY(self.lyricPanel.frame) - 44, 30, 30)];
    [_pauseOrBeginSwitcher setTitle:@"开始" forState:UIControlStateNormal];
    [_pauseOrBeginSwitcher setTitle:@"暂停" forState:UIControlStateSelected];
    _pauseOrBeginSwitcher.titleLabel.font = [UIFont systemFontOfSize:10];
    _pauseOrBeginSwitcher.layer.borderWidth = 1.5;
    
    _pauseOrBeginSwitcher.clipsToBounds = YES;
    _pauseOrBeginSwitcher.layer.cornerRadius = 15;
    _pauseOrBeginSwitcher.layer.masksToBounds = YES;
    [_pauseOrBeginSwitcher setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [_pauseOrBeginSwitcher setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    _pauseOrBeginSwitcher.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_pauseOrBeginSwitcher];
    [_pauseOrBeginSwitcher setSelected:NO];
    
    [_pauseOrBeginSwitcher addTarget:self action:@selector(pauseOrPlayPressUp:) forControlEvents:UIControlEventTouchUpInside];
}

//逐行／换行切换
- (void)rollSwitcherPressUp:(UIButton*)sender{
  
    [sender setSelected:!sender.selected];
    if([sender isSelected]){
        [self.lyricPanel setShouldHilightenedByWord:YES];
    }else{
        [self.lyricPanel setShouldHilightenedByWord:NO];
    }
}
//暂停／开始切换
- (void)pauseOrPlayPressUp:(UIButton*)sender{
    [sender setSelected:!sender.selected];
    if([sender isSelected]){//开始
        [self startTimer];
        [self.lyricPanel resumeAnimation];
    }else{
        [self stopTimer]; //播放器暂停
        [self.lyricPanel pauseAnimation]; //歌词暂停
    }
}

//拖动滑块是否联动
- (void)setRelationMove:(BOOL)enable{
    //enable:YES 联动  NO：不联动
    _slider.continuous = enable;
}

- (void)sliderMove:(UISlider*)slider{
    
    NSLog(@"你正在调整进度,当前进度%f",slider.value);
    
    [self stopTimer];//停止播放器
    [self.lyricPanel pauseAnimation]; //停止歌词滚动
    
    CGFloat curValue = slider.value;
    CGFloat totalDuration = 207488 / 1000.0;//秒
    _curSecond = totalDuration * curValue;
    
    [self startTimer];//开始播放
}

- (void)beginScrollLyric{
    
    NSString* docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"docPath:%@",docPath);
    
    NSString* fileName = @"lyric.qrc";
    NSString* lyricFilepath = [docPath stringByAppendingPathComponent:fileName];
    
    [self.lyricPanel setLyricIdxToShow:3];
    [self.lyricPanel loadLyricAtPath:lyricFilepath translateLyricAtPath:nil];
    
    //[self startTimer];
    
}

//模拟播放器，给一个时间出来
- (void)startTimer{
    __weak typeof(self) weakSelf = self;
    
    _timer = [NSTimer timerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        NSLog(@"第%f秒",weakSelf.curSecond);
        [weakSelf.lyricPanel repaintWithProgressTime:weakSelf.curSecond];
        weakSelf.curSecond += 0.1;

    }];
    
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];

}

- (void)stopTimer{
    if([_timer isValid]){
        [_timer invalidate];
    }
    _timer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
