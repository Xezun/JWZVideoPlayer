//
//  JWZVideoPlayerView.h
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, JWZPlayerStatus) {
    JWZPlayerStatusStopped,
    JWZPlayerStatusWaiting,
    JWZPlayerStatusPlaying,
    JWZPlayerStatusStalled,
    JWZPlayerStatusPaused
};

@protocol JWZPlayerDelegate;
@class JWZPlayerMedia;


IB_DESIGNABLE @interface JWZPlayerView : UIView

// 播放器状态
@property (nonatomic, readonly) JWZPlayerStatus status;

// 当前播放的内容
@property (nonatomic, strong, readonly) JWZPlayerMedia *currentMedia;

// 接收播放器事件的代理
@property (nonatomic, weak) IBInspectable id<JWZPlayerDelegate> delegate;

/**
 *  构造方法。
 */
+ (instancetype)playerWithPlayerMedia:(JWZPlayerMedia *)playerMedia;
- (instancetype)initWithPlayerMedia:(JWZPlayerMedia *)playerMedia;
- (instancetype)initWithFrame:(CGRect)frame playerMedia:(JWZPlayerMedia *)playerMedia;

// 替换播放器中播放的对象
- (void)replaceCurrentMediaWithPlayerMedia:(JWZPlayerMedia *)playerMedia;

// 播放已加载到播放器里的内容
- (void)play;

// 暂停正在播放的内容
- (void)pause;

// 停止播放
- (void)stop;

// 当前已播放的时长。如果没有获取到时长，返回 NSNotFound 。
- (NSTimeInterval)currentTime;

@end


@protocol JWZPlayerDelegate <NSObject>

@optional

// 是否开始播放
- (void)playerDidBeginPlaying:(JWZPlayerView *)player;

- (void)playerDidStallPlaying:(JWZPlayerView *)player;
- (void)playerDidContinuePlaying:(JWZPlayerView *)player;

- (void)playerDidFinishPlaying:(JWZPlayerView *)player;

// 播放发生错误
- (void)player:(JWZPlayerView *)player didFailToPlayWithError:(NSError *)error;

// 缓冲进度
- (void)player:(JWZPlayerView *)player mediaBufferDidChange:(CGFloat)progress;

// 播放不连续
- (void)playerDidJumpTime:(JWZPlayerView *)player;


@end




/**
 *  该类的主要作用是自动创建 AVPlayerItem 并监视其状态，并将其状态返回给 JWZPlayer 。
 */
@interface JWZPlayerMedia : NSObject

/**
 *  媒体资源的链接。
 */
@property (nonatomic, strong) NSURL *resourceURL;

- (NSTimeInterval)duration;

@end



