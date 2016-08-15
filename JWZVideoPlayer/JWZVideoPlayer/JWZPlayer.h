//
//  JWZVideoPlayerView.h
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import <UIKit/UIKit.h>

// 播放器状态枚举值
typedef NS_ENUM(NSInteger, JWZPlayerStatus) {
    JWZPlayerStatusStopped,  // 停止，初始状态，或资源不可播放
    JWZPlayerStatusWaiting,  // 等待，已经开始播放，但是因为资源没有准备好，而处于等待的状态
    JWZPlayerStatusPlaying,  // 正在播放
    JWZPlayerStatusStalled,  // 缓冲，已经开始播放，资源正在缓冲
    JWZPlayerStatusPaused  // 暂停
};

@protocol JWZPlayerDelegate;

/**
 *  类 JWZPlayer 设计的目的是将 AVPlayer 和 AVPlayerLayer 封装成易于使用的 UIView 视图。
 */
@interface JWZPlayer : UIView

/**
 *  播放器状态。
 */
@property (nonatomic, readonly) JWZPlayerStatus status;

/**
 *  接收播放器事件的代理。
 */
@property (nonatomic, weak) id<JWZPlayerDelegate> delegate;

@property (nonatomic, strong, readonly) NSError *error;


- (instancetype)initWithMediaURL:(NSURL *)mediaURL;


- (void)replaceCurrentMediaWithURL:(NSURL *)mediaURL;

/**
 *  播放。其可能触发代理事件 -playerDidBeginPlaying: 被调用：
 *  1，播放器处于 stop 状态，如果资源准备好，立即触发代理事件；
 *  2，如果资源没有准备好，例如正在缓冲，则在资源播放时，触发代理事件；
 *  3，播放器处于 JWZPlayerStatusPaused 状态，不触发代理事件；
 *  4，资源不可用触发 -player:didFailToPlayWithError: 事件。
 */
- (void)play;

/**
 *  暂停播放。调用该方法不会直接触发代理事件。
 */
- (void)pause;

/**
 *  停止播放。调用该方法不会直接触发代理事件。
 */
- (void)stop;

/**
 *  当前已播放的时长。如果没有获取到时长，返回 NSNotFound 。
 *
 *  @return 已播放的时长，单位秒。
 */
- (NSTimeInterval)currentTime;
- (NSTimeInterval)duration;

@end

// JWZPlayer 事件代理
@protocol JWZPlayerDelegate <NSObject>

@optional

/**
 *  视频已经开始播放。调用 -[JWZPlayer play] 方法，资源开始播放后，此方法会被触发。
 *
 *  @param player 已经开始视频播放的 JWZPlayer 对象。
 */
- (void)playerDidStartPlaying:(JWZPlayer *)player;

/**
 *  如果是网络视频，播放有可能进入缓冲状态。
 *
 *  @param player 进入缓冲状态的 JWZPlayer 对象。
 */
- (void)playerDidStallPlaying:(JWZPlayer *)player;

/**
 *  如果缓冲完成，可以继续播放时，这个代理方法会被调用。
 *
 *  @param player 进入继续播放状态的 JWZPlayer 对象。
 */
- (void)playerDidContinuePlaying:(JWZPlayer *)player;

/**
 *  如果播放资源完成，此代理方法会被调用。如果是手动停止，这个代理方法，不会被调用。
 *
 *  @param player 播放完成了的 JWZPlayer 对象。
 */
- (void)playerDidFinishPlaying:(JWZPlayer *)player;

/**
 *  播放失败。
 *
 *  @param player 播发器对象
 */
- (void)playerDidFailToPlayToEndTime:(JWZPlayer *)player;

/**
 *  这个方法用于跟踪缓冲进度。已完成的进度并非联系的。
 *
 *  @param player         触发事件的播放器 JWZPlayer 对象
 *  @param loadedDuration 已完成的进度
 */
- (void)player:(JWZPlayer *)player didLoadDuration:(NSTimeInterval)loadedDuration;

/**
 *  如果播放过程中发生不连续的情况，此代理方法会被调用。
 *
 *  @param player 触发事件的播放器 JWZPlayer 对象。
 */
- (void)playerDidJumpTime:(JWZPlayer *)player;


@end

