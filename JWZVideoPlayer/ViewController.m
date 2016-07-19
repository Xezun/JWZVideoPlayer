//
//  ViewController.m
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "ViewController.h"
#import "JWZPlayerController.h"

@interface ViewController () <JWZPlayerControllerDelegate>

@property (nonatomic, strong) NSURL *videoURL;

@property (weak, nonatomic) IBOutlet UIView *playerAvatar;

@property (nonatomic, strong) JWZPlayerController *playerController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // @"";http://mp4.68mtv.com/mp42/53184-%E5%AE%8B%E7%A5%96%E8%8B%B1-%E5%BD%A9%E9%BE%99%E8%88%9E%E4%B8%9C%E6%96%B9[68mtv.com].mp4
    self.videoURL = [NSURL URLWithString:@"http://funsbar.file.alimmdn.com/video/activity/20160312114630732.mp4"];
    
    self.playerController = [[JWZPlayerController alloc] init];
    self.playerController.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonAction:(id)sender {
    [self.playerController play:self.videoURL displayMode:(JWZPlayerDisplayModeEmbedded)];
}

#pragma mark - <JWZPlayerControllerDelegate>

- (UIViewController *)viewContorllerForPresentingPlayerController:(JWZPlayerController *)playerController {
    return self;
}

- (UIView *)viewForDisplayingEmbeddedPlayer:(JWZPlayerController *)playerController {
    return self.playerAvatar;
}

#pragma mark - <>

/**
 *  视频已经开始播放。调用 -[JWZPlayer play] 方法，资源开始播放后，此方法会被触发。
 *
 *  @param player 已经开始视频播放的 JWZPlayer 对象。
 */
- (void)playerDidStartPlaying:(JWZPlayer *)player {
    NSLog(@"%s", __func__);
}

/**
 *  如果是网络视频，播放有可能进入缓冲状态。
 *
 *  @param player 进入缓冲状态的 JWZPlayer 对象。
 */
- (void)playerDidStallPlaying:(JWZPlayer *)player {
    NSLog(@"%s", __func__);
}

/**
 *  如果缓冲完成，可以继续播放时，这个代理方法会被调用。
 *
 *  @param player 进入继续播放状态的 JWZPlayer 对象。
 */
- (void)playerDidContinuePlaying:(JWZPlayer *)player {
    NSLog(@"%s", __func__);
}

/**
 *  如果播放资源完成，此代理方法会被调用。如果是手动停止，这个代理方法，不会被调用。
 *
 *  @param player 播放完成了的 JWZPlayer 对象。
 */
- (void)playerDidFinishPlaying:(JWZPlayer *)player {
    NSLog(@"%s", __func__);
}

/**
 *  如果在播放过程中，播放或资源发生错误，此方法会被调用。
 *
 *  @param player 发生错误的 JWZPlayer 对象。
 *  @param error  错误信息。
 */
- (void)player:(JWZPlayer *)player didFailToPlayWithError:(NSError *)error {
    NSLog(@"%s", __func__);
}

/**
 *  这个方法用于跟踪缓冲进度。
 *
 *  @param player   触发事件的播放器 JWZPlayer 对象。
 *  @param progress 缓冲的进度。
 */
- (void)player:(JWZPlayer *)player didBufferMediaWithProgress:(CGFloat)progress {
    NSLog(@"%s", __func__);
}

/**
 *  如果播放过程中发生不连续的情况，此代理方法会被调用。
 *
 *  @param player 触发事件的播放器 JWZPlayer 对象。
 */
- (void)playerDidJumpTime:(JWZPlayer *)player {
    NSLog(@"%s", __func__);
}

@end
