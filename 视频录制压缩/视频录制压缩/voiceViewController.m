//
//  voiceViewController.m
//  视频录制压缩
//
//  Created by lizhongfei on 27/10/17.
//  Copyright © 2017年 lizhongfei. All rights reserved.
//

#import "voiceViewController.h"
#import "NSString+calculateSHA.h"

@interface voiceViewController ()

@end

@implementation voiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /**
     AVAudioSessionCategoryAmbient 或 kAudioSessionCategory_AmbientSound
     用于非以语音为主的应用，使用这个category的应用会随着静音键和屏幕关闭而静音。并且不会中止其它应用播放声音，可以和其它自带应用如iPod，safari等同时播放声音。注意：该Category无法在后台播放声音
     
     AVAudioSessionCategorySoloAmbient 或 kAudioSessionCategory_SoloAmbientSound
     类似于AVAudioSessionCategoryAmbient 不同之处在于它会中止其它应用播放声音。 这个category为默认category。该Category无法在后台播放声音
     
     AVAudioSessionCategoryPlayback 或 kAudioSessionCategory_MediaPlayback
     用于以语音为主的应用，使用这个category的应用不会随着静音键和屏幕关闭而静音。可在后台播放声音
     
     AVAudioSessionCategoryRecord 或 kAudioSessionCategory_RecordAudio
     用于需要录音的应用，设置该category后，除了来电铃声，闹钟或日历提醒之外的其它系统声音都不会被播放。该Category只提供单纯录音功能。
     
     AVAudioSessionCategoryPlayAndRecord 或 kAudioSessionCategory_PlayAndRecord
     用于既需要播放声音又需要录音的应用，语音聊天应用(如微信）应该使用这个category。该Category提供录音和播放功能。如果你的应用需要用到iPhone上的听筒，该category是你唯一的选择，在该Category下声音的默认出口为听筒（在没有外接设备的情况下）。
     
     注意：并不是一个应用只能使用一个category，程序应该根据实际需要来切换设置不同的category，举个例子，录音的时候，需要设置为AVAudioSessionCategoryRecord，当录音结束时，应根据程序需要更改category为AVAudioSessionCategoryAmbient，AVAudioSessionCategorySoloAmbient或AVAudioSessionCategoryPlayback中的一种。
     */
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        //7.0第一次运行会提示，是否允许使用麦克风
        AVAudioSession *session = [AVAudioSession sharedInstance];//单例AVAudioSession
        NSError *sessionError;
        //AVAudioSessionCategoryPlayAndRecord用于录音和播放
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        if(session == nil)
            NSLog(@"Error creating session: %@", [sessionError description]);
        else
            [session setActive:YES error:nil];
    }
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    playName = [NSString stringWithFormat:@"%@/play.aac",docDir];
    //录音设置
    recorderSettingsDict =[[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,
                           [NSNumber numberWithInt:1000.0],AVSampleRateKey,
                           [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
                           [NSNumber numberWithInt:8],AVLinearPCMBitDepthKey,
                           [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                           [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                           nil];
    //音量图片数组
    volumImages = [[NSMutableArray alloc]initWithObjects:@"RecordingSignal001",@"RecordingSignal002",@"RecordingSignal003",
                   @"RecordingSignal004", @"RecordingSignal005",@"RecordingSignal006",
                   @"RecordingSignal007",@"RecordingSignal008",nil];
    
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)back:(id)sender {
    recorder = nil;
    player = nil;
    //结束定时器
    [timer invalidate];
    timer = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:playName]) {
        NSError * error = nil;
        [fileManager removeItemAtPath:playName error:&error];
        if (error != nil) {
            NSLog(@"错误为：%@",error);
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)downAction:(id)sender {
    //按下录音
    if ([self canRecord]) {
        
        NSError *error = nil;
        //必须真机上测试,模拟器上会崩溃
        recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:playName] settings:recorderSettingsDict error:&error];
        
        if (recorder) {
            recorder.meteringEnabled = YES;
            [recorder prepareToRecord];//creates the file and gets ready to record. happens automatically on record.
            [recorder record];//start or resume recording to file.
            
            //启动定时器
            timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(levelTimer:) userInfo:nil repeats:YES];
            
        } else {
            int errorCode = CFSwapInt32HostToBig ([error code]);//小端转大端（数据内存中数据存储方式）
            NSLog(@"Error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode);
        }
    }
    
}

- (IBAction)upAction:(id)sender {

    static int upDpwnFlag = 0;
    if (upDpwnFlag == 0) {
        if ([self canRecord]) {
            
            NSError *error = nil;
            //必须真机上测试,模拟器上会崩溃
            recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:playName] settings:recorderSettingsDict error:&error];
            
            if (recorder) {
                recorder.meteringEnabled = YES;
                [recorder prepareToRecord];//creates the file and gets ready to record. happens automatically on record.
                [recorder record];//start or resume recording to file.
                
                upDpwnFlag =1;
                UIButton * btn = (UIButton *)sender;
                [btn setTitle:@"正在录音" forState:normal];
                [btn setTitle:@"正在录音" forState:normal];
                
                //启动定时器
                timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(levelTimer:) userInfo:nil repeats:YES];
                
            } else {
                int errorCode = CFSwapInt32HostToBig ([error code]);//小端转大端（数据内存中数据存储方式）
                NSLog(@"Error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode);
            }
        } else {
            NSLog(@"开启失败");
        }
    } else {
        upDpwnFlag = 0;
        UIButton * btn = (UIButton *)sender;
        [btn setTitle:@"点击录音开始" forState:normal];
        [btn setTitle:@"点击录音开始" forState:normal];
        //录音停止
        [recorder stop];
        recorder = nil;
        //结束定时器
        [timer invalidate];
        timer = nil;
        //图片重置
        soundLodingImageView.image = [UIImage imageNamed:[volumImages objectAtIndex:0]];
        
        NSString * hash256String = [NSString getFileSHA256WithPath:playName];
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"提示"
                                                                                  message: [NSString stringWithFormat:@"hash256:%@",hash256String]
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction)playAction:(id)sender {
    
    NSError *playerError;
    
    //播放
    player = nil;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:playName] error:&playerError];
    if (player == nil)
    {
        NSLog(@"ERror creating player: %@", [playerError description]);
    }else{
        [player play];
    }
    
    NSString * hash256String = [NSString getFileSHA256WithPath:playName];
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"提示"
                                                                              message: [NSString stringWithFormat:@"hash256:%@",hash256String]
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

