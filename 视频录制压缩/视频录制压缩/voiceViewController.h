//
//  voiceViewController.h
//  视频录制压缩
//
//  Created by lizhongfei on 27/10/17.
//  Copyright © 2017年 lizhongfei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface voiceViewController : UIViewController{
    IBOutlet UIImageView *soundLodingImageView;
    IBOutlet UIButton *playBtn;
    
    //录音器
    AVAudioRecorder *recorder;
    //播放器
    AVAudioPlayer *player;
    NSDictionary *recorderSettingsDict;
    
    //定时器
    NSTimer *timer;
    //图片组
    NSMutableArray *volumImages;
    double lowPassResults;
    
    //录音名字
    NSString *playName;
}

- (IBAction)downAction:(id)sender;
- (IBAction)upAction:(id)sender;

- (IBAction)playAction:(id)sender;

@end
