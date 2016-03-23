//
//  JWZVideoPlayerView.m
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "JWZPlayerView.h"

@import AVFoundation;

#pragma mark - JWZPlayerMedia ()
/**
 *  JWZPlayerMedia 的状态
 */
typedef NS_ENUM(NSInteger, JWZPlayerMediaStatus) {
    /**
     *  新媒体载入
     */
    JWZPlayerMediaStatusNewMedia,
    /**
     *  可以播放
     */
    JWZPlayerMediaStatusAvailable,
    /**
     *  缓冲中
     */
    JWZPlayerMediaStatusBuffering,
    /**
     *  不可用
     */
    JWZPlayerMediaStatusUnavailable
};

@protocol JWZPlayerMediaDelegate <NSObject>

- (void)playerMediaStatusDidChange:(JWZPlayerMedia *)media;
- (void)playerMedia:(JWZPlayerMedia *)media bufferDidChange:(CGFloat)progress;

@end

@interface JWZPlayerMedia ()

@property (nonatomic) JWZPlayerMediaStatus status;
@property (nonatomic, weak) id<JWZPlayerMediaDelegate> delegate;

@property (nonatomic, strong) AVPlayerItem *playerItem;

- (JWZPlayerMediaStatus)status;
- (void)setStatus:(JWZPlayerMediaStatus)status;

- (void)moveToStartTime:(void (^)(BOOL finished))completionHandler;

@end

#pragma mark - JWZPlayer ()

@interface JWZPlayerView () <JWZPlayerMediaDelegate>

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

- (AVPlayer *)player;

@end

#pragma mark - JWZPlayer Implementation

@implementation JWZPlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [self removePlayerItemNotificationObserver];
}

+ (instancetype)playerWithPlayerMedia:(JWZPlayerMedia *)playerMedia {
    return [[self alloc] initWithPlayerMedia:playerMedia];
}

- (instancetype)initWithPlayerMedia:(JWZPlayerMedia *)playerMedia {
    return [self initWithFrame:CGRectZero playerMedia:playerMedia];
}

- (instancetype)initWithFrame:(CGRect)frame playerMedia:(JWZPlayerMedia *)playerMedia {
    self = [super initWithFrame:frame];
    if (self != nil) {
        _currentMedia = playerMedia;
        _currentMedia.delegate = self;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_playerLayer != nil) {
        [CATransaction setDisableActions:YES]; // 关闭隐式动画
        _playerLayer.frame = self.bounds;
    }
}

- (void)setStatus:(JWZPlayerStatus)status {
    if (_status != status) {
        _status = status;
    }
}

- (void)preparePlayerLayerIfNeeded {
    if (_currentMedia != nil) {
        AVPlayerItem *playerItem = _currentMedia.playerItem;
        if (playerItem != nil) {
            if (_playerLayer != nil) {
                if (_playerLayer.player.currentItem != _currentMedia.playerItem) {
                    [_playerLayer.player replaceCurrentItemWithPlayerItem:playerItem];
                }
            } else {
                AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
                [player pause];
                _playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
                _playerLayer.delegate = self;
                [self.layer addSublayer:_playerLayer];
            }
        } else {
            if (_playerLayer != nil) {
                [_playerLayer.player replaceCurrentItemWithPlayerItem:nil];
            }
        }
    } else {
        if (_playerLayer != nil) {
            [_playerLayer.player replaceCurrentItemWithPlayerItem:nil];
        }
    }
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
    id<CAAction> acton = [super actionForLayer:layer forKey:event];
    NSLog(@"%s: %@", __func__, event);
    return acton;
}

- (void)replaceCurrentMediaWithPlayerMedia:(JWZPlayerMedia *)playerMedia {
    BOOL doPlayAfterReplace = NO;
    if (self.status != JWZPlayerStatusStopped) {
        [self pause];
        doPlayAfterReplace = YES;
    }
    if (_currentMedia != nil) {
        _currentMedia.delegate = nil;
    }
    _currentMedia = playerMedia;
    if (_currentMedia != nil) {
        _currentMedia.delegate = self;
    }
    if (doPlayAfterReplace) {
        [self play];
    }
}

