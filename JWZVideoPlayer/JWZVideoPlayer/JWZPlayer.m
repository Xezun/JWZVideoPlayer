//
//  JWZVideoPlayerView.m
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "JWZPlayer.h"

#ifdef JWZPlayerDebugLog
#undef JWZPlayerDebugLog
#endif

#if DEBUG
#define JWZPlayerDebugLog(...) NSLog(__VA_ARGS__)
#else
#define JWZPlayerDebugLog(...);
#endif

@import AVFoundation;
@import AVKit;

// 被 JWZPlayerItem 监视的 AVPlayerItem 属性的名，枚举值是为了方便使用数组。
typedef NS_ENUM(NSInteger, _JWZKVOKeys) {
    _JWZKVO_status = 0,
    _JWZKVO_loadedTimeRanges,
    _JWZKVO_playbackBufferEmpty,
    _JWZKVO_playbackLicklyToKeepUp,
    _JWZNumberOfKVOKeys
};

static NSString *const kJWZPlayerObservedAVPlayerItemKeys[_JWZNumberOfKVOKeys] = {
    @"status", @"loadedTimeRanges", @"playbackBufferEmpty", @"playbackLikelyToKeepUp"
};

#pragma mark - ================
#pragma mark - JWZPlayerView ()
#pragma mark - ================

IB_DESIGNABLE @interface JWZPlayer ()

- (AVPlayer *)player;
- (void)setPlayer:(AVPlayer *)player;

- (AVPlayerLayer *)playerLayer;
- (AVPlayerItem *)currentItem;

@end

#pragma mark - JWZPlayer Implementation

@implementation JWZPlayer

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)dealloc {
    AVPlayerItem *currentItem = [[self player] currentItem];
    if (currentItem != nil) {
        [self JWZPlayer_unregisterNotificationForAVPlayerItem:currentItem];
    }
}

- (instancetype)initWithMediaURL:(NSURL *)mediaURL {
    self = [self initWithFrame:CGRectMake(0, 0, 320, 240)];
    if (self != nil) {
        [self replaceCurrentMediaWithURL:mediaURL];
    }
    return self;
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self layer];
}

- (void)setPlayer:(AVPlayer *)player {
    [[self playerLayer] setPlayer:player];
}

- (AVPlayer *)player {
    AVPlayer *player = [[self playerLayer] player];
    if (player != nil) {
        return player;
    }
    player = [[AVPlayer alloc] init];
    [self setPlayer:player];
    return player;
}

- (AVPlayerItem *)currentItem {
    return [[self player] currentItem];
}

- (NSTimeInterval)duration {
    return CMTimeGetSeconds([[self currentItem] duration]);
}

- (NSError *)error {
    return [[self currentItem] error];
}

- (NSTimeInterval)currentTime {
    CMTime time = [[self player] currentTime];
    return CMTimeGetSeconds(time);
}

- (void)replaceCurrentMediaWithURL:(NSURL *)mediaURL {
    AVPlayer *player = [self player];
    AVPlayerItem *currentItem = [player currentItem];
    if (currentItem != nil) {
        for (NSInteger i = _JWZKVO_status; i < _JWZNumberOfKVOKeys; i++) {
            NSString *key = kJWZPlayerObservedAVPlayerItemKeys[i];
            [currentItem removeObserver:self forKeyPath:key];
        }
    }
    AVPlayerItem *newItem = [AVPlayerItem playerItemWithURL:mediaURL];
    if (newItem != nil) {
        for (NSInteger i = _JWZKVO_status; i < _JWZNumberOfKVOKeys; i++) {
            NSString *key = kJWZPlayerObservedAVPlayerItemKeys[i];
            [newItem addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew) context:NULL];
        }
    }
    [player replaceCurrentItemWithPlayerItem:newItem];
}

#pragma mark - 主要方法，对外方法

