//
//  JWZPlayerViewController.m
//  JWZPlayerViewController
//
//  Created by iMac on 16/3/28.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "JWZPlayerViewController.h"
#import "JWZPlayerPlaybackControls.h"

/**
 *  当 JWZPlayerViewController 需要显示动画时，此值定义了动画效果的默认时长。
 */
static NSTimeInterval const kJWZPlayerViewControllerAnimationDefaultDuration = 0.50;

@interface JWZPlayerViewController ()

@property (nonatomic) BOOL prefersStatusBarHidden;

@end

@implementation JWZPlayerViewController

#pragma mark - 生命周期

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        [self JWZ_playerViewControllerDidInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self JWZ_playerViewControllerDidInitialize];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        [self JWZ_playerViewControllerDidInitialize];
    }
    return self;
}

- (void)loadView {
    JWZPlayerView *player = [[JWZPlayerView alloc] init];
    player.layer.contentsGravity = kCAGravityResizeAspect;
    player.backgroundColor = [UIColor blackColor];
    player.delegate = self;
    self.view = player;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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

#pragma mark - 禁止转屏

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - 属性

@synthesize prefersStatusBarHidden = _prefersStatusBarHidden;

- (BOOL)prefersStatusBarHidden {
    return _prefersStatusBarHidden;
}

- (void)setPrefersStatusBarHidden:(BOOL)prefersStatusBarHidden {
    if (_prefersStatusBarHidden != prefersStatusBarHidden) {
        _prefersStatusBarHidden = prefersStatusBarHidden;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (JWZPlayerView *)playerView {
    return (JWZPlayerView *)self.view;
}

- (void)setPlayerView:(JWZPlayerView *)playerView {
    [self setView:playerView];
}

@synthesize playbackControls = _playbackControls;

- (void)setPlaybackControls:(__kindof UIView<JWZPlayerPlaybackControls> *)playbackControls {
    if (_playbackControls != playbackControls) {
        if (_playbackControls != nil) {
            [_playbackControls removeFromSuperview];
        }
        _playbackControls = playbackControls;
        if (_playbackControls != nil) {
            // _playbackControls.frame = self.view.bounds;
            [self.view addSubview:_playbackControls];
            // _playbackControls.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            _playbackControls.translatesAutoresizingMaskIntoConstraints = NO;
            NSArray *consts1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_playbackControls]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(_playbackControls)];
            NSArray *consts2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_playbackControls]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(_playbackControls)];
            [self.view addConstraints:consts1];
            [self.view addConstraints:consts2];
        }
    }
}

- (UIView<JWZPlayerPlaybackControls> *)playbackControls {
    if (_playbackControls != nil) {
        return _playbackControls;
    }
    JWZPlayerPlaybackControls *controls = [[JWZPlayerPlaybackControls alloc] init];
    controls.playerController = self;
    [self setPlaybackControls:controls];
    return _playbackControls;
}

//- (NSTimeInterval)currentTime {
//    return [self.playerView currentTime];
//}

#pragma mark - 私有方法

/**
 *  对象初始化后的操作
 */
- (void)JWZ_playerViewControllerDidInitialize {
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
}

- (void)JWZ_playerViewControllerDisplayPlayerOverView:(UIView *)view animated:(BOOL)animated {
    if (self.presentingViewController != nil) {  // 当前是全屏模式
        self.prefersStatusBarHidden = [self.presentingViewController prefersStatusBarHidden];
        if (self.presentingViewController.view.window == view.window) {  // 处于同一个 window
            if (animated) {
                [UIView animateWithDuration:kJWZPlayerViewControllerAnimationDefaultDuration animations:^{
                    // 把播放器缩放到目的视图的位置
                    CGRect viewFrame = view.frame;
                    self.view.frame = CGRectMake(CGRectGetMidX(viewFrame) - CGRectGetHeight(viewFrame) / 2.0, CGRectGetMidY(viewFrame) - CGRectGetWidth(viewFrame) / 2.0, CGRectGetHeight(viewFrame), CGRectGetWidth(viewFrame));// [view.superview convertRect:view.frame toView:view.window];
                    [self.view layoutIfNeeded];
                    self.view.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                    [self dismissViewControllerAnimated:NO completion:^{
                        // 将播放器放到目的视图上
                        self.view.frame = view.bounds;
                        [view addSubview:self.view];
                    }];
                }];
            } else {
                self.view.frame = view.bounds;
                [view addSubview:self.view];
            }
        } else {
            [self dismissViewControllerAnimated:NO completion:^{
                self.view.frame = view.bounds;
                [view addSubview:self.view];
            }];
        }
    } else { // 当前是窗口嵌入模式
        if (self.view.window == view.window) { // 如果播放器开始所处 window 与目的视图 window 相同
            if (animated) {
                // 将播放器放到 window 上
                self.view.frame = [self.view.superview convertRect:self.view.frame toView:self.view.window];
                [self.view.window addSubview:self.view];
                
                [UIView animateWithDuration:kJWZPlayerViewControllerAnimationDefaultDuration animations:^{
                    // 将播放器移动到目的视图位置
                    [self.view layoutIfNeeded];
                    self.view.frame = [view.superview convertRect:view.frame toView:view.window];
                } completion:^(BOOL finished) {
                    // 将播放器放置到目的视图
                    self.view.frame = view.bounds;
                    [view addSubview:self.view];
                }];
            } else {
                // 将播放器放置到目的视图
                self.view.frame = view.bounds;
                [view addSubview:self.view];
            }
        } else { // window 不相同
            self.view.frame = view.bounds;
            [view addSubview:self.view];
        }
    }
}