- (void)play {
    if (self.currentMedia != nil && self.currentMedia.status != JWZPlayerMediaStatusUnavailable) {
        [self preparePlayerLayerIfNeeded];
        if (self.status == JWZPlayerStatusStopped) {
            if (self.currentMedia.status == JWZPlayerMediaStatusAvailable) {
                NSLog(@"播放：JWZPlayerMediaStatusAvailable");
                [self addPlayerItemNotificationObserver];
                [[self player] play];
                self.status = JWZPlayerStatusPlaying;
                if (self.delegate != nil) {
                    [self.delegate playerDidBeginPlaying:self];
                }
            } else if (self.currentMedia.status == JWZPlayerMediaStatusUnavailable) {
                NSLog(@"播放：JWZPlayerMediaStatusUnavailable");
                if (self.delegate != nil) {
                    [self.delegate player:self didFailToPlayWithError:[[self currentMedia].playerItem error]];
                }
            } else {
                NSLog(@"播放：%ld", self.currentMedia.status);
                [self addPlayerItemNotificationObserver];
                //[[self player] play];
                self.status = JWZPlayerStatusWaiting;
            }
        } else if (self.status == JWZPlayerStatusPaused) {
            [self addPlayerItemNotificationObserver];
            [[self player] play];
            self.status = JWZPlayerStatusPlaying;
        }
    }
}

- (void)pause {
    if (self.status != JWZPlayerStatusStopped && self.status != JWZPlayerStatusPaused) {
        [[self player] pause];
        self.status = JWZPlayerStatusPaused;
        [self removePlayerItemNotificationObserver];
    }
}

- (void)stop {
    if (self.status != JWZPlayerStatusStopped) {
        __weak typeof(self) weakSelf = self;
        [[weakSelf player] pause];
        [self.currentMedia moveToStartTime:^(BOOL finished) {
            weakSelf.status = JWZPlayerStatusStopped;
            [weakSelf removePlayerItemNotificationObserver];
        }];
    }

}

- (void)stall {
    self.status = JWZPlayerStatusStalled;
    [[self player] pause];
}

- (AVPlayer *)player {
    return [_playerLayer player];
}

- (NSTimeInterval)currentTime {
    if ([self player] != nil && _currentMedia != nil) {
        CMTime time = [[self player] currentTime];
        if (CMTIME_IS_VALID(time)) {
            return CMTimeGetSeconds(time);
        }
        return NSNotFound;
    }
    return NSNotFound;
}

// 收听播放状态
- (void)addPlayerItemNotificationObserver {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(playerItemDidPlayToEndTime:)
                               name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(playerItemFailedToPlayToEndTime:)
                               name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(playerItemPlaybackStalled:)
                               name:AVPlayerItemPlaybackStalledNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(playerItemTimeJumped:)
                               name:AVPlayerItemTimeJumpedNotification object:nil];
}

- (void)removePlayerItemNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 播放完成
- (void)playerItemDidPlayToEndTime:(NSNotification *)notification {
    __weak typeof(self) weakSelf = self;
    [self.currentMedia moveToStartTime:^(BOOL finished) {
        [[weakSelf player] pause];
        [weakSelf removePlayerItemNotificationObserver];
        weakSelf.status = JWZPlayerStatusStopped;
        if (weakSelf.delegate != nil) {
            [weakSelf.delegate playerDidFinishPlaying:weakSelf];
        }
    }];
}

// 播放失败
- (void)playerItemFailedToPlayToEndTime:(NSNotification *)notification {
    [[self player] pause];
    [self removePlayerItemNotificationObserver];
    self.status = JWZPlayerStatusStopped;
    if (self.delegate != nil) {
        [self.delegate player:self didFailToPlayWithError:[[[self currentMedia] playerItem] error]];
    }
}

// 播放停滞了
- (void)playerItemPlaybackStalled:(NSNotification *)notification {
    [[self player] pause];
    self.status = JWZPlayerStatusStalled;
    if (self.delegate != nil) {
        [self.delegate playerDidStallPlaying:self];
    }
}

