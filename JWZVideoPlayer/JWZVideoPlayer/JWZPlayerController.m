//
//  JWZVideoPlayerViewController.m
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "JWZPlayerController.h"

@import AVFoundation;

@interface _JWZPlayerControlView : UIView


@end

@implementation _JWZPlayerControlView

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
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // 收到内存警告时，如果没有在播放，就释放调当前资源
    // if (![self isPlaying]) {
    //     self.player.currentMedia.resourceURL = nil;
    // }
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
//- (JWZPlayer *)player {
//    if (_player != nil) {
//        return _player;
//    }
//    JWZPlayerMedia *playerMedia = [[JWZPlayerMedia alloc] init];
//    playerMedia.resourceURL = self.mediaURL;
//    JWZPlayer *player = [[JWZPlayer alloc] initWithFrame:self.playerWrapperView.bounds];
//    player.backgroundColor = [UIColor blackColor];
//    player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.playerWrapperView insertSubview:player atIndex:0];
//    
////    player.translatesAutoresizingMaskIntoConstraints = NO;
////    NSArray *constraints1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[player]|"
////                                                                    options:(NSLayoutFormatAlignAllLeft)
////                                                                    metrics:nil
////                                                                      views:NSDictionaryOfVariableBindings(player)];
////    NSArray *constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[player]|"
////                                                                    options:(NSLayoutFormatAlignAllLeft)
////                                                                    metrics:nil
////                                                                      views:NSDictionaryOfVariableBindings(player)];
////    [self.playerWrapperView addConstraints:constraints1];
////    [self.playerWrapperView addConstraints:constraints2];
//    
//    [self setPlayer:player];
//    return _player;
//}

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

- (void)setDisplayMode:(JWZPlayerControllerDisplayMode)displayMode {
    _displayMode = displayMode;
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

#pragma mark - Custom Methods

- (void)play:(NSURL *)mediaURL displayMode:(JWZPlayerControllerDisplayMode)displayMode {
    self.mediaURL = mediaURL;
    self.displayMode = displayMode;
    
    switch (_displayMode) {
        case JWZPlayerControllerDisplayModeNormal: {
            UIViewController *presentingVC = nil;
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(viewContorllerForPresentingPlayerController:)]) {
                presentingVC = [self.delegate viewContorllerForPresentingPlayerController:self];
            } else {
                presentingVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            }
            if (self.presentingViewController != nil) {
                if (self.presentingViewController != presentingVC) {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [presentingVC presentViewController:self animated:YES completion:^{
                            [self.player play];
                        }];
                    }];
                }
            } else {
                if (self.view.superview != nil) {
                    self.view.frame = [self.view.superview convertRect:self.view.frame toView:self.view.window];
                    [self.view.window addSubview:self.view];
                    [UIView animateWithDuration:0.25 animations:^{
                        self.view.frame = self.view.window.bounds;
                    } completion:^(BOOL finished) {
                        [presentingVC presentViewController:self animated:NO completion:^{
                            [self.player play];
                        }];
                    }];
                } else {
                    [presentingVC presentViewController:self animated:YES completion:^{
                        [self.player play];
                    }];
                }
            }
            break;
        }
        case JWZPlayerControllerDisplayModeEmbedded: {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(viewForDisplayingEmbeddedPlayer:)]) {
                UIView *containerView = [self.delegate viewForDisplayingEmbeddedPlayer:self];
                if (self.presentingViewController != nil) {
                    [self dismissViewControllerAnimated:NO completion:^{
                        [containerView.window addSubview:self.view];
                        CGRect frame = [containerView.superview convertRect:containerView.frame toView:containerView.window];
                        [UIView animateWithDuration:0.25 animations:^{
                            self.view.frame = frame;
                        } completion:^(BOOL finished) {
                            self.view.frame = containerView.bounds;
                            [containerView addSubview:self.view];
                            [self.player play];
                        }];
                    }];
                } else {
                    if (self.view.superview == nil) {
                        self.view.frame = containerView.bounds;
                        [containerView addSubview:self.view];
                        [self.player play];
                    } else if (self.view.superview != containerView) {
                        self.view.frame = [self.view.superview convertRect:self.view.frame toView:self.view.window];
                        [containerView.window addSubview:self.view];
                        CGRect frame = [containerView.superview convertRect:containerView.frame toView:containerView.window];
                        [UIView animateWithDuration:0.25 animations:^{
                            self.view.frame = frame;
                        } completion:^(BOOL finished) {
                            self.view.frame = containerView.bounds;
                            [containerView addSubview:self.view];
                            [self.player play];
                        }];
                    }
                }
            }
            break;
        }
    }
    
