//
//  ViewController.m
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "ViewController.h"
#import "JWZPlayerController.h"

@import AVFoundation;
@import AVKit;

@interface ViewController () <JWZPlayerControllerDelegate>

@property (nonatomic, strong) NSURL *videoURL;

@property (weak, nonatomic) IBOutlet UIView *playerAvatar;
@property (weak, nonatomic) IBOutlet UIView *playerAvatar2;

@property (nonatomic, strong) JWZPlayerController *playerController;

@property (nonatomic, weak) UIView *videoPlayView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // RTMP
//    AVPlayerViewController
    // @"";http://mp4.68mtv.com/mp42/53184-%E5%AE%8B%E7%A5%96%E8%8B%B1-%E5%BD%A9%E9%BE%99%E8%88%9E%E4%B8%9C%E6%96%B9[68mtv.com].mp4
    //NSString *netUrl1 = @"http://mp4.68mtv.com/mp42/53184-%E5%AE%8B%E7%A5%96%E8%8B%B1-%E5%BD%A9%E9%BE%99%E8%88%9E%E4%B8%9C%E6%96%B9[68mtv.com].mp4";
//    NSString *netUrl2 = @"http://funsbar.file.alimmdn.com/video/activity/20160312114630732.mp4";
//    self.videoURL = [NSURL URLWithString:netUrl2];
    
    self.videoURL = [[NSBundle mainBundle] URLForResource:@"video" withExtension:@"mp4"];;
    self.videoPlayView = self.playerAvatar;
    
    self.playerController = [[JWZPlayerController alloc] init];
    self.playerController.delegate = self;
    

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    AVPlayerViewController *av = [[AVPlayerViewController alloc] init];
//    AVPlayer *player = [AVPlayer playerWithURL:self.videoURL];
//    av.player = player;
//    [self presentViewController:av animated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonAction:(id)sender {
    [self.playerController playWithMediaURL:self.videoURL displayMode:(JWZPlayerControllerDisplayModeEmbedded)];
}

- (IBAction)moveAction:(id)sender {
    if (self.videoPlayView == self.playerAvatar) {
        self.videoPlayView = self.playerAvatar2;
    } else {
        self.videoPlayView = self.playerAvatar;
    }
    [self presentViewController:self.playerController animated:YES completion:^{
        [self.playerController play];
    }];
}

#pragma mark - <JWZPlayerControllerDelegate>

- (UIViewController *)viewControllerForPresentingPlayerController:(JWZPlayerController *)playerController {
    return self;
}

- (UIView *)viewForDisplayingEmbeddedPlayer:(JWZPlayerController *)playerController {
    return self.videoPlayView;
}

@end