// 播放时间跳跃了
- (void)playerItemTimeJumped:(NSNotification *)notification {
    if (self.delegate != nil) {
        [self.delegate playerDidJumpTime:self];
    }
}

- (void)playerMediaStatusDidChange:(JWZPlayerMedia *)playerMedia {
    switch (playerMedia.status) {
        case JWZPlayerMediaStatusNewMedia:
            // NSLog(@"JWZPlayerMediaStatusUnknown");
            [self pause];
            [self preparePlayerLayerIfNeeded];
            break;
        case JWZPlayerMediaStatusAvailable:  // 资源可以播放了
            // NSLog(@"JWZPlayerMediaStatusAvailable");
            if (self.status == JWZPlayerStatusStalled) {
                [[self player] play];
                self.status = JWZPlayerStatusPlaying;
                if (self.delegate != nil) {
                    [self.delegate playerDidContinuePlaying:self];
                }
            } else if (self.status == JWZPlayerStatusWaiting) {
                [[self player] play];
                if (self.delegate != nil) {
                    [self.delegate playerDidBeginPlaying:self];
                }
            }
            break;
        case JWZPlayerMediaStatusBuffering:
            // NSLog(@"JWZPlayerMediaStatusBuffering");
            break;
        case JWZPlayerMediaStatusUnavailable:
            // NSLog(@"JWZPlayerMediaStatusUnavailable");
            if (self.status == JWZPlayerStatusWaiting) {
                if (self.delegate != nil) {
                    [self.delegate player:self didFailToPlayWithError:[[[self currentMedia] playerItem] error]];
                }
            }
            break;
        default:
            break;
    }
}

- (void)playerMedia:(JWZPlayerMedia *)playerMedia bufferDidChange:(CGFloat)progress {
    if (self.delegate != nil) {
        [self.delegate player:self mediaBufferDidChange:progress];
    }
}


@end


#pragma mark - ++++++++++++++
#pragma mark - JWZPlayerMedia
#pragma mark - ++++++++++++++

// 被 JWZPlayerMedia 监视的 AVPlayerItem 属性的名，枚举值是为了方便使用数组。
typedef NS_ENUM(NSInteger, JWZOberservedAVPlayerItemProperty) {
    JWZOberservedAVPlayerItemPropertyStatus = 0,
    JWZOberservedAVPlayerItemPropertyLoadedTimeRanges,
    JWZOberservedAVPlayerItemPropertyPlaybackBufferEmpty,
    JWZOberservedAVPlayerItemPropertyPlaybackLicklyToKeepUp,
    JWZNumberOfOberservedAVPlayerItemProperties
};

static NSString *const kJWZObservedAVPlayerItemProperties[JWZNumberOfOberservedAVPlayerItemProperties] = {
    @"status", @"loadedTimeRanges", @"playbackBufferEmpty", @"playbackLikelyToKeepUp"
};

@implementation JWZPlayerMedia

- (void)dealloc {
    if (_playerItem != nil) {
        [self stopObservingMediaRescoureWithPlayerItem:_playerItem];
        _playerItem = nil;
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

/**
 *  设置资源链接。设置链接可能会更新 playerItem 属性。
 *
 *  @param resourceURL 媒体资源的URL
 */
- (void)setResourceURL:(NSURL *)resourceURL {
    if (_resourceURL != resourceURL) {
        _resourceURL = resourceURL;
        AVPlayerItem *playerItem = nil;
        if (_resourceURL != nil) {
            playerItem = [AVPlayerItem playerItemWithURL:_resourceURL];
        }
        [self setPlayerItem:playerItem];
        // 告诉代理，替换了新内容
        self.status = JWZPlayerMediaStatusNewMedia;
        if (playerItem != nil) {
            if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
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
        } else {
            self.status = JWZPlayerMediaStatusUnavailable;
        }
    }
}

@synthesize playerItem = _playerItem;
- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem != playerItem) {
        if (_playerItem != nil) {
            [self stopObservingMediaRescoureWithPlayerItem:_playerItem];
        }
        _playerItem = playerItem;
        if (_playerItem != nil) {
            [self startObservingMediaRescoureWithPlayerItem:_playerItem];
        }
    }
}

