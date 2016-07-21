//
//  JWZVideoPlayerViewController.m
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "JWZPlayerController.h"
#import "JWZPlayerControllerPlaybackControls.h"

static NSTimeInterval const kJWZPlayerControllerAnimationDefaultDuration = 0.25;

@interface JWZPlayerController ()

@property (nonatomic, strong, readonly) JWZPlayer *player;

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

- (void)loadView {
    JWZPlayer *player = [[JWZPlayer alloc] init];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - 属性

- (JWZPlayer *)player {
    return (JWZPlayer *)self.view;
}

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

@synthesize playbackControls = _playbackControls;

- (void)setPlaybackControls:(__kindof UIView<JWZPlayerControllerPlaybackControls> *)playbackControls {
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

- (UIView<JWZPlayerControllerPlaybackControls> *)playbackControls {
    if (_playbackControls != nil) {
        return _playbackControls;
    }
    JWZPlayerControllerPlaybackControls *controls = [[JWZPlayerControllerPlaybackControls alloc] init];
    controls.playerController = self;
    [self setPlaybackControls:controls];
    return _playbackControls;
}

- (NSTimeInterval)currentTime {
    return [self.player currentTime];
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
}

- (void)stop {
    [self.player stop];
}

#pragma mark - <JWZPlayerDelegate>

// 已经开始播放
- (void)playerDidStartPlaying:(JWZPlayer *)player {
    // NSLog(@"%s", __func__);
    if (self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerController:didStartPlayingMediaWithDuration:)]) {
        [self.playbackControls playerController:self didStartPlayingMediaWithDuration:player.media.duration];
    }
}

// 播放停滞了
- (void)playerDidStallPlaying:(JWZPlayer *)player {

}

// 播放继续
- (void)playerDidContinuePlaying:(JWZPlayer *)player {

}

// 播放完成
- (void)playerDidFinishPlaying:(JWZPlayer *)player {
    if (self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerControllerDidFinishPlaying:)]) {
        [self.playbackControls playerControllerDidFinishPlaying:self];
    }
}

// 播放发生错误
- (void)player:(JWZPlayer *)player didFailToPlayWithError:(NSError *)error {

}

- (void)player:(JWZPlayer *)player didBufferMediaWithProgress:(CGFloat)progress {
    // NSLog(@"%s, %f", __func__, progress);
    if (self.playbackControls != nil && [self.playbackControls respondsToSelector:@selector(playerController:didBufferMediaWithProgress:)]) {
        [self.playbackControls playerController:self didBufferMediaWithProgress:progress];
    }
}

// 播放不连续
- (void)playerDidJumpTime:(JWZPlayer *)player {
     // NSLog(@"%s", __func__);
}

#pragma mark - Actions & Events


@end


