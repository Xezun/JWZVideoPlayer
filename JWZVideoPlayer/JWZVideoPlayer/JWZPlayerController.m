//
//  JWZVideoPlayerViewController.m
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "JWZPlayerController.h"

static NSTimeInterval const kJWZPlayerControllerAnimationDefaultDuration = 0.25;

@interface _JWZPlayerControllerPlaybackControls : UIView <JWZPlayerControllerPlaybackControls>

@property (nonatomic, weak) JWZPlayerController *playerController;

@end

@interface JWZPlayerController ()

@property (nonatomic, strong, readonly) JWZPlayer *player;

//@property (strong, nonatomic) IBOutlet UIView *playerWrapperView;
//
//@property (weak, nonatomic) IBOutlet UIView *progressWrapperView;   // 进度条容器，限定进度条的位置、大小
//@property (weak, nonatomic) IBOutlet UIView *playProgressView;      // 播放进度
//@property (weak, nonatomic) IBOutlet UIView *bufferProgressView;    // 缓冲进度
//
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bufferProgress;  // 进度条的右边到其容器左边的约束
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *playProgress;    // 约束
//
//@property (nonatomic, strong) NSTimer *timer;
//
//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
//
//@property (nonatomic) CGFloat bufferProgressUpdateInterval; // 缓冲进度更新间隔
//@property (nonatomic) CGFloat progressOfBuffer; // 缓冲进度
//
//@property (nonatomic) CGFloat playingProgressUpdateInterval; // 播放进度更新间隔
//@property (nonatomic) CGFloat progressOfPlaying; // 播放进度

@end

@implementation JWZPlayerController

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        [self _JWZPlayerControllerDidInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self _JWZPlayerControllerDidInitialize];
    }
    return self;
}

- (void)_JWZPlayerControllerDidInitialize {
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
}

//- (void)dealloc {
//    if (_timer != nil) {
//        [_timer invalidate];
//        _timer = nil;
//    }
//}

- (void)loadView {
    JWZPlayer *player = [[JWZPlayer alloc] init];
    player.layer.contentsGravity = kCAGravityResizeAspect;
    player.backgroundColor = [UIColor blackColor];
    player.delegate = self;
    self.view = player;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _JWZPlayerControllerPlaybackControls *controls = [[_JWZPlayerControllerPlaybackControls alloc] init];
    controls.playerController = self;
    self.playbackControls = controls;
    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
//    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (JWZPlayer *)player {
    return (JWZPlayer *)self.view;
}

//- (void)setTimer:(NSTimer *)timer {
//    if (_timer != timer) {
//        if (_timer != nil) {
//            [_timer invalidate];
//        }
//        _timer = timer;
//    }
//}

- (void)setMediaURL:(NSURL *)mediaURL {
    if (_mediaURL != mediaURL && ![_mediaURL.absoluteString isEqualToString:mediaURL.absoluteString]) {
        _mediaURL = mediaURL;
        JWZPlayerMedia *media = self.player.media;
        if (media == nil) {
            media = [JWZPlayerMedia playerMediaWithResourceURL:_mediaURL];
        } else {
            media.resourceURL = _mediaURL;
        }
        self.player.media = media;
    }
}

- (void)setPlaybackControls:(__kindof UIView<JWZPlayerControllerPlaybackControls> *)playbackControls {
    if (_playbackControls != playbackControls) {
        if (_playbackControls != nil) {
            [_playbackControls removeFromSuperview];
        }
        _playbackControls = playbackControls;
        if (_playbackControls != nil) {
//            _playbackControls.frame = self.view.bounds;
            [self.view addSubview:_playbackControls];
//            _playbackControls.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            _playbackControls.translatesAutoresizingMaskIntoConstraints = NO;
            NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_playbackControls]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(_playbackControls)];
            NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_playbackControls]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(_playbackControls)];
            [self.view addConstraints:consts1];
            [self.view addConstraints:consts2];
        }
    }
}



/**
 *  设置进度刷新时间的同时，创建 timer。
 */
- (void)setPlayingProgressUpdateInterval:(CGFloat)playingProgressUpdateInterval {
//    if (_playingProgressUpdateInterval != playingProgressUpdateInterval) {
//        _playingProgressUpdateInterval = playingProgressUpdateInterval;
//        if (_playingProgressUpdateInterval > 0) {
//            self.progressWrapperView.hidden = NO;
//            self.timer = [NSTimer scheduledTimerWithTimeInterval:_playingProgressUpdateInterval target:self selector:@selector(updateMediaPlayingProgress:) userInfo:nil repeats:YES];
//        } else {
//            self.progressWrapperView.hidden = YES;
//            self.timer = nil;
//        }
//    }
}

