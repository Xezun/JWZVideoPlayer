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

#pragma mark - =================
#pragma mark - JWZPlayerItem ()
#pragma mark - =================



@protocol JWZPlayerItemDelegate <NSObject>

- (void)playerItemStatusDidChange:(JWZPlayerItem *)media;
- (void)playerItem:(JWZPlayerItem *)media didBufferWithProgress:(CGFloat)progress;

@end

@interface JWZPlayerItem ()

@property (nonatomic, weak) id<JWZPlayerItemDelegate> delegate;
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;
@property (nonatomic, strong, readonly) NSError *error;

@end



// 被 JWZPlayerItem 监视的 AVPlayerItem 属性的名，枚举值是为了方便使用数组。
typedef NS_ENUM(NSInteger, _JWZPlayerObervedAVPlayerItemKeys) {
    _JWZPlayerObervedAVPlayerItemKeyStatus = 0,
    _JWZPlayerObervedAVPlayerItemKeyLoadedTimeRanges,
    _JWZPlayerObervedAVPlayerItemKeyPlaybackBufferEmpty,
    _JWZPlayerObervedAVPlayerItemKeyPlaybackLicklyToKeepUp,
    _JWZPlayerNumberOfObervedAVPlayerItemKeys
};

static NSString *const kJWZPlayerObservedAVPlayerItemKeys[_JWZPlayerNumberOfObervedAVPlayerItemKeys] = {
    @"status", @"loadedTimeRanges", @"playbackBufferEmpty", @"playbackLikelyToKeepUp"
};

#pragma mark - ================
#pragma mark - JWZPlayerView ()
#pragma mark - ================

IB_DESIGNABLE @interface JWZPlayer () <JWZPlayerItemDelegate>

@property (nonatomic) JWZPlayerStatus status;
@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayer *player;

- (AVPlayer *)player;

@end

#pragma mark - JWZPlayer Implementation

@implementation JWZPlayer

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self layer];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [self unregisterAVPlayerItemNotification];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (instancetype)initWithMediaURL:(NSURL *)mediaURL {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self != nil) {
        [self replaceCurrentMediaWithURL:mediaURL];
    }
    return self;
}

- (void)replaceCurrentMediaWithURL:(NSURL *)mediaURL {
    AVPlayer *player = [self player];
    AVPlayerItem *currentItem = [player currentItem];
    if (currentItem != nil) {
        for (NSInteger i = _JWZPlayerObervedAVPlayerItemKeyStatus; i < _JWZPlayerNumberOfObervedAVPlayerItemKeys; i++) {
            NSString *key = kJWZPlayerObservedAVPlayerItemKeys[i];
            [currentItem removeObserver:self forKeyPath:key];
        }
    }
    AVPlayerItem *newItem = [AVPlayerItem playerItemWithURL:mediaURL];
    if (newItem != nil) {
        for (NSInteger i = _JWZPlayerObervedAVPlayerItemKeyStatus; i < _JWZPlayerNumberOfObervedAVPlayerItemKeys; i++) {
            NSString *key = kJWZPlayerObservedAVPlayerItemKeys[i];
            [currentItem addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew) context:NULL];
        }
    }
    [player replaceCurrentItemWithPlayerItem:newItem];
}

#pragma mark - 属性

