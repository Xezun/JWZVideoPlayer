//
//  JWZPlayerPlaybackControls.h
//  JWZVideoPlayer
//
//  Created by iMac on 16/7/21.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWZPlayerController.h"

/**
 *  播放控制界面。
 */
@interface JWZPlayerPlaybackControls : UIView <JWZPlayerPlaybackControls>

@property (nonatomic, weak) JWZPlayerController *playerController;

@end