- (void)JWZ_playerViewControllerPresentPlayerFromController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.definesPresentationContext = YES;
    if (self.presentingViewController == nil) { // 嵌入模式
        // 将播放器放到 window 上
        if (self.view.superview != nil) {
            self.view.frame = [self.view.superview convertRect:self.view.frame toView:self.view.window];
            [self.view.window addSubview:self.view];
        }
        
        CGRect windowBounds = self.view.window.bounds;
        CGFloat windowWidth = CGRectGetWidth(windowBounds);
        CGFloat windowHeight = CGRectGetHeight(windowBounds);
        if (animated) {
            [UIView animateWithDuration:kJWZPlayerViewControllerAnimationDefaultDuration animations:^{
                // 背景变黑并缩放到全屏
                self.view.frame = CGRectMake((windowWidth - windowHeight) / 2.0, (windowHeight - windowWidth) / 2.0, windowHeight, windowWidth);
                self.view.transform = CGAffineTransformMakeRotation(M_PI_2); // 旋转 90 度
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                // Present播放器控制器
                // NSLog(@"frame: %@", NSStringFromCGRect(self.view.frame));
                [viewController presentViewController:self animated:NO completion:NULL];
            }];
        } else {
            [viewController presentViewController:self animated:NO completion:NULL];
        }
    } else if (self.presentingViewController != viewController) { // 已经是全屏状态
        if (self.view.window != viewController.view.window) { // 只有在不同的 window 上才能操作
            [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
                [viewController presentViewController:self animated:animated completion:NULL];
            }];
        }
    }
}

#pragma mark - Public Methods

//- (void)play {
//    if ((self.playerView.status == JWZPlayerStatusStopped) && self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerControllerWillStartPlaying:)]) {
//        [self.playbackControls playerControllerWillStartPlaying:self];
//    }
//    [self.playerView play];
//}

- (void)playWithMediaURL:(NSURL *)mediaURL displayMode:(JWZPlayerControllerDisplayMode)displayMode {
    [self.playerView pause];
    [self.playerView replaceCurrentMediaWithURL:mediaURL];
    if (self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerControllerWillStartPlaying:)]) {
        [self.playbackControls playerControllerWillStartPlaying:self];
    }
    [self.playerView play];
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
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(viewControllerForPresentingPlayerViewController:)]) {
                presentingVC = [self.delegate viewControllerForPresentingPlayerViewController:self];
            } else {
                presentingVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            }
            [self JWZ_playerViewControllerPresentPlayerFromController:presentingVC animated:animated];
            break;
        }
        case JWZPlayerControllerDisplayModeEmbedded: {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(viewForDisplayingPlayerViewControllerInEmbeddedMode:)]) {
                UIView *view = [self.delegate viewForDisplayingPlayerViewControllerInEmbeddedMode:self];
                [self JWZ_playerViewControllerDisplayPlayerOverView:view animated:animated];
            } else {
                [self display:(JWZPlayerControllerDisplayModeNormal) animated:animated];
            }
            break;
        }
        default:
            break;
    }
}

//- (void)pause {
//    [self.playerView pause];
//}
//
//- (void)stop {
//    [self.playerView stop];
//}

#pragma mark - <JWZPlayerDelegate>

// 已经开始播放
- (void)playerDidStartPlaying:(JWZPlayerView *)player {
    // NSLog(@"%s", __func__);
    if (self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerController:didStartPlayingMediaWithDuration:)]) {
        [self.playbackControls playerController:self didStartPlayingMediaWithDuration:player.duration];
    }
}

// 播放停滞了
- (void)playerDidStallPlaying:(JWZPlayerView *)player {
    if (self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerControllerDidStallPlaying:)]) {
        [self.playbackControls playerControllerDidStallPlaying:self];
    }
}

// 播放继续
- (void)playerDidContinuePlaying:(JWZPlayerView *)player {
    if (self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerControllerDidContinuePlaying:)]) {
        [self.playbackControls playerControllerDidContinuePlaying:self];
    }
}

// 播放完成
- (void)playerDidFinishPlaying:(JWZPlayerView *)player {
    if (self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerControllerDidFinishPlaying:)]) {
        [self.playbackControls playerControllerDidFinishPlaying:self];
    }
}

// 播放发生错误
- (void)playerDidFailToPlayToEndTime:(JWZPlayerView *)player {
    if (self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerControllerDidFailToPlay:)]) {
        [self.playbackControls playerControllerDidFailToPlay:self];
    }
}

- (void)player:(JWZPlayerView *)player didLoadDuration:(NSTimeInterval)loadedDuration {
     NSLog(@"%s, %f", __func__, loadedDuration);
    if (self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerController:didLoadDuration:)]) {
        [self.playbackControls playerController:self didLoadDuration:loadedDuration];
    }
}

// 播放不连续
- (void)playerDidJumpTime:(JWZPlayerView *)player {
     // NSLog(@"%s", __func__);
}

#pragma mark - Actions & Events


@end