- (void)setMedia:(JWZPlayerItem *)media {
    if (media != _media) {
        BOOL needToPlay = NO;
        if (self.status != JWZPlayerStatusStopped) {
            [self pause];
            needToPlay = YES;
            _media.delegate = nil;
        }
        _media = media;
        if (_media != nil) {
            _media.delegate = self;
            AVPlayer *player = [self player];
            if (player == nil) {
                player = [AVPlayer playerWithPlayerItem:_media.playerItem];
                self.player = player;
            } else {
                [self.player replaceCurrentItemWithPlayerItem:_media.playerItem];
            }
            if (needToPlay) {
                [self play];
            }
        } else {
            [self stop];
        }
    }
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

- (NSError *)error {
    return [[[self player] currentItem] error];
}

#pragma mark - 主要方法，对外方法

- (void)play {
    if ([self error] == nil) {
        [self JWZPlayer_AVPlayerDidFailToPlayWithError:[self error]];
        return;
    }
    if ([[[self player] currentItem] isPlaybackLikelyToKeepUp]) {
        [self registerForAVPlayerItemNotification];
        [self play];
        [self JWZPlayer_AVPlayerDidStartPlaying];
    } else {
        [self registerForAVPlayerItemNotification];
        [self play];
    }
}

- (void)pause {
    switch (self.status) {
        case JWZPlayerStatusStopped:
        case JWZPlayerStatusPaused:
            break;
        default: {
            [self unregisterAVPlayerItemNotification];
            [[self player] pause];
            [self JWZPlayer_AVPlayerDidPausePlaying];
            break;
        }
    }
}

- (void)stop {
    switch (self.status) {
        case JWZPlayerStatusStopped:
            break;
        default: {
            __weak typeof(self) weakSelf = self;
            [[weakSelf player] pause];
            [self.media moveToStartTime:^(BOOL finished) {
                weakSelf.status = JWZPlayerStatusStopped;
                [weakSelf unregisterAVPlayerItemNotification];
            }];
            break;
        }
    }
}

- (NSTimeInterval)currentTime {
    if ([self player] != nil && _media != nil) {
        CMTime time = [[self player] currentTime];
        if (CMTIME_IS_VALID(time)) {
            return CMTimeGetSeconds(time);
        }
        return NSNotFound;
    }
    return NSNotFound;
}

#pragma mark - 自定义方法

/**
 *  注册 AVPlayerItem 的播放状态通知
 */
- (void)registerForAVPlayerItemNotification {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(JWZPlayer_AVPlayerItemDidPlayToEndTime:)
                               name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(JWZPlayer_AVPlayerItemFailedToPlayToEndTime:)
                               name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(JWZPlayer_AVPlayerItemPlaybackStalled:)
                               name:AVPlayerItemPlaybackStalledNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(JWZPlayer_AVPlayerItemTimeJumped:)
                               name:AVPlayerItemTimeJumpedNotification object:nil];
}

- (void)unregisterAVPlayerItemNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  播放器开始播放了。视频资源可用，真的开始播放了
 */
- (void)JWZPlayer_AVPlayerDidStartPlaying {
    self.status = JWZPlayerStatusPlaying;  
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidStartPlaying:)]) {
        [self.delegate playerDidStartPlaying:self];
    }
}

- (void)JWZPlayer_AVPlayerDidFailToPlayWithError:(NSError *)error {
    _status = JWZPlayerStatusStopped;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didFailToPlayWithError:)]) {
        [self.delegate player:self didFailToPlayWithError:error];
    }
}

- (void)JWZPlayer_AVPlayerDidPausePlaying {
    _status = JWZPlayerStatusPaused;
}

- (void)JWZPlayer_AVPlayerDidStopPlaying {
    _status = JWZPlayerStatusStopped;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidFinishPlaying:)]) {
        [self.delegate playerDidFinishPlaying:self];
    }
}



#pragma mark - AVPlayerItem Notifications

// 播放完成
- (void)JWZPlayer_AVPlayerItemDidPlayToEndTime:(NSNotification *)notification {
    [self unregisterAVPlayerItemNotification];
    [[self player] pause];
    self.status = JWZPlayerStatusStopped;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidFinishPlaying:)]) {
        [self.delegate playerDidFinishPlaying:self];
    }
}

// 播放失败
- (void)JWZPlayer_AVPlayerItemFailedToPlayToEndTime:(NSNotification *)notification {
    [self unregisterAVPlayerItemNotification];
    [[self player] pause];
    self.status = JWZPlayerStatusStopped;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didFailToPlayWithError:)]) {
        [self.delegate player:self didFailToPlayWithError:[[self media] error]];
    }
}

// 播放停滞了
- (void)JWZPlayer_AVPlayerItemPlaybackStalled:(NSNotification *)notification {
    [[self player] pause];
    self.status = JWZPlayerStatusStalled;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidStallPlaying:)]) {
        [self.delegate playerDidStallPlaying:self];
    }
}

// 播放时间跳跃了
- (void)JWZPlayer_AVPlayerItemTimeJumped:(NSNotification *)notification {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidJumpTime:)]) {
        [self.delegate playerDidJumpTime:self];
    }
}

#pragma mark - <JWZPlayerItemDelegate>

- (void)playerItemStatusDidChange:(JWZPlayerItem *)playerMedia {
    switch (playerMedia.status) {
        case JWZPlayerItemStatusNewMedia:
            [self pause];
            break;
        case JWZPlayerItemStatusAvailable: { // 资源可以播放了
            switch (self.status) {
                case JWZPlayerStatusStalled:  // 当前是缓冲状态，直接进入播放状态
                case JWZPlayerStatusWaiting: {// 当前是等待状态，直接进入播放状态
                    [self.player play];
                    [self JWZPlayer_AVPlayerDidStartPlaying];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case JWZPlayerItemStatusBuffering:     // 正在缓冲
            break;
        case JWZPlayerItemStatusUnavailable: {  // 资源不可用
            if (self.status != JWZPlayerStatusStopped) {
                [self stop];
                if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didFailToPlayWithError:)]) {
                    [self.delegate player:self didFailToPlayWithError:[self.media error]];
                }
            }
            break;
        }
        default:
            break;
    }
}

