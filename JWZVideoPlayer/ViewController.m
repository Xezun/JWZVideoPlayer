//
//  ViewController.m
//  JWZVideoPlayer
//
//  Created by MJH on 16/3/13.
//  Copyright © 2016年 MXZ. All rights reserved.
//

#import "ViewController.h"
#import "JWZPlayerViewController.h"

@import AVFoundation;
@import AVKit;

@interface ViewController () <JWZPlayerViewControllerDelegate>

@property (nonatomic, strong) NSURL *videoURL;

@property (weak, nonatomic) IBOutlet UIView *playerAvatar;
@property (weak, nonatomic) IBOutlet UIView *playerAvatar2;

@property (nonatomic, strong) JWZPlayerViewController *playerController;

@property (nonatomic, weak) UIView *videoPlayView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoPlayView = self.playerAvatar;
    // RTMP
    // self.videoURL = [NSURL URLWithString:@"http://mp4.68mtv.com/mp42/53184-%E5%AE%8B%E7%A5%96%E8%8B%B1-%E5%BD%A9%E9%BE%99%E8%88%9E%E4%B8%9C%E6%96%B9[68mtv.com].mp4"];

    // self.videoURL = [NSURL URLWithString:@"http://funsbar.file.alimmdn.com/video/activity/20160312114630732.mp4"];
    
    self.videoURL = [[NSBundle mainBundle] URLForResource:@"video" withExtension:@"mp4"];
    self.playerController = [[JWZPlayerViewController alloc] init];
    self.playerController.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonAction:(id)sender {
    [self.playerController playWithMediaURL:self.videoURL displayMode:(JWZPlayerControllerDisplayModeEmbedded)];
}

#pragma mark - <JWZPlayerControllerDelegate>

- (UIViewController *)viewControllerForPresentingPlayerViewController:(JWZPlayerViewController *)playerViewController {
    return self;
}

- (UIView *)viewForDisplayingPlayerViewControllerInEmbeddedMode:(JWZPlayerViewController *)playerViewController {
    return self.videoPlayView;
}

@end
