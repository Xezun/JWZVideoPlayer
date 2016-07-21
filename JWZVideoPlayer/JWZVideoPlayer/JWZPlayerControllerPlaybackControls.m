//
//  JWZPlayerControllerPlaybackControls.m
//  JWZVideoPlayer
//
//  Created by iMac on 16/7/21.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "JWZPlayerControllerPlaybackControls.h"

@interface _JWZProgressSlider : UISlider

@property (nonatomic, weak) UIProgressView *progressView;

@end

@interface _JWZTimeDisplayLabel : UILabel

@property (nonatomic) NSUInteger duration;

@end

static UIImage *UIImageFromJWZPlayerBundle(NSString *imageName) {
    NSString *imageFullName = [NSString stringWithFormat:@"JWZPlayer.bundle/%@", imageName];
    return [UIImage imageNamed:imageFullName];
}

@interface JWZPlayerControllerPlaybackControls ()

@property (nonatomic, weak) UIButton *playButton;
@property (nonatomic, weak) UIButton *zoomButton;
@property (nonatomic, weak) _JWZTimeDisplayLabel *durationLabel;
@property (nonatomic, weak) _JWZProgressSlider *progressSlider;

@property (nonatomic, strong) NSTimer *playingProgressTimer;

@end

@implementation JWZPlayerControllerPlaybackControls

- (void)dealloc {
    if (_playingProgressTimer != nil) {
        [_playingProgressTimer invalidate];
        _playingProgressTimer = nil;
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self _viewDidInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self _viewDidInitialize];
    }
    return self;
}

