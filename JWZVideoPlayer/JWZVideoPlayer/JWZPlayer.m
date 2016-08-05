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
#pragma mark - JWZPlayerMedia ()
#pragma mark - =================

@protocol JWZPlayerMediaDelegate <NSObject>

- (void)playerMediaStatusDidChange:(JWZPlayerMedia *)media;
- (void)playerMedia:(JWZPlayerMedia *)media didBufferWithProgress:(CGFloat)progress;

@end

@interface JWZPlayerMedia ()

@property (nonatomic, weak) id<JWZPlayerMediaDelegate> delegate;
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;
@property (nonatomic, strong) NSError *error;

@end



#pragma mark - ================
#pragma mark - JWZPlayerView ()
#pragma mark - ================

IB_DESIGNABLE @interface JWZPlayer () <JWZPlayerMediaDelegate>

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

#pragma mark - 属性

- (void)setMedia:(JWZPlayerMedia *)media {
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
        } else if (needToPlay) {
            [self stop];
        }
    }
}

- (void)setPlayer:(AVPlayer *)player {
    [[self playerLayer] setPlayer:player];
}

- (AVPlayer *)player {
    return [[self playerLayer] player];
}

#pragma mark - 主要方法，对外方法

- (void)play {
    if (self.media.playerItem != nil) {
        switch (self.status) {
            case JWZPlayerStatusStopped: {  // 播放器当前处于停止状态
                switch (self.media.status) {
                    case JWZPlayerMediaStatusAvailable: { // 资源可以播放
                        [self.media moveToStartTime:^(BOOL finished) {
                            if (finished) {
                                [self registerForAVPlayerItemNotification];
                                [self.player play];
                                [self JWZPlayer_AVPlayerDidBeginPlaying];
                            }
                        }];
                        break;
                    }
                    case JWZPlayerMediaStatusUnavailable: { // 资源无法播放
                        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didFailToPlayWithError:)]) {
                            [self.delegate player:self didFailToPlayWithError:[self.media error]];
                        }
                        break;
                    }
                    default: {  // 资源暂不可播放
                        [self registerForAVPlayerItemNotification];
                        self.status = JWZPlayerStatusWaiting;
                        break;
                    }
                }
                break;
            }
            case JWZPlayerStatusPaused: { // 播放器处于暂停状态
                [self registerForAVPlayerItemNotification];
                [self.player play];
                self.status = JWZPlayerStatusPlaying;
                // [self _JWZPlayer_AVPlayerDidBeginPlaying]; // 暂停状态恢复播放，不发送事件
                break;
            }
            default:
                break;
        }
    } else {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didFailToPlayWithError:)]) {
            [self.delegate player:self didFailToPlayWithError:[self.media error]];
        }
    }
}

/**
 *  播放器开始播放了。视频资源可用，真的开始播放了
 */
