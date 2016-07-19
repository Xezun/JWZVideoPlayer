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

/**
 *  JWZPlayerControlle 的代理方法
 */
@protocol JWZPlayerControllerDelegate <NSObject>

@optional
/**
 *  正常模式下，当播放器需要被展示时，应该由谁来 Present.
 *
 *  @param playerController 需要被 Present 的 JWZPlayerController 对象
 *
 *  @return JWZPlayerController的 presentingViewController 。
 */
- (UIViewController *)viewContorllerForPresentingPlayerController:(JWZPlayerController *)playerController;

/**
 *  嵌入模式下，JWZPlayerController 的承载的播放器视图应该被展示在那个视图之上。
 *
 *  @param playerController 承载播放视图的 JWZPlayerController 对象。
 *
 *  @return 需要展示播放器的视图。
 */
- (UIView *)viewForDisplayingEmbeddedPlayer:(JWZPlayerController *)playerController;

/**
 *  播放器展示状态发生改变时，调用的代理方法。
 *
 *  @param playerController 播放器控制器对象。
 *  @param displayMode      展示方式
 */
- (void)playerController:(JWZPlayerController *)playerController shouldDisplayWithMode:(JWZPlayerControllerDisplayMode)displayMode;

@end

@interface JWZPlayerController : UIViewController <JWZPlayerDelegate, UITextViewDelegate>

/**
 *  视频的资源链接
 */
@property (nonatomic, strong, readonly) NSURL *mediaURL;

@property (nonatomic, readonly) JWZPlayerControllerDisplayMode displayMode;

@property (nonatomic, weak) id<JWZPlayerControllerDelegate> delegate;

/**
 *  播放。
 *
 *  @param mediaURL 媒体资源的链接。
 */
- (void)play:(NSURL *)mediaURL displayMode:(JWZPlayerControllerDisplayMode)displayMode;

- (void)pause;

/**
 *  停止播放
 */
- (void)stop;



@end