- (void)_viewDidInitialize {
    const CGFloat height = 30.0;
    const CGFloat buttonWidth = 40.0;
    // 底部控制条
    UIView *toolBar = [[UIView alloc] init];
    toolBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self addSubview:toolBar];
    {
        toolBar.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[toolBar]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(toolBar)];
        NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[toolBar(==height)]|" options:(NSLayoutFormatAlignAllLeft) metrics:@{@"height": @(height)} views:NSDictionaryOfVariableBindings(toolBar)];
        [self addConstraints:consts1];
        [self addConstraints:consts2];
    }
    
    // 播放按钮
    UIButton *playButton = [[UIButton alloc] init];
    [playButton setImage:UIImageFromJWZPlayerBundle(@"icon-btn-play") forState:(UIControlStateNormal)];
    [playButton setImage:UIImageFromJWZPlayerBundle(@"icon-btn-pause") forState:(UIControlStateSelected)];
    [toolBar addSubview:playButton];
    {
        playButton.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[playButton(==buttonWidth)]" options:(NSLayoutFormatAlignAllLeft) metrics:@{@"buttonWidth": @(buttonWidth)} views:NSDictionaryOfVariableBindings(playButton)];
        NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[playButton]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(playButton)];
        [toolBar addConstraints:consts1];
        [toolBar addConstraints:consts2];
    }
    [playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 全屏按钮
    UIButton *zoomButton = [[UIButton alloc] init];
    [zoomButton setImage:UIImageFromJWZPlayerBundle(@"icon-btn-zoomin") forState:(UIControlStateNormal)];
    [zoomButton setImage:UIImageFromJWZPlayerBundle(@"icon-btn-zoomout") forState:(UIControlStateSelected)];
    [toolBar addSubview:zoomButton];
    {
        zoomButton.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[zoomButton(==buttonWidth)]|" options:(NSLayoutFormatAlignAllLeft) metrics:@{@"buttonWidth": @(buttonWidth)} views:NSDictionaryOfVariableBindings(zoomButton)];
        NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[zoomButton]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(zoomButton)];
        [toolBar addConstraints:consts1];
        [toolBar addConstraints:consts2];
    }
    [zoomButton addTarget:self action:@selector(zoomButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 进度条容器
    UIView *progressWrapperView = [[UIView alloc] init];
    [toolBar addSubview:progressWrapperView];
    {
        progressWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *const1 = [NSLayoutConstraint constraintWithItem:progressWrapperView attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:toolBar attribute:(NSLayoutAttributeWidth) multiplier:1.0 constant:-buttonWidth * 2.0];
        const1.priority = UILayoutPriorityDefaultHigh;
        NSLayoutConstraint *const2 = [NSLayoutConstraint constraintWithItem:progressWrapperView attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationGreaterThanOrEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1.0 constant:0];
        const2.priority = UILayoutPriorityRequired;
        NSLayoutConstraint *const3 = [NSLayoutConstraint constraintWithItem:progressWrapperView attribute:(NSLayoutAttributeCenterX) relatedBy:(NSLayoutRelationEqual) toItem:toolBar attribute:(NSLayoutAttributeCenterX) multiplier:1.0 constant:0];
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[progressWrapperView]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(progressWrapperView)];
        [toolBar addConstraint:const1];
        [progressWrapperView addConstraint:const2];
        [toolBar addConstraint:const3];
        [toolBar addConstraints:consts1];
    }
    
    // 进度条
    _JWZProgressSlider *progressSlider = [[_JWZProgressSlider alloc] init];
    progressSlider.userInteractionEnabled = NO; // 禁用拖动
    progressSlider.minimumValue           = 0;
    progressSlider.maximumTrackTintColor  = [UIColor clearColor];
    progressSlider.thumbTintColor         = [UIColor clearColor];
    progressSlider.minimumTrackTintColor  = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    progressSlider.progressView.trackTintColor    = [UIColor colorWithWhite:0.7 alpha:1.0];
    progressSlider.progressView.progressTintColor = [UIColor colorWithWhite:0.4 alpha:1.0];
 
    [progressWrapperView addSubview:progressSlider];
    _JWZTimeDisplayLabel *durationLabel = [[_JWZTimeDisplayLabel alloc] init];
    durationLabel.font                      = [UIFont systemFontOfSize:9.0];
    durationLabel.textColor                 = [UIColor lightGrayColor];
    durationLabel.text                      = @"--:--";
    durationLabel.textAlignment             = NSTextAlignmentCenter;
    durationLabel.adjustsFontSizeToFitWidth = YES;
    [durationLabel setContentHuggingPriority:(UILayoutPriorityRequired) forAxis:(UILayoutConstraintAxisHorizontal)];
    [progressWrapperView addSubview:durationLabel];
    {
        progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
        durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *const1 = [NSLayoutConstraint constraintWithItem:progressSlider attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:progressWrapperView attribute:(NSLayoutAttributeCenterY) multiplier:1.0 constant:0];
        [progressWrapperView addConstraint:const1];
        NSLayoutConstraint *const2 = [NSLayoutConstraint constraintWithItem:durationLabel attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:progressWrapperView attribute:(NSLayoutAttributeCenterY) multiplier:1.0 constant:0];
        [progressWrapperView addConstraint:const2];
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[progressSlider]-5-[durationLabel]|" options:(NSLayoutFormatDirectionLeadingToTrailing) metrics:nil views:NSDictionaryOfVariableBindings(progressSlider, durationLabel)];
        [progressWrapperView addConstraints:consts1];
    }
    
    _playButton     = playButton;
    _zoomButton     = zoomButton;
    _progressSlider = progressSlider;
    _durationLabel  = durationLabel;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

#pragma mark - Properties 

@synthesize playingProgressTimer = _playingProgressTimer;

- (NSTimer *)playingProgressTimer {
    if (_playingProgressTimer != nil) {
        return _playingProgressTimer;
    }
    return _playingProgressTimer;
}

- (void)setPlayingProgressTimer:(NSTimer *)playingProgressTimer {
    if (_playingProgressTimer != playingProgressTimer) {
        if (_playingProgressTimer != nil) {
            [_playingProgressTimer invalidate];
        }
        _playingProgressTimer = playingProgressTimer;
    }
}

#pragma mark - Events And Actions

- (void)playButtonAction:(UIButton *)button {
    if (button.isSelected) {
        button.selected = NO;
        [self.playerController pause];
        self.playingProgressTimer.fireDate = [NSDate distantFuture];
    } else {
        button.selected = YES;
        [self.playerController play];
        self.playingProgressTimer.fireDate = [NSDate distantPast];
    }
}

- (void)zoomButtonAction:(UIButton *)button {
    if (button.isSelected) {
        button.selected = NO;
        [self.playerController display:(JWZPlayerControllerDisplayModeEmbedded) animated:YES];
    } else {
        button.selected = YES;
        [self.playerController display:(JWZPlayerControllerDisplayModeNormal) animated:YES];
    }
}

- (void)playingProgressTimerAction:(NSTimer *)timer {
    NSTimeInterval currentTime = self.playerController.currentTime;
    // NSLog(@"play progress: %f", currentTime);
    [self.progressSlider setValue:currentTime animated:YES];
    self.durationLabel.duration = (NSUInteger)(self.progressSlider.maximumValue - currentTime);
}

#pragma mark - <JWZPlayerControllerPlaybackControls>

- (void)playerController:(JWZPlayerController *)playerController didStartPlayingMediaWithDuration:(NSTimeInterval)duration {
    self.playButton.selected = YES;
    // 显示时长
    self.durationLabel.duration = duration;
    // 播放进度
    if (self.progressSlider.maximumValue != duration) {
        self.progressSlider.maximumValue = duration;
        NSTimeInterval interval = self.progressSlider.maximumValue / CGRectGetWidth(self.progressSlider.frame);
        interval = MAX(0.1, interval);
        self.playingProgressTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(playingProgressTimerAction:) userInfo:nil repeats:YES];
    }
    [self.playingProgressTimer fire];
}