-(void)levelTimer:(NSTimer*)timer_
{
    //重点：直接调用prepareToRecord准备，调用record开始写入，利用定时器主要是为了UI换图片（其中使用了低频滤波算法）
    //call to refresh meter values刷新平均和峰值功率
    //此计数是以对数刻度计量的,-160表示完全安静，0表示最大输入值, 为方便，我们将其转换为0-1,0代表完全安静，1代表最大音量。
    [recorder updateMeters];
    const double ALPHA = 0.05;
    //peakPowerForChannel 获得指定声道的分贝峰值，注意如果要获得分贝峰值必须在此之前调用updateMeters方法
    double peakPowerForChannel = pow(10, (0.05 * [recorder peakPowerForChannel:0]));//a的b次方（例）double val = pow(2, 3);→8  （这样之后就可以转化到0-1之间）
    lowPassResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * lowPassResults;//lowPassResults通过低频滤波算法得到（噪声/声音是由低频声音组成的。我们将使用low pass filter（低频滤波） 来降低来自麦克的高频声音；当滤波信号的电平等级突然增大时，我们就知道有人向麦克说话了。）
    //averagePowerForChannel 获得指定声道的分贝平均值，注意如果要获得分贝平均值必须在此之前调用updateMeters方法
    NSLog(@"Average input: %f Peak input: %f Low pass results: %f", [recorder averagePowerForChannel:0], [recorder peakPowerForChannel:0], lowPassResults);
    NSLog(@"lowPassResults:%f",lowPassResults);
    if (lowPassResults>=0.8) {
        soundLodingImageView.image = [UIImage imageNamed:[volumImages objectAtIndex:7]];
    }else if(lowPassResults>=0.7){
        soundLodingImageView.image = [UIImage imageNamed:[volumImages objectAtIndex:6]];
    }else if(lowPassResults>=0.6){
        soundLodingImageView.image = [UIImage imageNamed:[volumImages objectAtIndex:5]];
    }else if(lowPassResults>=0.5){
        soundLodingImageView.image = [UIImage imageNamed:[volumImages objectAtIndex:4]];
    }else if(lowPassResults>=0.4){
        soundLodingImageView.image = [UIImage imageNamed:[volumImages objectAtIndex:3]];
    }else if(lowPassResults>=0.3){
        soundLodingImageView.image = [UIImage imageNamed:[volumImages objectAtIndex:2]];
    }else if(lowPassResults>=0.2){
        soundLodingImageView.image = [UIImage imageNamed:[volumImages objectAtIndex:1]];
    }else if(lowPassResults>=0.1){
        soundLodingImageView.image = [UIImage imageNamed:[volumImages objectAtIndex:0]];
    }else{
        soundLodingImageView.image = [UIImage imageNamed:[volumImages objectAtIndex:0]];
    }
}

//判断是否允许使用麦克风7.0新增的方法requestRecordPermission
-(BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                }
                else {
                    bCanRecord = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:nil
                                                    message:@"app需要访问您的麦克风。\n请启用麦克风-设置/隐私/麦克风"
                                                   delegate:nil
                                          cancelButtonTitle:@"关闭"
                                          otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    }
    
    return bCanRecord;
}

@end