@synthesize status = _status;
- (JWZPlayerMediaStatus)status {
    return _status;
}

- (void)setStatus:(JWZPlayerMediaStatus)status {
    if (_status != status) {
        _status = status;
        if (self.delegate != nil) {
            [self.delegate playerMediaStatusDidChange:self];
        }
    }
}

- (NSTimeInterval)duration {
    if (self.status != JWZPlayerMediaStatusNewMedia && self.status != JWZPlayerMediaStatusUnavailable) {
        return CMTimeGetSeconds([_playerItem duration]);
    }
    return NSNotFound;
}

// 开始监听资源状态
- (void)startObservingMediaRescoureWithPlayerItem:(AVPlayerItem *)playerItem {
    for (NSInteger i = 0; i < JWZNumberOfOberservedAVPlayerItemProperties; i++) {
        NSString *keyPath = kJWZObservedAVPlayerItemProperties[i];
        [playerItem addObserver:self forKeyPath:keyPath options:(NSKeyValueObservingOptionNew) context:nil];
    }
}

// 停止监听资源状态
- (void)stopObservingMediaRescoureWithPlayerItem:(AVPlayerItem *)playerItem {
    for (NSInteger i = 0; i < JWZNumberOfOberservedAVPlayerItemProperties; i++) {
        NSString *keyPath = kJWZObservedAVPlayerItemProperties[i];
        [playerItem removeObserver:self forKeyPath:keyPath];
    }
}

// 处理监听
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.playerItem) {
        AVPlayerItem *playerItem = object;
        if ([keyPath isEqualToString:kJWZObservedAVPlayerItemProperties[JWZOberservedAVPlayerItemPropertyStatus]]) {
            if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
                if (playerItem.isPlaybackLikelyToKeepUp) {
                    NSLog(@"Media：JWZPlayerMediaStatusAvailable");
                    self.status = JWZPlayerMediaStatusAvailable;
                } else {
                    NSLog(@"Media：JWZPlayerMediaStatusBuffering");
                    self.status = JWZPlayerMediaStatusBuffering;
                }
            } else if (playerItem.status == AVPlayerItemStatusFailed) {
                NSLog(@"Media：JWZPlayerMediaStatusUnavailable");
                self.status = JWZPlayerMediaStatusUnavailable;
            }
        } else if ([keyPath isEqualToString:kJWZObservedAVPlayerItemProperties[JWZOberservedAVPlayerItemPropertyLoadedTimeRanges]]) {
            if (self.delegate != nil) {
                NSArray *loadedTimeRanges        = [[self playerItem] loadedTimeRanges];
                CMTimeRange timeRange            = [loadedTimeRanges.firstObject CMTimeRangeValue]; // 获取缓冲区域
                Float64 startTimeInSeconds       = CMTimeGetSeconds(timeRange.start);
                Float64 durationInSeconds        = CMTimeGetSeconds(timeRange.duration);
                NSTimeInterval completedDuration = startTimeInSeconds + durationInSeconds; // 计算缓冲总进度
                CMTime playerItemDuration        = [self playerItem].duration;
                NSTimeInterval totalDuration     = CMTimeGetSeconds(playerItemDuration);
                CGFloat progress                 = (completedDuration / totalDuration);
                [self.delegate playerMedia:self bufferDidChange:progress];
            }
        } else if ([keyPath isEqualToString:kJWZObservedAVPlayerItemProperties[JWZOberservedAVPlayerItemPropertyPlaybackBufferEmpty]]) {
            if ([[self playerItem] isPlaybackBufferEmpty]) {
                NSLog(@"Media：JWZPlayerMediaStatusBuffering");
                self.status = JWZPlayerMediaStatusBuffering;
            }
        } else if ([keyPath isEqualToString:kJWZObservedAVPlayerItemProperties[JWZOberservedAVPlayerItemPropertyPlaybackLicklyToKeepUp]]) {
            if ([[self playerItem] isPlaybackLikelyToKeepUp]) {
                NSLog(@"Media：JWZPlayerMediaStatusAvailable");
                self.status = JWZPlayerMediaStatusAvailable;
            }
        }
    }
}

@end



