//
//  JWZPlayerViewController.h
//  JWZPlayer
//
//  Created by J. W. Z. on 16/3/28.
//  Copyright © 2016年 J. W. Z.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWZPlayerView.h"

typedef NS_ENUM(NSInteger, JWZPlayerControllerDisplayMode) {
    JWZPlayerControllerDisplayModeNormal,  // 正常模式，全屏播放
    JWZPlayerControllerDisplayModeEmbedded // 嵌入模式，需要实现代理，指定嵌入的位置
};

@class JWZPlayerViewController;
@protocol JWZPlayerPlaybackControls;

/**
 *  JWZPlayerController 的代理方法
 */
@protocol JWZPlayerViewControllerDelegate <NSObject>

@optional
/**
 *  当 JWZPlayerController 需要在正常模式下呈现播放器时，会通过此代理方法获取它的 presentingViewController。如果此代理方法没有实现，默认当前 keywindow 的根控制器。
 *
 *  @param playerController 播放器控制器 JWZPlayerController 对象。
 *
 *  @return JWZPlayerController的 presentingViewController 。
 */
- (nonnull UIViewController *)viewControllerForPresentingPlayerViewController:(JWZPlayerViewController * _Nonnull)playerViewController;

/**
 *  当以嵌入模式呈现播放器时，JWZPlayerController 将通过此方法获取播放器要嵌入的位置。如果此代理方法没有实现，则呈现方式转换为普通模式。
 *
 *  @param playerController 播放器控制器 JWZPlayerController 对象。
 *
 *  @return 播放器将要嵌入的视图，即也是播放器的 superview 。
 */
- (nonnull UIView *)viewForDisplayingPlayerViewControllerInEmbeddedMode:(JWZPlayerViewController * _Nonnull)playerViewController;

@end


/**
 *  播放器控制器
 */
@interface JWZPlayerViewController : UIViewController <JWZPlayerDelegate>

/**
 *  播放器视图。
 */
@property (nonatomic, strong, null_resettable) JWZPlayerView *playerView;

/**
 *  JWZPlayerController 呈现播放器的模式。
 */
@property (nonatomic) JWZPlayerControllerDisplayMode displayMode;

/**
 *  控制器的代理。
 */
@property (nonatomic, weak, nullable) id<JWZPlayerViewControllerDelegate> delegate;

/**
 *  回放控制 UI 。
 */
@property (nonatomic, strong, nullable) __kindof UIView<JWZPlayerPlaybackControls> *playbackControls;

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
 *  @param mediaURL    媒体资源
 *  @param displayMode 呈现模式
 */
- (void)playWithMediaURL:(NSURL * _Nullable)mediaURL displayMode:(JWZPlayerControllerDisplayMode)displayMode;

@end


/**
 *  播放控制视图需要遵循的代理方法。
 */
@protocol JWZPlayerPlaybackControls <NSObject>

@optional
- (void)playerControllerWillStartPlaying:(JWZPlayerViewController * _Nonnull)playerController;
- (void)playerController:(JWZPlayerViewController * _Nonnull)playerController didStartPlayingMediaWithDuration:(NSTimeInterval)duration;
- (void)playerControllerDidStallPlaying:(JWZPlayerViewController * _Nonnull)playerController;
- (void)playerControllerDidContinuePlaying:(JWZPlayerViewController * _Nonnull)playerController;
- (void)playerControllerDidFailToPlay:(JWZPlayerViewController * _Nonnull)playerController;
- (void)playerController:(JWZPlayerViewController * _Nonnull)playerController didLoadDuration:(NSTimeInterval)loadedDuration;
- (void)playerControllerDidFinishPlaying:(JWZPlayerViewController * _Nonnull)playerController;

@end
