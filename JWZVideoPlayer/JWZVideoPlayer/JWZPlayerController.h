//
//  JWZVideoPlayerViewController.h
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, JWZPlayerControllerStatus) {
    JWZPlayerControllerStopped,
    JWZPlayerControllerPaused,
    JWZPlayerControllerPlaying
};

typedef NS_ENUM(NSInteger, JWZPlayerControllerMode) {
    JWZPlayerControllerModeNone,
    JWZPlayerControllerModeWindow,
    JWZPlayerControllerModeScreen
};

@class JWZPlayerController;

@protocol JWZPlayerControllerDelegate <NSObject>

- (void)playerControllerDidStartPlaying:(JWZPlayerController *)playerController;
- (void)playerControllerDidFinishPlaying:(JWZPlayerController *)playerController;

- (void)playerControllerClicked:(JWZPlayerController *)playerController;

@end

@interface JWZPlayerController : UIViewController

/**
 *  接收视频播放事件的代理方法
 */
@property (nonatomic, weak) id<JWZPlayerControllerDelegate> delegate;

/**
 *  视频的缩略图
 */
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

/**
 *  视频的资源链接
 */
@property (nonatomic, strong) NSURL *mediaURL;

@property (nonatomic, readonly) JWZPlayerControllerStatus status;
@property (nonatomic, readonly) JWZPlayerControllerMode mode;

/**
 *  共享的视频播放器。这个播放器在第一次调用后就始终存在。
 *
 *  @return 视频播放器控制器
 */
+ (instancetype)sharedPlayerController;

/**
 *  把播放器放到视图 playView 上
 *
 *  @param playView 将要放置播放器的视图
 */
- (void)showPlayerOverView:(UIView *)playView;

/**
 *  将播放器从控制器 viewController 上 present 出来。
 *
 *  @param viewController present 播放器的控制器
 */
- (void)presentPlayerFromViewController:(UIViewController *)viewController;

- (void)remove;

/**
 *  除非调用此方法，否则播放器不会播放。
 */
- (void)play;

- (void)pause;

/**
 *  停止播放
 */
- (void)stop;



@end