//    if (_status == JWZPlayerControllerStopped) {
//        if (self.mediaURL != nil) {
//            _status = JWZPlayerControllerPlaying;
//            if (self.player.media != nil) {
//                self.player.media.resourceURL = self.mediaURL;
//            } else {
//                JWZPlayerMedia *media = [[JWZPlayerMedia alloc] init];
//                media.resourceURL = self.mediaURL;
//                self.player.media = media;
//            }
//            [self.activityIndicatorView startAnimating];
//            self.thumbnailImageView.hidden = NO;
//            [self.player play];
//        }
//    } else if (_status == JWZPlayerControllerPaused) {
//        _status = JWZPlayerControllerPlaying;
//        [[self player] play];
//        [[self timer] setFireDate:[NSDate distantPast]];
//    }
}

- (void)pause {
    [self.player pause];
//    if (_status == JWZPlayerControllerPlaying) {
//        _status = JWZPlayerControllerPaused;
//        [self.player pause];
//        [self.timer setFireDate:[NSDate distantFuture]];
//    }
}

- (void)stop {
    [self.player stop];
}

- (void)playInView:(UIView *)view {
    _displayMode = JWZPlayerControllerDisplayModeEmbedded;
    UIViewController *presentingViewController = [self presentingViewController];
    if (presentingViewController != nil) {
//        __weak typeof(self) weakSelf = self;
//        BOOL needContinuePlaying = NO;
//        if (_status == JWZPlayerControllerPlaying) {
//            [self pause];
//            needContinuePlaying = YES;
//        }
        [self dismissViewControllerAnimated:NO completion:^{
            self.view.frame = view.bounds;
            [view addSubview:self.view];
//            self.playerWrapperView.frame = playView.bounds;
//            [playView addSubview:self.playerWrapperView];
//            [weakSelf setProgressOfBuffer:weakSelf.progressOfBuffer];
//            [weakSelf setProgressOfPlaying:weakSelf.progressOfPlaying];
//            if (needContinuePlaying) {
//                [weakSelf play];
//            }
        }];
    } else {
        self.view.frame = view.bounds;
        [view addSubview:self.view];
//        self.playerWrapperView.frame = playView.bounds;
//        [playView addSubview:self.playerWrapperView];
    }
}

- (void)presentPlayerFromViewController:(UIViewController *)viewController {
    _displayMode = JWZPlayerControllerDisplayModeNormal;
//    viewController.definesPresentationContext = YES;
//    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [viewController presentViewController:self animated:NO completion:^{
        
    }];
//    if (self.view.superview != nil) {
//
//        
//        BOOL needContinuePlaying = NO;
//        if (_status == JWZPlayerControllerPlaying) {
//            [self pause];
//            needContinuePlaying = YES;
//        }
//        CGRect frame = [self.playerWrapperView.superview.superview convertRect:self.playerWrapperView.superview.frame toView:self.playerWrapperView.superview.window];
//        [self.playerWrapperView removeFromSuperview];
//        
//        self.view.backgroundColor = [UIColor clearColor];
//        viewController.definesPresentationContext = YES;
//        self.modalPresentationStyle               = UIModalPresentationOverCurrentContext;
//        __weak typeof(self) weakSelf = self;
//        [viewController presentViewController:self animated:NO completion:^{
//            // 把播放器添加到当前控制器
//            weakSelf.playerWrapperView.frame = frame;
//            [weakSelf.view addSubview:weakSelf.playerWrapperView];
//            CGRect newFrame = AVMakeRectWithAspectRatioInsideRect(frame.size, weakSelf.view.bounds);
//            // 把背景变黑，同时放大到中间
//            [UIView animateWithDuration:0.5 animations:^{
//                weakSelf.view.backgroundColor    = [UIColor blackColor];
//                weakSelf.playerWrapperView.frame = newFrame;
//            } completion:^(BOOL finished) {
//                // 是否自动开始
//                [weakSelf setProgressOfBuffer:weakSelf.progressOfBuffer];
//                [weakSelf setProgressOfPlaying:weakSelf.progressOfPlaying];
//                if (needContinuePlaying) {
//                    [weakSelf play];
//                }
//            }];
//        }];
//    } else {
//        self.playerWrapperView.frame = self.view.bounds;
//        [self.view addSubview:self.playerWrapperView];
//        [viewController presentViewController:self animated:NO completion:NULL];
//    }
}

- (void)remove {
//    if (self.presentingViewController != nil) {
//        [self dismissViewControllerAnimated:NO completion:NULL];
//    } else if (self.playerWrapperView.superview != self.view) {
//        [self.playerWrapperView removeFromSuperview];
//    }
}

#pragma mark - <JWZPlayerDelegate>

// 已经开始播放
- (void)playerDidStartPlaying:(JWZPlayer *)player {
//     NSLog(@"%s", __func__);
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

// 缓冲进度
- (void)player:(JWZPlayer *)player mediaBufferDidChange:(CGFloat)progress {
     NSLog(@"%s, %f", __func__, progress);
    [self setProgressOfBuffer:progress];
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
        [self play:self.mediaURL displayMode:(JWZPlayerControllerDisplayModeEmbedded)];
    } else {
        [self play:self.mediaURL displayMode:(JWZPlayerControllerDisplayModeNormal)];
    }
}


@end