- (void)playerItem:(JWZPlayerItem *)playerMedia didBufferWithProgress:(CGFloat)progress {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didBufferMediaWithProgress:)]) {
        [self.delegate player:self didBufferMediaWithProgress:progress];
    }
}

#pragma mark - <KVO>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.player.currentItem) {
        AVPlayerItem *playerItem = object;
        if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZPlayerObervedAVPlayerItemKeyStatus]]) {
            if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
                if (playerItem.isPlaybackLikelyToKeepUp) {
                    JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusAvailable");

                } else {
                    JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusBuffering");

                }
            } else if (playerItem.status == AVPlayerItemStatusFailed) {
                JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusUnavailable");

            }
        } else if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZPlayerObervedAVPlayerItemKeyLoadedTimeRanges]]) {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didBufferMediaWithProgress:)]) {
                NSArray *loadedTimeRanges        = [playerItem loadedTimeRanges];
                CMTimeRange timeRange            = [loadedTimeRanges.firstObject CMTimeRangeValue]; // 获取缓冲区域
                Float64 startTimeInSeconds       = CMTimeGetSeconds(timeRange.start);
                Float64 durationInSeconds        = CMTimeGetSeconds(timeRange.duration);
                NSTimeInterval completedDuration = startTimeInSeconds + durationInSeconds; // 计算缓冲总进度
                CMTime playerItemDuration        = playerItem.duration;
                NSTimeInterval totalDuration     = CMTimeGetSeconds(playerItemDuration);
                CGFloat progress                 = (completedDuration / totalDuration);
                [self.delegate player:self didBufferMediaWithProgress:progress];
            }
        } else if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZPlayerObervedAVPlayerItemKeyPlaybackBufferEmpty]]) {
            if ([playerItem isPlaybackBufferEmpty]) {
                JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusBuffering");
            }
        } else if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZPlayerObervedAVPlayerItemKeyPlaybackLicklyToKeepUp]]) {
            if ([playerItem isPlaybackLikelyToKeepUp]) {
                JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusAvailable");

            }
        }
    }
}

@end


#pragma mark - ==============
#pragma mark - JWZPlayerItem
#pragma mark - ==============

@implementation JWZPlayerItem

- (void)dealloc {
    JWZPlayerDebugLog(@"%s", __func__);
    if (_playerItem != nil) {
        [self JWZPlayerItem_stopObservingAVPlayerItemStatus:_playerItem];
        _playerItem = nil;
    }
}

+ (instancetype)playerItemWithResourceURL:(NSURL *)resourceURL {
    return [[self alloc] initWithResourceURL:resourceURL];
}

- (instancetype)init {
    return [self initWithResourceURL:nil];
}

- (NSError *)error {
    return [self.playerItem error];
}

/**
 *  指定初始化方法。
 */
- (instancetype)initWithResourceURL:(NSURL *)resourceURL {
    self = [super init];
    if (self != nil) {
        _resourceURL = resourceURL;
        if (_resourceURL != nil) {
            _status = JWZPlayerItemStatusNewMedia;
        }
    }
    return self;
}

- (void)replaceMediaResourceWithURL:(NSURL *)resourceURL {
    if (_resourceURL != resourceURL) {
        _resourceURL = resourceURL;
        [self setPlayerItem:[AVPlayerItem playerItemWithURL:_resourceURL]];
    }
}

/**
 *  更新状态并发送代理事件。
 */
- (void)JWZPlayerItem_updateMediastatus:(JWZPlayerItemStatus)status {
    _status = status;
    if (_delegate != nil) {
        [_delegate playerItemStatusDidChange:self];
    }
}

/**
 *  更新 AVPlayerItem 。停止对旧的 Item 的监控，并开始监控新的 Item 的状态。
 *
 *  @param playerItem AVPlayerItem 对象。
 */
- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem != playerItem) {
        if (_playerItem != nil) {
            [self JWZPlayerItem_stopObservingAVPlayerItemStatus:_playerItem];
        }
        _playerItem = playerItem;
        if (_playerItem != nil) { // 新媒体载入
            [self JWZPlayerItem_updateMediastatus:(JWZPlayerItemStatusNewMedia)];
            switch (_playerItem.status) {
                case AVPlayerItemStatusUnknown:
                    break;
                case AVPlayerItemStatusReadyToPlay:
                    [self JWZPlayerItem_updateMediastatus:(JWZPlayerItemStatusAvailable)];
                    break;
                case AVPlayerItemStatusFailed:
                    [self JWZPlayerItem_updateMediastatus:(JWZPlayerItemStatusUnavailable)];
                    break;
                default:
                    break;
            }
            [self JWZPlayerItem_startObservingAVPlayerItemStatus:_playerItem];
        } else {
            [self JWZPlayerItem_updateMediastatus:(JWZPlayerItemStatusUnavailable)];
        }
    }
}