- (void)play {
    switch (_status) {
        case JWZPlayerStatusStalled:
        case JWZPlayerStatusWaiting:
        case JWZPlayerStatusPlaying:
            // 这三种状态不需要取做任何操作
            break;
        case JWZPlayerStatusPaused: {
            [self JWZPlayer_registerNotificationForAVPlayerItem:[self currentItem]];
            [[self player] play];
            break;
        }
        case JWZPlayerStatusStopped: {
            if ([self error] != nil) {
                AVURLAsset *urlAsset = (AVURLAsset *)[self currentItem].asset;
                if ([urlAsset isMemberOfClass:[AVURLAsset class]]) {
                    [self replaceCurrentMediaWithURL:urlAsset.URL];
                    [self play];
                }
            } else {
                [self JWZPlayer_registerNotificationForAVPlayerItem:[self currentItem]];
                _status = JWZPlayerStatusWaiting;
                if ([[self currentItem] isPlaybackLikelyToKeepUp]) {
                    [self JWZPlayer_moveToStartTime:^(BOOL finished) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self JWZPlayer_AVPlayerItemStatusAvailable];
                        });
                    }];
                }
            }
        }
        default:
            break;
    }
}

- (void)pause {
    switch (self.status) {
        case JWZPlayerStatusStopped:
        case JWZPlayerStatusPaused:
            // 处于这两种状态时，不需要进行任何操作
            break;
        default: {
            [self JWZPlayer_unregisterNotificationForAVPlayerItem:[self currentItem]];
            [[self player] pause];
            _status = JWZPlayerStatusPaused;
            break;
        }
    }
}

- (void)stop {
    switch (self.status) {
        case JWZPlayerStatusStopped:
            break;
        default: {
            [self JWZPlayer_unregisterNotificationForAVPlayerItem:[self currentItem]];
            [[self player] pause];
            _status = JWZPlayerStatusPaused;
            [self JWZPlayer_moveToStartTime:NULL];
            break;
        }
    }
}

#pragma mark - 属性



#pragma mark - 私有方法

/**
 *  注册 AVPlayerItem 的状态通知。
 *
 *  @param playerItem 要监听的 AVPlayerItem 对象。
 */
- (void)JWZPlayer_registerNotificationForAVPlayerItem:(AVPlayerItem *)playerItem {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(JWZPlayer_AVPlayerItemDidPlayToEndTime:)
                               name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    [notificationCenter addObserver:self selector:@selector(JWZPlayer_AVPlayerItemFailedToPlayToEndTime:)
                               name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
    [notificationCenter addObserver:self selector:@selector(JWZPlayer_AVPlayerItemPlaybackStalled:)
                               name:AVPlayerItemPlaybackStalledNotification object:playerItem];
    [notificationCenter addObserver:self selector:@selector(JWZPlayer_AVPlayerItemTimeJumped:)
                               name:AVPlayerItemTimeJumpedNotification object:playerItem];
}

/**
 *  解注册对 AVPlayerItem 的状态监听通知。
 *
 *  @param playerItem 要解除监听的 AVPlayerItem 的对象。
 */
- (void)JWZPlayer_unregisterNotificationForAVPlayerItem:(AVPlayerItem *)playerItem {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    [notificationCenter removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
    [notificationCenter removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:playerItem];
    [notificationCenter removeObserver:self name:AVPlayerItemTimeJumpedNotification object:playerItem];
}

- (void)JWZPlayer_moveToStartTime:(void (^)(BOOL finished))completionHandler {
    AVPlayerItem *playerItem = [self currentItem];
    if (playerItem != nil) {
        NSArray<NSValue *> *seekableTimeRanges = playerItem.seekableTimeRanges;
        if (seekableTimeRanges != nil && seekableTimeRanges.count > 0) {
            CMTime time = [[seekableTimeRanges firstObject] CMTimeRangeValue].start;
            [playerItem seekToTime:time completionHandler:completionHandler];
        } else {
            completionHandler(NO);
        }
    } else {
        completionHandler(NO);
    }
}

#pragma mark - AVPlayerItem Notifications

// 播放完成
- (void)JWZPlayer_AVPlayerItemDidPlayToEndTime:(NSNotification *)notification {
    if (notification.object == [self currentItem]) {
        [self JWZPlayer_unregisterNotificationForAVPlayerItem:[self currentItem]];
        [[self player] pause];
        _status = JWZPlayerStatusStopped;
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidFinishPlaying:)]) {
            [self.delegate playerDidFinishPlaying:self];
        }
    }
}

