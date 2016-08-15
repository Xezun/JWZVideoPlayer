//
//  JWZPlayerControllerPlaybackControls.m
//  JWZVideoPlayer
//
//  Created by iMac on 16/7/21.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "JWZPlayerPlaybackControls.h"

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


static NSString *const kBarAnimationKey = @"kJWZPlayerControllerPlaybackControlsBarAnimationKey";
static CGFloat const kBarHeight = 36.0;

@interface JWZPlayerPlaybackControls ()

@property (nonatomic, weak) UIView *footBarView;
@property (nonatomic, weak) UIButton *playButton;
@property (nonatomic, weak) UIButton *zoomButton;
@property (nonatomic, weak) _JWZTimeDisplayLabel *timeLabel;
@property (nonatomic, weak) _JWZTimeDisplayLabel *durationLabel;
@property (nonatomic, weak) _JWZProgressSlider *progressSlider;

@property (nonatomic, weak) UIActivityIndicatorView *activityIndicatorView;

/**
 *  刷新播放进度的定时器。
 */
@property (nonatomic, strong) NSTimer *playingProgressTimer;

@end

@implementation JWZPlayerPlaybackControls

- (void)dealloc {
    if (_playingProgressTimer != nil) {
        [_playingProgressTimer invalidate];
        _playingProgressTimer = nil;
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self JWZPlayerControllerPlaybackControls_viewDidInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self JWZPlayerControllerPlaybackControls_viewDidInitialize];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

#pragma mark - Events And Actions

- (void)playButtonAction:(UIButton *)button {
    if (button.isSelected) {
        button.selected = NO;
        [button setImage:UIImageFromJWZPlayerBundle(@"icon-btn-play-light") forState:(UIControlStateHighlighted)];
        [self.playerController pause];
        self.playingProgressTimer.fireDate = [NSDate distantFuture];
        [self JWZPlayerControllerPlaybackControls_hideFootBarView:NO];
    } else {
        button.selected = YES;
        [button setImage:UIImageFromJWZPlayerBundle(@"icon-btn-pause-light") forState:(UIControlStateHighlighted | UIControlStateSelected)];
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
    self.timeLabel.duration = currentTime;
    // self.durationLabel.duration = (NSUInteger)(self.progressSlider.maximumValue - currentTime);
}

- (void)tapAction:(UITapGestureRecognizer *)tap {
    if (self.playButton.isSelected) { // 正在播放
        [self JWZPlayerControllerPlaybackControls_hideFootBarView:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.playButton.isSelected) {
                [self JWZPlayerControllerPlaybackControls_hideFootBarView:YES];
            }
        });
    }
}

#pragma mark - <JWZPlayerControllerPlaybackControls>

- (void)playerControllerWillStartPlaying:(JWZPlayerController *)playerController {
    self.playButton.selected = YES;
    UIImage *image = UIImageFromJWZPlayerBundle(@"icon-btn-pause-light");
    [self.playButton setImage:image forState:(UIControlStateHighlighted | UIControlStateSelected)];
    self.durationLabel.duration = 0;
    [self.activityIndicatorView startAnimating];
}

- (void)playerController:(JWZPlayerController *)playerController didStartPlayingMediaWithDuration:(NSTimeInterval)duration {
    [self.activityIndicatorView stopAnimating];
    // 显示时长
    self.durationLabel.duration = duration;
    // 播放进度
    if (duration != NSNotFound && self.progressSlider.maximumValue != duration) {
        self.progressSlider.maximumValue = duration;
        NSTimeInterval interval = self.progressSlider.maximumValue / CGRectGetWidth(self.progressSlider.frame);
        interval = MAX(0.2, interval);
        self.playingProgressTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(playingProgressTimerAction:) userInfo:nil repeats:YES];
    }
    [self.playingProgressTimer fire];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.playButton.isSelected) {
            [self JWZPlayerControllerPlaybackControls_hideFootBarView:YES];
        }
    });
}

- (void)playerController:(JWZPlayerController *)playerController didLoadDuration:(NSTimeInterval)loadedDuration {
    [self.progressSlider.progressView setProgress:(loadedDuration / self.progressSlider.maximumValue) animated:YES];
}

- (void)playerControllerDidStallPlaying:(JWZPlayerController *)playerController {
    [self.activityIndicatorView startAnimating];
}

- (void)playerControllerDidContinuePlaying:(JWZPlayerController *)playerController {
    [[self activityIndicatorView] stopAnimating];
}