- (void)setProgressOfBuffer:(CGFloat)progressOfBuffer {
//    _progressOfBuffer = progressOfBuffer;
//    self.bufferProgress.constant = CGRectGetWidth(self.bufferProgressView.bounds) * _progressOfBuffer;
//    __weak typeof(self) weakSelf = self;
//    [UIView animateWithDuration:1.0 animations:^{
//        [weakSelf.progressWrapperView layoutIfNeeded];
//    }];
}

- (void)setProgressOfPlaying:(CGFloat)progressOfPlaying {
//    _progressOfPlaying = MIN(1.0, MAX(0.0, progressOfPlaying));
//    self.playProgress.constant = CGRectGetWidth(self.playProgressView.bounds) * _progressOfPlaying;
//    __weak typeof(self) weakSelf = self;
//    [UIView animateWithDuration:_timer.timeInterval animations:^{
//        [weakSelf.progressWrapperView layoutIfNeeded];
//    }];
}

#pragma mark - Private Methods

- (void)_JWZPlayerController_displayPlayerOverView:(UIView *)view animated:(BOOL)animated {
    if (self.presentingViewController != nil) {  // 当前是全屏模式
        if (self.presentingViewController.view.window == view.window) {  // 处于同一个 window
            [UIView animateWithDuration:kJWZPlayerControllerAnimationDefaultDuration animations:^{
                // 把播放器缩放到目的视图的位置
                self.view.frame = [view.superview convertRect:view.frame toView:view.window];
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                [self dismissViewControllerAnimated:NO completion:^{
                    // 将播放器放到目的视图上
                    self.view.frame = view.bounds;
                    [view addSubview:self.view];
                }];
            }];
        } else {
            [self dismissViewControllerAnimated:NO completion:^{
                self.view.frame = view.bounds;
                [view addSubview:self.view];
            }];
        }
    } else { // 当前是窗口嵌入模式
        if (self.view.window == view.window) { // 如果播放器开始所处 window 与目的视图 window 相同
            // 将播放器放到 window 上
            self.view.frame = [self.view.superview convertRect:self.view.frame toView:self.view.window];
            [self.view.window addSubview:self.view];
            
            [UIView animateWithDuration:kJWZPlayerControllerAnimationDefaultDuration animations:^{
                // 将播放器移动到目的视图位置
                [self.view layoutIfNeeded];
                self.view.frame = [view.superview convertRect:view.frame toView:view.window];
            } completion:^(BOOL finished) {
                // 将播放器放置到目的视图
                self.view.frame = view.bounds;
                [view addSubview:self.view];
            }];
        } else { // window 不相同
            self.view.frame = view.bounds;
            [view addSubview:self.view];
        }
    }
    
}

- (void)_JWZPlayerController_presentPlayerFromController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.definesPresentationContext = YES;
    if (self.presentingViewController == nil) { // 嵌入模式
        // 将播放器放到 window 上
        if (self.view.superview != nil) {
            self.view.frame = [self.view.superview convertRect:self.view.frame toView:self.view.window];
            [self.view.window addSubview:self.view];
        }
        
        [UIView animateWithDuration:kJWZPlayerControllerAnimationDefaultDuration animations:^{
            // 背景变黑并缩放到全屏
            self.view.frame = self.view.window.bounds;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            // Present播放器控制器
            [viewController presentViewController:self animated:NO completion:NULL];
        }];
    } else if (self.presentingViewController != viewController) { // 已经是全屏状态
        if (self.view.window != viewController.view.window) { // 只有在不同的 window 上才能操作
            [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
                [viewController presentViewController:self animated:animated completion:NULL];
            }];
        }
    }
}

#pragma mark - Public Methods

- (void)play {
    [self.player play];
}

- (void)playWithMediaURL:(NSURL *)mediaURL displayMode:(JWZPlayerControllerDisplayMode)displayMode {
    self.mediaURL = mediaURL;
    [self play];
    [self display:displayMode animated:NO];
}

- (void)display:(JWZPlayerControllerDisplayMode)displayMode animated:(BOOL)animated {
    self.displayMode = displayMode;
    [self display:animated];
}

- (void)display:(BOOL)animated {
    switch (_displayMode) {
        case JWZPlayerControllerDisplayModeNormal: {
            UIViewController *presentingVC = nil;
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(viewControllerForPresentingPlayerController:)]) {
                presentingVC = [self.delegate viewControllerForPresentingPlayerController:self];
            } else {
                presentingVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            }
            [self _JWZPlayerController_presentPlayerFromController:presentingVC animated:animated];
            break;
        }
        case JWZPlayerControllerDisplayModeEmbedded: {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(viewForDisplayingEmbeddedPlayer:)]) {
                UIView *view = [self.delegate viewForDisplayingEmbeddedPlayer:self];
                [self _JWZPlayerController_displayPlayerOverView:view animated:animated];
            } else {
                [self display:(JWZPlayerControllerDisplayModeNormal) animated:animated];
            }
            break;
        }
        default:
            break;
    }
}

