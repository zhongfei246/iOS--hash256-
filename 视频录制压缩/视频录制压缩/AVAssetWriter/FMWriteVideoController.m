//
//  FMWriteVideoController.m
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/15.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753

#import "FMWriteVideoController.h"
#import "FMWVideoView.h"
#import "FMVideoPlayController.h"
#import "NSString+calculateSHA.h"

@interface FMWriteVideoController ()<FMWVideoViewDelegate>
@property (nonatomic, strong)FMWVideoView *videoView;
@end

@implementation FMWriteVideoController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = YES;
    
    _videoView  =[[FMWVideoView alloc] initWithFMVideoViewType:Type1X1];
    _videoView.delegate = self;
    [self.view addSubview:_videoView];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_videoView.fmodel.recordState == FMRecordStateFinish) {
        [_videoView.fmodel reset];
    }
}


- (void)dismissVC
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark ---------------------------------
#pragma mark --------录制结束
- (void)recordFinishWithvideoUrl:(NSURL *)videoUrl
{
    //这个URL是缓存到cache中的url，不是由相册来的
    NSLog(@"url(tiaozhuan)：%@",videoUrl);
    NSString * hash256String = [NSString getFileSHA256WithPath:[videoUrl path]];
    NSLog(@"sha1加密(tiaozhuan)：%@",hash256String);
    if (hash256String.length>0) {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"提示"
                                                                                  message: [NSString stringWithFormat:@"hash256:%@",hash256String]
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            FMVideoPlayController *playVC = [[FMVideoPlayController alloc] init];
            playVC.videoUrl =  videoUrl;
            [self.navigationController pushViewController:playVC animated:YES];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"提示"
                                                                                  message: @"计算失败！"
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


@end
