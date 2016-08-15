//
//  JWZVideoPlayerViewController.h
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWZPlayer.h"

typedef NS_ENUM(NSInteger, JWZPlayerControllerDisplayMode) {
    JWZPlayerControllerDisplayModeNormal,  // 正常模式，全屏播放
    JWZPlayerControllerDisplayModeEmbedded // 嵌入模式，需要实现代理，指定嵌入的位置
};

@class JWZPlayerController;
@protocol JWZPlayerPlaybackControls;

/**
 *  JWZPlayerController 的代理方法
 */
@protocol JWZPlayerControllerDelegate <NSObject>

@optional
/**
 *  当 JWZPlayerController 需要在正常模式下呈现播放器时，会通过此代理方法获取它的 presentingViewController。如果此代理方法没有实现，默认当前 keywindow 的根控制器。
 *
 *  @param playerController 播放器控制器 JWZPlayerController 对象。
 *
 *  @return JWZPlayerController的 presentingViewController 。
 */
- (nonnull UIViewController *)viewControllerForPresentingPlayerController:(JWZPlayerController * _Nonnull)playerController;

/**
 *  当以嵌入模式呈现播放器时，JWZPlayerController 将通过此方法获取播放器要嵌入的位置。如果此代理方法没有实现，则呈现方式转换为普通模式。
 *
 *  @param playerController 播放器控制器 JWZPlayerController 对象。
 *
 *  @return 播放器将要嵌入的视图，即也是播放器的 superview 。
 */
- (nonnull UIView *)viewForDisplayingEmbeddedPlayer:(JWZPlayerController * _Nonnull)playerController;

/**
 *  当 JWZPlayerController 要改变播放器的呈现方式时，会调用此方法询问，是否允许改变呈现方式。如果此代理方法没有实现，则默认允许。
 *
 *  @param playerController 播放器控制器 JWZPlayerController 对象。
 *  @param displayMode      将要改变的呈现方式。
 *
 *  @return YES 允许，NO 不允许。
 */
- (BOOL)playerController:(JWZPlayerController * _Nonnull)playerController shouldDisplayWithMode:(JWZPlayerControllerDisplayMode)displayMode;

@end


/**
 *  播放器控制器
 */
@interface JWZPlayerController : UIViewController <JWZPlayerDelegate>

/**
 *  视频的资源链接。
 */
@property (nonatomic, strong, readonly, nullable) NSURL *mediaURL;

/**
 *  JWZPlayerController 呈现播放器的模式。
 */
@property (nonatomic) JWZPlayerControllerDisplayMode displayMode;

/**
 *  控制器的代理。
 */
@property (nonatomic, weak, nullable) id<JWZPlayerControllerDelegate> delegate;

/**
 *  如果实现了相应的代理方法，调用此方法，JWZPlayerController 将按照指定的模式呈现播放器。
 *
 *  @param displayMode 播放器的呈现模式。
 *  @param animated    是否开启动画效果。
 */
- (void)display:(JWZPlayerControllerDisplayMode)displayMode animated:(BOOL)animated;

/**
 *  呈现播放器。你需要调用此方法才能显示播放器。
 *
 *  @param animated 是否展示动画效果。
 */
- (void)display:(BOOL)animated;

/**
 *  播放。
 *
 *  @param mediaURL 要播放的媒体资源地址。
 */
/**
 *  播放。
 *
 *  @param mediaURL    媒体资源
 *  @param displayMode 呈现模式
 */
- (void)playWithMediaURL:(NSURL * _Nullable)mediaURL displayMode:(JWZPlayerControllerDisplayMode)displayMode;

/**
 *  播放。纯粹的播放，如果当前已经开始播放，则不会进行任何操作。
 */
- (void)play;

/**
 *  暂停播放。
 */
- (void)pause;

/**
 *  停止播放
 */
- (void)stop;

/**
 *  当前播放时间。
 */
@property (nonatomic, readonly) NSTimeInterval currentTime;

/**
 *  回放控制UI
 */
@property (nonatomic, strong, nullable) __kindof UIView<JWZPlayerPlaybackControls> *playbackControls;

@end


/**
 *  播放控制视图需要遵循的代理方法。
 */
@protocol JWZPlayerPlaybackControls <NSObject>

@optional
- (void)playerControllerWillStartPlaying:(JWZPlayerController * _Nonnull)playerController;
- (void)playerController:(JWZPlayerController * _Nonnull)playerController didStartPlayingMediaWithDuration:(NSTimeInterval)duration;
- (void)playerControllerDidStallPlaying:(JWZPlayerController * _Nonnull)playerController;
- (void)playerControllerDidContinuePlaying:(JWZPlayerController * _Nonnull)playerController;
- (void)playerControllerDidFailToPlay:(JWZPlayerController * _Nonnull)playerController;
- (void)playerController:(JWZPlayerController * _Nonnull)playerController didLoadDuration:(NSTimeInterval)loadedDuration;
- (void)playerControllerDidFinishPlaying:(JWZPlayerController * _Nonnull)playerController;

@end