- (void)JWZPlayer_AVPlayerDidBeginPlaying {
    self.status = JWZPlayerStatusPlaying;  // 先改状态，然后启动播放
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidStartPlaying:)]) {
        [self.delegate playerDidStartPlaying:self];
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
            self.status = JWZPlayerStatusPaused;
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

#pragma mark - <JWZPlayerMediaDelegate>

- (void)playerMediaStatusDidChange:(JWZPlayerMedia *)playerMedia {
    switch (playerMedia.status) {
        case JWZPlayerMediaStatusNewMedia:
            [self pause];
            break;
        case JWZPlayerMediaStatusAvailable: { // 资源可以播放了
            switch (self.status) {
                case JWZPlayerStatusStalled:  // 当前是缓冲状态，直接进入播放状态
                case JWZPlayerStatusWaiting: {// 当前是等待状态，直接进入播放状态
                    [self.player play];
                    [self JWZPlayer_AVPlayerDidBeginPlaying];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case JWZPlayerMediaStatusBuffering:     // 正在缓冲
            break;
        case JWZPlayerMediaStatusUnavailable: {  // 资源不可用
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

- (void)playerMedia:(JWZPlayerMedia *)playerMedia didBufferWithProgress:(CGFloat)progress {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didBufferMediaWithProgress:)]) {
        [self.delegate player:self didBufferMediaWithProgress:progress];
    }
}


@end


#pragma mark - ==============
#pragma mark - JWZPlayerMedia
#pragma mark - ==============

// 被 JWZPlayerMedia 监视的 AVPlayerItem 属性的名，枚举值是为了方便使用数组。
typedef NS_ENUM(NSInteger, _JWZOberservedAVPlayerItemProperty) {
    _JWZOberservedAVPlayerItemPropertyStatus = 0,
    _JWZOberservedAVPlayerItemPropertyLoadedTimeRanges,
    _JWZOberservedAVPlayerItemPropertyPlaybackBufferEmpty,
    _JWZOberservedAVPlayerItemPropertyPlaybackLicklyToKeepUp,
    _JWZNumberOfOberservedAVPlayerItemProperties
};

static NSString *const kJWZObservedAVPlayerItemProperties[_JWZNumberOfOberservedAVPlayerItemProperties] = {
    @"status", @"loadedTimeRanges", @"playbackBufferEmpty", @"playbackLikelyToKeepUp"
};

@implementation JWZPlayerMedia

- (void)dealloc {
    JWZPlayerDebugLog(@"%s", __func__);
    if (_playerItem != nil) {
        [self stopObservingAVPlayerItemStatus:_playerItem];
        _playerItem = nil;
    }
}

+ (instancetype)playerMediaWithResourceURL:(NSURL *)resourceURL {
    return [[self alloc] initWithResourceURL:resourceURL];
}

- (instancetype)init {
    return [self initWithResourceURL:nil];
}

/**
 *  指定初始化方法。
 */
- (instancetype)initWithResourceURL:(NSURL *)resourceURL {
    self = [super init];
    if (self != nil) {
        _resourceURL = resourceURL;
        if (_resourceURL != nil) {
            _status = JWZPlayerMediaStatusNewMedia;
        }
    }
    return self;
}

- (void)replaceMediaResourceWithURL:(NSURL *)resourceURL {
    if (_resourceURL != resourceURL) {
        _resourceURL = resourceURL;
        [self JWZPlayerMedia_updatePlayerItem:nil];
        if (_resourceURL != nil) {
            [self JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatusNewMedia)];
        } else {
            _error = [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorInvalidSourceMedia userInfo:nil];
            [self JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatusUnavailable)];
        }
    }
}

- (void)JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatus)status {
    _status = status;
    if (_delegate != nil) {
        [_delegate playerMediaStatusDidChange:self];
    }
}

- (void)JWZPlayerMedia_playerItemWillChange {
    if (_playerItem != nil) {
        [self stopObservingAVPlayerItemStatus:_playerItem];
    }
}

- (void)JWZPlayerMedia_playerItemDidChange {
    if (_playerItem != nil) {
        [self startObservingAVPlayerItemStatus:_playerItem];
    }
}

@synthesize playerItem = _playerItem;

- (AVPlayerItem *)playerItem {
    if (_playerItem != nil) {
        return _playerItem;
    }
    [self JWZPlayerMedia_updatePlayerItem:[AVPlayerItem playerItemWithURL:_resourceURL]];
    if (_playerItem != nil) { // 新媒体载入
        // 获取初始状态
        if (_playerItem.status != AVPlayerItemStatusFailed) {
            [self JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatusNewMedia)];
            if ([_playerItem isPlaybackLikelyToKeepUp]) {
                NSArray<NSValue *> *seekableTimeRanges = [_playerItem seekableTimeRanges];
                if (seekableTimeRanges.count > 0) {
                    CMTime startTime = [[seekableTimeRanges firstObject] CMTimeRangeValue].start;
                    [_playerItem seekToTime:startTime completionHandler:^(BOOL finished) {
                        JWZPlayerDebugLog(@"新媒体载入");
                        [self JWZPlayerMedia_updateMediastatus:JWZPlayerMediaStatusAvailable];
                    }];
                }
            }
        } else {
            _error = _playerItem.error;
            [self JWZPlayerMedia_updatePlayerItem:nil];
            [self JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatusUnavailable)];
        }
    } else {
        _error = _playerItem.error;
        [self JWZPlayerMedia_updatePlayerItem:nil];
        [self JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatusUnavailable)];
    }
    return _playerItem;
}

/**
 *  更新 AVPlayerItem 。停止对旧的 Item 的监控，并开始监控新的 Item 的状态。
 *
 *  @param playerItem AVPlayerItem 对象。
 */
- (void)JWZPlayerMedia_updatePlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem != playerItem) {
        [self JWZPlayerMedia_playerItemWillChange];
        _playerItem = playerItem;
        [self JWZPlayerMedia_playerItemDidChange];
    }
}

