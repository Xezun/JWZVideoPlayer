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

@interface JWZPlayerMedia ()

/**
 *  设置 status 属性会同时触发代理事件
 */
@property (nonatomic) JWZPlayerMediaStatus status;

@property (nonatomic, weak) id<JWZPlayerMediaDelegate> delegate;

/**
 *  设置 playerItem 属性会同时监听它的状态
 */
@property (nonatomic, strong) AVPlayerItem *playerItem;

- (JWZPlayerMediaStatus)status;
- (void)setStatus:(JWZPlayerMediaStatus)status;

/**
 *  媒体资源播放进度移动到开始。
 *
 *  @param completionHandler 如果执行操作时，已有正在进行的操作，block 会立即执行，finished = NO；如果操作没有被别的操作所打断，block 在执行时，finished = YES 。
 */
- (void)moveToStartTime:(void (^)(BOOL finished))completionHandler;

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
    if (self.media != nil && self.media.status != JWZPlayerMediaStatusUnavailable) {
        switch (self.status) {
            case JWZPlayerStatusStopped: {  // 播放器当前处于停止状态
                switch (self.media.status) {
                    case JWZPlayerMediaStatusAvailable: { // 资源可以播放
                        [self.media moveToStartTime:^(BOOL finished) {
                            if (finished) {
                                [self registerForAVPlayerItemNotification];
                                [self.player play];
                                [self _JWZPlayer_AVPlayerDidBeginPlaying];
                            }
                        }];
                        break;
                    }
                    case JWZPlayerMediaStatusUnavailable: { // 资源无法播放
                        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didFailToPlayWithError:)]) {
                            [self.delegate player:self didFailToPlayWithError:[self.media.playerItem error]];
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
    }
}

/**
 *  播放器开始播放了。视频资源可用，真的开始播放了
 */
- (void)_JWZPlayer_AVPlayerDidBeginPlaying {
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
    [notificationCenter addObserver:self selector:@selector(_JWZPlayer_AVPlayerItemDidPlayToEndTime:)
                               name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(_JWZPlayer_AVPlayerItemFailedToPlayToEndTime:)
                               name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(_JWZPlayer_AVPlayerItemPlaybackStalled:)
                               name:AVPlayerItemPlaybackStalledNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(_JWZPlayer_AVPlayerItemTimeJumped:)
                               name:AVPlayerItemTimeJumpedNotification object:nil];
}

- (void)unregisterAVPlayerItemNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - AVPlayerItem Notifications

// 播放完成
- (void)_JWZPlayer_AVPlayerItemDidPlayToEndTime:(NSNotification *)notification {
    [self unregisterAVPlayerItemNotification];
    [[self player] pause];
    self.status = JWZPlayerStatusStopped;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidFinishPlaying:)]) {
        [self.delegate playerDidFinishPlaying:self];
    }
}

// 播放失败
- (void)_JWZPlayer_AVPlayerItemFailedToPlayToEndTime:(NSNotification *)notification {
    [self unregisterAVPlayerItemNotification];
    [[self player] pause];
    self.status = JWZPlayerStatusStopped;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didFailToPlayWithError:)]) {
        [self.delegate player:self didFailToPlayWithError:[[[self media] playerItem] error]];
    }
}

// 播放停滞了
- (void)_JWZPlayer_AVPlayerItemPlaybackStalled:(NSNotification *)notification {
    [[self player] pause];
    self.status = JWZPlayerStatusStalled;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(playerDidStallPlaying:)]) {
        [self.delegate playerDidStallPlaying:self];
    }
}