// 播放失败
- (void)JWZPlayer_AVPlayerItemFailedToPlayToEndTime:(NSNotification *)notification {
    if (notification.object == [self currentItem]) {
        [self JWZPlayer_unregisterNotificationForAVPlayerItem:[self currentItem]];
        [[self player] pause];
        _status = JWZPlayerStatusStopped;
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidFailToPlayToEndTime:)]) {
            [self.delegate playerDidFailToPlayToEndTime:self];
        }
    }
}

// 播放停滞了
- (void)JWZPlayer_AVPlayerItemPlaybackStalled:(NSNotification *)notification {
    if (notification.object == [self currentItem]) {
        [[self player] pause];
        _status = JWZPlayerStatusStalled;
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidStallPlaying:)]) {
            [self.delegate playerDidStallPlaying:self];
        }
    }
}

// 播放时间跳跃了
- (void)JWZPlayer_AVPlayerItemTimeJumped:(NSNotification *)notification {
    if (notification.object == [self currentItem]) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidJumpTime:)]) {
            [self.delegate playerDidJumpTime:self];
        }
    }
}

#pragma mark - KVO 方法

- (void)JWZPlayer_AVPlayerItemStatusAvailable {
    JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusAvailable");
    switch (self.status) {
        case JWZPlayerStatusStalled: { // 当前是缓冲状态，直接进入播放状态
            _status = JWZPlayerStatusPlaying;
            [[self player] play];
            if (_delegate != nil && [_delegate respondsToSelector:@selector(playerDidContinuePlaying:)]) {
                [_delegate playerDidContinuePlaying:self];
            }
            break;
        }
        case JWZPlayerStatusWaiting: { // 当前是等待状态，直接进入播放状态
            _status = JWZPlayerStatusPlaying;
            [self.player play];
            if (_delegate != nil && [_delegate respondsToSelector:@selector(playerDidStartPlaying:)]) {
                [_delegate playerDidStartPlaying:self];
            }
            break;
        }
        default:
            break;
    }
}

- (void)JWZPlayer_AVPlayerItemStatusBuffering {
    JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusBuffering");
    // [self JWZPlayer_AVPlayerDidStallPlaying];
}

- (void)JWZPlayer_AVPlayerItemStatusFailed {
    JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusUnavailable");
    _status = JWZPlayerStatusStopped;
    [[self player] pause];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidFailToPlayToEndTime:)]) {
        [self.delegate playerDidFailToPlayToEndTime:self];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == [self currentItem]) {
        AVPlayerItem *playerItem = object;
        if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZKVO_status]]) {
            switch (playerItem.status) {
                case AVPlayerItemStatusUnknown:
                    
                    break;
                case AVPlayerItemStatusReadyToPlay:
                    if (playerItem.isPlaybackLikelyToKeepUp) {
                        [self JWZPlayer_AVPlayerItemStatusAvailable];
                    } else {
                        [self JWZPlayer_AVPlayerItemStatusBuffering];
                    }
                    break;
                case AVPlayerItemStatusFailed:
                    [self JWZPlayer_AVPlayerItemStatusFailed];
                    break;
                default:
                    break;
            }
        } else if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZKVO_loadedTimeRanges]]) {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didLoadDuration:)]) {
                NSArray *loadedTimeRanges        = [playerItem loadedTimeRanges];
                NSTimeInterval completedDuration = 0;
                for (NSValue *timeRangeValue in loadedTimeRanges) {
                    CMTimeRange timeRange        = [timeRangeValue CMTimeRangeValue];
                    Float64 startTimeInSeconds   = CMTimeGetSeconds(timeRange.start);
                    Float64 durationInSeconds    = CMTimeGetSeconds(timeRange.duration);
                    completedDuration            = startTimeInSeconds + durationInSeconds; // 计算缓冲总进度
                }
                [self.delegate player:self didLoadDuration:completedDuration];
            }
        } else if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZKVO_playbackBufferEmpty]]) {
            if ([playerItem isPlaybackBufferEmpty]) {
                [self JWZPlayer_AVPlayerItemStatusBuffering];
            }
        } else if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZKVO_playbackLicklyToKeepUp]]) {
            if ([playerItem isPlaybackLikelyToKeepUp]) {
                [self JWZPlayer_AVPlayerItemStatusAvailable];
            }
        }
    }
}

@end