- (void)playerController:(JWZPlayerController *)playerController didBufferMediaWithProgress:(CGFloat)progress {
    [self.progressSlider.progressView setProgress:progress animated:YES];
}

- (void)playerControllerDidFinishPlaying:(JWZPlayerController *)playerController {
    self.playButton.selected = NO;
    [self.playingProgressTimer setFireDate:[NSDate distantFuture]];
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

#pragma mark - Privite View Implementation

@implementation _JWZProgressSlider

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self _viewDidInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self _viewDidInitialize];
    }
    return self;
}

- (void)_viewDidInitialize {
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:(UIProgressViewStyleDefault)];
    [self insertSubview:progressView atIndex:0];
    {
        /* // autoLayout 在动画的时候，有点小问题。
        progressView.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[progressView]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(progressView)];
        NSLayoutConstraint *const1 = [NSLayoutConstraint constraintWithItem:progressView attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeCenterY) multiplier:1.0 constant:0];
        NSLayoutConstraint *const2 = [NSLayoutConstraint constraintWithItem:progressView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1.0 constant:1.0];
        [progressView addConstraint:const2];
        [self addConstraint:const1];
        [self addConstraints:consts1];
         */
        CGRect bounds = self.bounds;
        progressView.frame = CGRectMake(0, CGRectGetMidY(bounds) - 1.0, CGRectGetWidth(bounds), 2.0);
        progressView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    }
    _progressView = progressView;
}

- (CGRect)trackRectForBounds:(CGRect)bounds {
    return self.progressView.frame;
    // return CGRectMake(0, CGRectGetMidY(bounds) - 0.5, CGRectGetWidth(bounds), 1.0);
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
    return CGRectMake(CGRectGetWidth(rect) * (value - self.minimumValue) / (self.maximumValue - self.minimumValue), CGRectGetMinY(rect), 1.0, 1.0);
}

@end


@implementation _JWZTimeDisplayLabel

- (void)setDuration:(NSUInteger)duration {
    if (_duration != duration) {
        _duration = duration;
        NSInteger second       = _duration % 60;    // 秒
        NSInteger totalMinutes = duration / 60;     // 分钟数
        NSInteger minute       = totalMinutes % 60; // 分钟
        if (totalMinutes < 60) {
            self.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minute, (long)second];
        } else {
            NSInteger hour = totalMinutes / 60;
            self.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hour, (long)minute, (long)second];
        }
    }
}

@end