- (NSTimeInterval)duration {
    if (self.status != JWZPlayerMediaStatusNewMedia && self.status != JWZPlayerMediaStatusUnavailable) {
        return CMTimeGetSeconds([_playerItem duration]);
    }
    return NSNotFound;
}

// 开始监听资源状态
- (void)startObservingAVPlayerItemStatus:(AVPlayerItem *)playerItem {
    for (NSInteger i = 0; i < _JWZNumberOfOberservedAVPlayerItemProperties; i++) {
        NSString *keyPath = kJWZObservedAVPlayerItemProperties[i];
        [playerItem addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew) context:nil];
    }
}

// 停止监听资源状态
- (void)stopObservingAVPlayerItemStatus:(AVPlayerItem *)playerItem {
    for (NSInteger i = 0; i < _JWZNumberOfOberservedAVPlayerItemProperties; i++) {
        NSString *keyPath = kJWZObservedAVPlayerItemProperties[i];
        [playerItem removeObserver:self forKeyPath:keyPath];
    }
}

// 处理监听
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.playerItem) {
        AVPlayerItem *playerItem = object;
        if ([keyPath isEqualToString:kJWZObservedAVPlayerItemProperties[_JWZOberservedAVPlayerItemPropertyStatus]]) {
            if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
                if (playerItem.isPlaybackLikelyToKeepUp) {
                    JWZPlayerDebugLog(@"Media：JWZPlayerMediaStatusAvailable");
                    [self JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatusAvailable)];
                } else {
                    JWZPlayerDebugLog(@"Media：JWZPlayerMediaStatusBuffering");
                    [self JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatusBuffering)];
                }
            } else if (playerItem.status == AVPlayerItemStatusFailed) {
                JWZPlayerDebugLog(@"Media：JWZPlayerMediaStatusUnavailable");
                _error = _playerItem.error;
                [self JWZPlayerMedia_updatePlayerItem:nil];
                [self JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatusUnavailable)];
            }
        } else if ([keyPath isEqualToString:kJWZObservedAVPlayerItemProperties[_JWZOberservedAVPlayerItemPropertyLoadedTimeRanges]]) {
            if (self.delegate != nil) {
                NSArray *loadedTimeRanges        = [[self playerItem] loadedTimeRanges];
                CMTimeRange timeRange            = [loadedTimeRanges.firstObject CMTimeRangeValue]; // 获取缓冲区域
                Float64 startTimeInSeconds       = CMTimeGetSeconds(timeRange.start);
                Float64 durationInSeconds        = CMTimeGetSeconds(timeRange.duration);
                NSTimeInterval completedDuration = startTimeInSeconds + durationInSeconds; // 计算缓冲总进度
                CMTime playerItemDuration        = [self playerItem].duration;
                NSTimeInterval totalDuration     = CMTimeGetSeconds(playerItemDuration);
                CGFloat progress                 = (completedDuration / totalDuration);
                [self.delegate playerMedia:self didBufferWithProgress:progress];
            }
        } else if ([keyPath isEqualToString:kJWZObservedAVPlayerItemProperties[_JWZOberservedAVPlayerItemPropertyPlaybackBufferEmpty]]) {
            if ([[self playerItem] isPlaybackBufferEmpty]) {
                JWZPlayerDebugLog(@"Media：JWZPlayerMediaStatusBuffering");
                [self JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatusBuffering)];
            }
        } else if ([keyPath isEqualToString:kJWZObservedAVPlayerItemProperties[_JWZOberservedAVPlayerItemPropertyPlaybackLicklyToKeepUp]]) {
            if ([[self playerItem] isPlaybackLikelyToKeepUp]) {
                JWZPlayerDebugLog(@"Media：JWZPlayerMediaStatusAvailable");
                [self JWZPlayerMedia_updateMediastatus:(JWZPlayerMediaStatusAvailable)];
            }
        }
    }
}

- (void)moveToStartTime:(void (^)(BOOL finished))completionHandler {
    if (self.status != JWZPlayerMediaStatusUnavailable && self.status != JWZPlayerMediaStatusNewMedia) {
        NSArray<NSValue *> *seekableTimeRanges = _playerItem.seekableTimeRanges;
        if (seekableTimeRanges != nil && seekableTimeRanges.count > 0) {
            CMTime time = [[seekableTimeRanges firstObject] CMTimeRangeValue].start;
            if (CMTIME_IS_VALID(time)) {
                [_playerItem seekToTime:time completionHandler:completionHandler];
            }
        }
    }
}

@end