- (void)pause {
    [self.player pause];
    if (self.playbackControls != nil) {
        [self.playbackControls playerControllerDidPausePlaying:self];
    }
//    if (_status == JWZPlayerControllerPlaying) {
//        _status = JWZPlayerControllerPaused;
//        [self.player pause];
//        [self.timer setFireDate:[NSDate distantFuture]];
//    }
}

- (void)stop {
    [self.player stop];
}

#pragma mark - <JWZPlayerDelegate>

// 已经开始播放
- (void)playerDidStartPlaying:(JWZPlayer *)player {
    if (self.playbackControls != nil) {
        [self.playbackControls playerController:self didStartPlayingMediaWithDuration:player.media.duration];
    }
     NSLog(@"%s", __func__);
//    [self.activityIndicatorView stopAnimating];  // 停止活动指示器
//    self.thumbnailImageView.hidden = YES;       // 隐藏缩略图
//    NSTimeInterval timeInterval = player.media.duration / CGRectGetWidth(self.progressWrapperView.bounds);
//    [self setPlayingProgressUpdateInterval:timeInterval];  // 同时设置进度
//    if (self.timer != nil) {
//        [self.timer fire];
//    }
//    if (self.delegate != nil) {
//        [self.delegate playerControllerDidStartPlaying:self];
//    }
}

// 播放停滞了
- (void)playerDidStallPlaying:(JWZPlayer *)player {
//     NSLog(@"%s", __func__);
//    [self.timer setFireDate:[NSDate distantFuture]];
//    [self.activityIndicatorView startAnimating];
}

// 播放继续
- (void)playerDidContinuePlaying:(JWZPlayer *)player {
//     NSLog(@"%s", __func__);
//    [self.timer setFireDate:[NSDate distantFuture]];
//    [self.activityIndicatorView stopAnimating];
}

// 播放完成
- (void)playerDidFinishPlaying:(JWZPlayer *)player {
    if (self.playbackControls != nil) {
        [self.playbackControls playerControllerDidFinishPlaying:self];
    }
//     NSLog(@"%s", __func__);
//    [self stop];
//    if (self.delegate != nil) {
//        [self.delegate playerControllerDidFinishPlaying:self];
//    }
}

// 播放发生错误
- (void)player:(JWZPlayer *)player didFailToPlayWithError:(NSError *)error {
//     NSLog(@"%s", __func__);
//    [self stop];
//    if (self.delegate != nil) {
//        [self.delegate playerControllerDidFinishPlaying:self];
//    }
}

- (void)player:(JWZPlayer *)player didBufferMediaWithProgress:(CGFloat)progress {
    NSLog(@"%s, %f", __func__, progress);
    if (self.playbackControls != nil) {
        [self.playbackControls playerController:self didBufferMediaWithProgress:progress];
    }
}

// 播放不连续
- (void)playerDidJumpTime:(JWZPlayer *)player {
     NSLog(@"%s", __func__);
}

// 更新播放进度的方法
- (void)updateMediaPlayingProgress:(NSTimer *)timer {
//    NSTimeInterval currentTime = self.player.currentTime;
//    NSTimeInterval totalTime = self.player.media.duration;
//    CGFloat progress = 0;
//    if (currentTime != NSNotFound && totalTime != 0 && totalTime != NSNotFound) {
//        progress = currentTime / totalTime;
//    }
//     NSLog(@"Play Progress: %f", progress);
//    [self setProgressOfPlaying:progress];
}



#pragma mark - Actions & Events

- (void)tapAction:(id)sender {
    if (self.displayMode == JWZPlayerControllerDisplayModeNormal) {
        [self display:(JWZPlayerControllerDisplayModeEmbedded) animated:YES];
    } else {
        [self display:(JWZPlayerControllerDisplayModeNormal) animated:YES];
    }
}


@end

@interface _JWZProgressSliderView : UIProgressView

@property (nonatomic, weak) UISlider *slider;

@end


#pragma mark - Privite View Implementation

static UIImage *UIImageFromJWZPlayerBundle(NSString *imageName) {
    NSString *imageFullName = [NSString stringWithFormat:@"JWZPlayer.bundle/%@", imageName];
    return [UIImage imageNamed:imageFullName];
}

@interface _JWZPlayerControllerPlaybackControls ()

@property (nonatomic, weak) UIButton *playButton;
@property (nonatomic, weak) UIButton *zoomButton;
@property (nonatomic, weak) UILabel *durationLabel;
@property (nonatomic, weak) _JWZProgressSliderView *progressSliderView;