- (NSTimeInterval)duration {
    if (self.status != JWZPlayerItemStatusNewMedia && self.status != JWZPlayerItemStatusUnavailable) {
        return CMTimeGetSeconds([self.playerItem duration]);
    }
    return NSNotFound;
}

// 开始监听资源状态
- (void)JWZPlayerItem_startObservingAVPlayerItemStatus:(AVPlayerItem *)playerItem {
    for (NSInteger i = 0; i < _JWZPlayerNumberOfObervedAVPlayerItemKeys; i++) {
        NSString *keyPath = kJWZPlayerObservedAVPlayerItemKeys[i];
        [playerItem addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew) context:nil];
    }
}

// 停止监听资源状态
- (void)JWZPlayerItem_stopObservingAVPlayerItemStatus:(AVPlayerItem *)playerItem {
    for (NSInteger i = 0; i < _JWZPlayerNumberOfObervedAVPlayerItemKeys; i++) {
        NSString *keyPath = kJWZPlayerObservedAVPlayerItemKeys[i];
        [playerItem removeObserver:self forKeyPath:keyPath];
    }
}

// 处理监听
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.playerItem) {
        AVPlayerItem *playerItem = object;
        if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZPlayerObervedAVPlayerItemKeyStatus]]) {
            if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
                if (playerItem.isPlaybackLikelyToKeepUp) {
                    JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusAvailable");
                    [self JWZPlayerItem_updateMediastatus:(JWZPlayerItemStatusAvailable)];
                } else {
                    JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusBuffering");
                    [self JWZPlayerItem_updateMediastatus:(JWZPlayerItemStatusBuffering)];
                }
            } else if (playerItem.status == AVPlayerItemStatusFailed) {
                JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusUnavailable");
                [self JWZPlayerItem_updateMediastatus:(JWZPlayerItemStatusUnavailable)];
            }
        } else if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZPlayerObervedAVPlayerItemKeyLoadedTimeRanges]]) {
            if (self.delegate != nil) {
                NSArray *loadedTimeRanges        = [[self playerItem] loadedTimeRanges];
                CMTimeRange timeRange            = [loadedTimeRanges.firstObject CMTimeRangeValue]; // 获取缓冲区域
                Float64 startTimeInSeconds       = CMTimeGetSeconds(timeRange.start);
                Float64 durationInSeconds        = CMTimeGetSeconds(timeRange.duration);
                NSTimeInterval completedDuration = startTimeInSeconds + durationInSeconds; // 计算缓冲总进度
                CMTime playerItemDuration        = [self playerItem].duration;
                NSTimeInterval totalDuration     = CMTimeGetSeconds(playerItemDuration);
                CGFloat progress                 = (completedDuration / totalDuration);
                [self.delegate playerItem:self didBufferWithProgress:progress];
            }
        } else if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZPlayerObervedAVPlayerItemKeyPlaybackBufferEmpty]]) {
            if ([[self playerItem] isPlaybackBufferEmpty]) {
                JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusBuffering");
                [self JWZPlayerItem_updateMediastatus:(JWZPlayerItemStatusBuffering)];
            }
        } else if ([keyPath isEqualToString:kJWZPlayerObservedAVPlayerItemKeys[_JWZPlayerObervedAVPlayerItemKeyPlaybackLicklyToKeepUp]]) {
            if ([[self playerItem] isPlaybackLikelyToKeepUp]) {
                JWZPlayerDebugLog(@"Media：JWZPlayerItemStatusAvailable");
                [self JWZPlayerItem_updateMediastatus:(JWZPlayerItemStatusAvailable)];
            }
        }
    }
}

- (void)moveToStartTime:(void (^)(BOOL finished))completionHandler {
    if (self.status != JWZPlayerItemStatusUnavailable && self.status != JWZPlayerItemStatusNewMedia) {
        NSArray<NSValue *> *seekableTimeRanges = self.playerItem.seekableTimeRanges;
        if (seekableTimeRanges != nil && seekableTimeRanges.count > 0) {
            CMTime time = [[seekableTimeRanges firstObject] CMTimeRangeValue].start;
            if (CMTIME_IS_VALID(time)) {
                [self.playerItem seekToTime:time completionHandler:completionHandler];
            }
        }
    }
}

@end