// 播放时间跳跃了
- (void)_JWZPlayer_AVPlayerItemTimeJumped:(NSNotification *)notification {
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
                    [self _JWZPlayer_AVPlayerDidBeginPlaying];
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
            if (self.status == JWZPlayerStatusStopped) {
                [self stop];
                if (self.delegate != nil && [self.delegate respondsToSelector:@selector(player:didFailToPlayWithError:)]) {
                    [self.delegate player:self didFailToPlayWithError:[self.media.playerItem error]];
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
        if (resourceURL != nil) {
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:resourceURL];
            if (playerItem != nil) {
                if (playerItem.status != AVPlayerItemStatusFailed) {
                    if ([playerItem isPlaybackBufferFull]) {
                        _status = JWZPlayerMediaStatusAvailable;
                        NSArray<NSValue *> *seekableTimeRanges = [playerItem seekableTimeRanges];
                        if (seekableTimeRanges.count > 0) {
                            CMTime startTime = [[seekableTimeRanges firstObject] CMTimeRangeValue].start;
                            [playerItem seekToTime:startTime];
                        }
                    } else {
                        _status = JWZPlayerMediaStatusNewMedia;
                    }
                }
                _playerItem = playerItem;
            }
        } else {
            _status = JWZPlayerMediaStatusUnavailable;
        }
    }
    return self;
}

- (void)JWZPlayerMedia_resourceURLDidChange {
    if (_resourceURL == nil) {
        self.playerItem = nil;
        self.status = JWZPlayerMediaStatusUnavailable;
    } else {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:_resourceURL];
        [self setPlayerItem:playerItem];
        if (playerItem == nil) {
            self.status = JWZPlayerMediaStatusUnavailable;
        } else if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            self.status = JWZPlayerMediaStatusNewMedia;
            if ([playerItem isPlaybackBufferFull]) {
                NSArray<NSValue *> *seekableTimeRanges = playerItem.seekableTimeRanges;
                if (seekableTimeRanges != nil && seekableTimeRanges.count > 0) {
                    CMTime time = [[seekableTimeRanges firstObject] CMTimeRangeValue].start;
                    if (CMTIME_IS_VALID(time)) {
                        [playerItem seekToTime:time];
                    }
                }
                self.status = JWZPlayerMediaStatusAvailable;
            } else {
                self.status = JWZPlayerMediaStatusBuffering;
            }
        } else if (playerItem.status == AVPlayerItemStatusFailed) {
            self.status = JWZPlayerMediaStatusUnavailable;
        }
    }
}

- (void)setResourceURL:(NSURL *)resourceURL {
    if (_resourceURL != resourceURL) {
        _resourceURL = resourceURL;
        [self JWZPlayerMedia_resourceURLDidChange];
    }
}

- (void)_JWZPlayerMedia_statusDidChange {
    if (self.delegate != nil) {
        [self.delegate playerMediaStatusDidChange:self];
    }
}

- (void)setStatus:(JWZPlayerMediaStatus)status {
    if (_status != status) {
        _status = status;
        [self _JWZPlayerMedia_statusDidChange];
    }
}

- (void)_JWZPlayerMedia_playerItemWillChange {
    if (_playerItem != nil) {
        [self stopObservingAVPlayerItemStatus:_playerItem];
    }
}

- (void)_JWZPlayerMedia_playerItemDidChange {
    if (_playerItem != nil) {
        [self startObservingAVPlayerItemStatus:_playerItem];
    }
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem != playerItem) {
        [self _JWZPlayerMedia_playerItemWillChange];
        _playerItem = playerItem;
        [self _JWZPlayerMedia_playerItemDidChange];
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
                    self.status = JWZPlayerMediaStatusAvailable;
                } else {
                    JWZPlayerDebugLog(@"Media：JWZPlayerMediaStatusBuffering");
                    self.status = JWZPlayerMediaStatusBuffering;
                }
            } else if (playerItem.status == AVPlayerItemStatusFailed) {
                JWZPlayerDebugLog(@"Media：JWZPlayerMediaStatusUnavailable");
                self.status = JWZPlayerMediaStatusUnavailable;
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
                self.status = JWZPlayerMediaStatusBuffering;
            }
        } else if ([keyPath isEqualToString:kJWZObservedAVPlayerItemProperties[_JWZOberservedAVPlayerItemPropertyPlaybackLicklyToKeepUp]]) {
            if ([[self playerItem] isPlaybackLikelyToKeepUp]) {
                JWZPlayerDebugLog(@"Media：JWZPlayerMediaStatusAvailable");
                self.status = JWZPlayerMediaStatusAvailable;
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