- (void)playerControllerDidFailToPlay:(JWZPlayerController *)playerController {
    [[self activityIndicatorView] stopAnimating];
    self.durationLabel.text = 0;
    [self playerControllerDidFinishPlaying:playerController];
}

- (void)playerControllerDidFinishPlaying:(JWZPlayerController *)playerController {
    [self JWZPlayerControllerPlaybackControls_hideFootBarView:NO];
    self.playButton.selected = NO;
    self.progressSlider.value = self.progressSlider.maximumValue;
    [self.playingProgressTimer setFireDate:[NSDate distantFuture]];
}

#pragma mark - 私有方法。

/**
 *  视图初始化，创建界面UI。
 */
- (void)JWZPlayerControllerPlaybackControls_viewDidInitialize {
    self.clipsToBounds = YES;
    
    // 底部控制条
    UIView *toolBar = [[UIView alloc] init];
    toolBar.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    [self addSubview:toolBar];
    {
        toolBar.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[toolBar]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(toolBar)];
        NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[toolBar(==barHeight)]|" options:(NSLayoutFormatAlignAllLeft) metrics:@{@"barHeight": @(kBarHeight)} views:NSDictionaryOfVariableBindings(toolBar)];
        [self addConstraints:consts1];
        [self addConstraints:consts2];
    }
    
    // 播放按钮
    UIButton *playButton = [[UIButton alloc] init];
    [playButton setImage:UIImageFromJWZPlayerBundle(@"icon-btn-play") forState:(UIControlStateNormal)];
    [playButton setImage:UIImageFromJWZPlayerBundle(@"icon-btn-play-light") forState:(UIControlStateHighlighted)];
    [playButton setImage:UIImageFromJWZPlayerBundle(@"icon-btn-pause") forState:(UIControlStateSelected)];
    [toolBar addSubview:playButton];
    {
        playButton.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[playButton]" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(playButton)];
        NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[playButton]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(playButton)];
        [toolBar addConstraints:consts1];
        [toolBar addConstraints:consts2];
        NSLayoutConstraint *const1 = [NSLayoutConstraint constraintWithItem:playButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:playButton attribute:(NSLayoutAttributeHeight) multiplier:1.0 constant:0];
        [playButton addConstraint:const1];
    }
    [playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 全屏按钮
    UIButton *zoomButton = [[UIButton alloc] init];
    [zoomButton setImage:UIImageFromJWZPlayerBundle(@"icon-btn-zoomin") forState:(UIControlStateNormal)];
    [zoomButton setImage:UIImageFromJWZPlayerBundle(@"icon-btn-zoomout") forState:(UIControlStateSelected)];
    [toolBar addSubview:zoomButton];
    {
        zoomButton.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[zoomButton]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(zoomButton)];
        NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[zoomButton]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(zoomButton)];
        [toolBar addConstraints:consts1];
        [toolBar addConstraints:consts2];
        NSLayoutConstraint *const1 = [NSLayoutConstraint constraintWithItem:zoomButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:zoomButton attribute:(NSLayoutAttributeHeight) multiplier:1.0 constant:0];
        [zoomButton addConstraint:const1];
    }
    [zoomButton addTarget:self action:@selector(zoomButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 进度条容器
    UIView *progressWrapperView = [[UIView alloc] init];
    [toolBar addSubview:progressWrapperView];
    {
        progressWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[playButton]-0@750-[progressWrapperView]-0@750-[zoomButton]" options:(NSLayoutFormatDirectionLeadingToTrailing) metrics:nil views:NSDictionaryOfVariableBindings(playButton, progressWrapperView, zoomButton)];
        [toolBar addConstraints:consts1];
        NSLayoutConstraint *const1 = [NSLayoutConstraint constraintWithItem:progressWrapperView attribute:(NSLayoutAttributeCenterX) relatedBy:(NSLayoutRelationEqual) toItem:toolBar attribute:(NSLayoutAttributeCenterX) multiplier:1.0 constant:0];
        [toolBar addConstraint:const1];
        NSLayoutConstraint *const2 = [NSLayoutConstraint constraintWithItem:progressWrapperView attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationGreaterThanOrEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1.0 constant:0];
        const2.priority = UILayoutPriorityRequired;
        [progressWrapperView addConstraint:const2];
        NSLayoutConstraint *const3 = [NSLayoutConstraint constraintWithItem:progressWrapperView attribute:(NSLayoutAttributeCenterX) relatedBy:(NSLayoutRelationEqual) toItem:toolBar attribute:(NSLayoutAttributeCenterX) multiplier:1.0 constant:0];
        [toolBar addConstraint:const3];
        NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[progressWrapperView]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(progressWrapperView)];
        [toolBar addConstraints:consts2];
    }
    
    _JWZTimeDisplayLabel *timeLabel = [[_JWZTimeDisplayLabel alloc] init];
    timeLabel.font                      = [UIFont systemFontOfSize:9.0];
    timeLabel.textColor                 = [UIColor whiteColor];
    timeLabel.text                      = @"00:00";
    timeLabel.textAlignment             = NSTextAlignmentCenter;
    timeLabel.adjustsFontSizeToFitWidth = YES;
    [timeLabel setContentHuggingPriority:(UILayoutPriorityRequired) forAxis:(UILayoutConstraintAxisHorizontal)];
    [progressWrapperView addSubview:timeLabel];
    // 进度条
    _JWZProgressSlider *progressSlider = [[_JWZProgressSlider alloc] init];
    progressSlider.userInteractionEnabled = NO; // 禁用拖动
    progressSlider.minimumValue           = 0;
    progressSlider.maximumTrackTintColor  = [UIColor clearColor];
    progressSlider.thumbTintColor         = [UIColor clearColor];
    progressSlider.minimumTrackTintColor  = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    progressSlider.progressView.trackTintColor    = [UIColor colorWithWhite:0.5 alpha:1.0];
    progressSlider.progressView.progressTintColor = [UIColor colorWithRed:0.4 green:0.7 blue:0.4 alpha:1.0];
    
    [progressWrapperView addSubview:progressSlider];
    _JWZTimeDisplayLabel *durationLabel = [[_JWZTimeDisplayLabel alloc] init];
    durationLabel.font                      = [UIFont systemFontOfSize:9.0];
    durationLabel.textColor                 = [UIColor whiteColor];
    durationLabel.text                      = @"--:--";
    durationLabel.textAlignment             = NSTextAlignmentCenter;
    durationLabel.adjustsFontSizeToFitWidth = YES;
    [durationLabel setContentHuggingPriority:(UILayoutPriorityRequired) forAxis:(UILayoutConstraintAxisHorizontal)];
    [progressWrapperView addSubview:durationLabel];
    {
        timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
        durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *const1 = [NSLayoutConstraint constraintWithItem:progressSlider attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:progressWrapperView attribute:(NSLayoutAttributeCenterY) multiplier:1.0 constant:0];
        [progressWrapperView addConstraint:const1];
        NSLayoutConstraint *const2 = [NSLayoutConstraint constraintWithItem:timeLabel attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:progressWrapperView attribute:(NSLayoutAttributeCenterY) multiplier:1.0 constant:0];
        [progressWrapperView addConstraint:const2];
        NSLayoutConstraint *const3 = [NSLayoutConstraint constraintWithItem:durationLabel attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:progressWrapperView attribute:(NSLayoutAttributeCenterY) multiplier:1.0 constant:0];
        [progressWrapperView addConstraint:const3];
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[timeLabel]-5-[progressSlider]-5-[durationLabel]|" options:(NSLayoutFormatDirectionLeadingToTrailing) metrics:nil views:NSDictionaryOfVariableBindings(timeLabel, progressSlider, durationLabel)];
        [progressWrapperView addConstraints:consts1];
    }
    
    // 手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:tap];
    
    _footBarView    = toolBar;
    _playButton     = playButton;
    _zoomButton     = zoomButton;
    _timeLabel      = timeLabel;
    _progressSlider = progressSlider;
    _durationLabel  = durationLabel;
}



- (void)JWZPlayerControllerPlaybackControls_hideFootBarView:(BOOL)hide {
    if (hide) {
        [UIView animateWithDuration:0.5 animations:^{
            self.footBarView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, kBarHeight);
        }];
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            self.footBarView.transform = CGAffineTransformIdentity;
        }];
    }
}

#pragma mark - <CAAnimationDelegate>

- (void)animationDidStart:(CAAnimation *)anim {
    
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    self.footBarView.hidden = YES;
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

- (UIActivityIndicatorView *)activityIndicatorView {
    if (_activityIndicatorView != nil) {
        return _activityIndicatorView;
    }
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleWhite)];
    activityIndicatorView.hidesWhenStopped = YES;
    activityIndicatorView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    [self insertSubview:activityIndicatorView atIndex:0];
    
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[activityIndicatorView]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(activityIndicatorView)];
    NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[activityIndicatorView]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(activityIndicatorView)];
    [self addConstraints:consts1];
    [self addConstraints:consts2];
    
    _activityIndicatorView = activityIndicatorView;
    return _activityIndicatorView;
}

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