@end

@implementation _JWZPlayerControllerPlaybackControls

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

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self layoutIfNeeded];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self layoutIfNeeded];
}

- (void)_viewDidInitialize {
    CGFloat height = 30.0;
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
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[playButton(==44)]" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(playButton)];
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
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[zoomButton(==44)]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(zoomButton)];
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
        NSLayoutConstraint *const1 = [NSLayoutConstraint constraintWithItem:progressWrapperView attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:toolBar attribute:(NSLayoutAttributeWidth) multiplier:1.0 constant:-80.0];
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
    _JWZProgressSliderView *progressSlider = [[_JWZProgressSliderView alloc] initWithProgressViewStyle:(UIProgressViewStyleDefault)];
    progressSlider.userInteractionEnabled = YES;
    progressSlider.trackImage = UIImageFromJWZPlayerBundle(@"icon-img-barlight");
    progressSlider.progressImage = UIImageFromJWZPlayerBundle(@"icon-img-bardark");
//    progressSlider.slider.enabled = NO;
    
    [progressSlider.slider setThumbImage:UIImageFromJWZPlayerBundle(@"icon-img-point") forState:(UIControlStateNormal)];
    [progressSlider.slider setMinimumTrackImage:UIImageFromJWZPlayerBundle(@"icon-img-barcolored") forState:(UIControlStateNormal)];
    [progressSlider.slider setMaximumTrackTintColor:[UIColor clearColor]];
    
    [progressWrapperView addSubview:progressSlider];
    UILabel *durationLabel = [[UILabel alloc] init];
    durationLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    durationLabel.textColor = [UIColor lightGrayColor];
    durationLabel.text = @"00:00";
    durationLabel.textAlignment = NSTextAlignmentCenter;
    [durationLabel setContentHuggingPriority:(UILayoutPriorityRequired) forAxis:(UILayoutConstraintAxisHorizontal)];
    [progressWrapperView addSubview:durationLabel];
    {
        progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
        durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *const1 = [NSLayoutConstraint constraintWithItem:progressSlider attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:progressWrapperView attribute:(NSLayoutAttributeCenterY) multiplier:1.0 constant:0];
        [progressWrapperView addConstraint:const1];
        NSLayoutConstraint *const2 = [NSLayoutConstraint constraintWithItem:durationLabel attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:progressWrapperView attribute:(NSLayoutAttributeCenterY) multiplier:1.0 constant:0];
        [progressWrapperView addConstraint:const2];
        NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[progressSlider]-3-[durationLabel]|" options:(NSLayoutFormatDirectionLeadingToTrailing) metrics:nil views:NSDictionaryOfVariableBindings(progressSlider, durationLabel)];
        [progressWrapperView addConstraints:consts1];
    }
    
    self.playButton = playButton;
    self.zoomButton = zoomButton;
    self.progressSliderView = progressSlider;
    self.durationLabel = durationLabel;
}

- (void)playButtonAction:(UIButton *)button {
    if (button.isSelected) {
        [self.playerController pause];
    } else {
        [self.playerController play];
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

- (void)playerController:(JWZPlayerController *)playerController didStartPlayingMediaWithDuration:(NSTimeInterval)duration {
    self.progressSliderView.slider.minimumValue = 0;
    self.progressSliderView.slider.maximumValue = duration;
    self.playButton.selected = YES;
    NSInteger totalSeconds = duration;
    NSInteger second       = totalSeconds % 60;
    NSInteger totalMinutes = totalSeconds / 60;
    NSInteger minute       = totalMinutes % 60;
    if (totalMinutes < 60) {
        self.durationLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minute, (long)second];
    } else {
        NSInteger hour = totalMinutes / 60;
        self.durationLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hour, (long)minute, (long)second];
    }
}

- (void)playerController:(JWZPlayerController *)playerController didBufferMediaWithProgress:(CGFloat)progress {
    [self.progressSliderView setProgress:progress animated:YES];
}

- (void)playerControllerDidPausePlaying:(JWZPlayerController *)playerController {
    self.playButton.selected = NO;
}

- (void)playerControllerDidFinishPlaying:(JWZPlayerController *)playerController {
    self.playButton.selected = NO;
}

@end

@implementation _JWZProgressSliderView

- (instancetype)initWithProgressViewStyle:(UIProgressViewStyle)style {
    self = [super initWithProgressViewStyle:style];
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
    UISlider *slider = [[UISlider alloc] init];
    [self addSubview:slider];
    
    slider.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[slider]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(slider)];
    NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[slider]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(slider)];
    [self addConstraints:consts1];
    [self addConstraints:consts2];
    _slider = slider;
}

@end
