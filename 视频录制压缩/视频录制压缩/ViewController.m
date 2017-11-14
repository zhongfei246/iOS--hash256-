//
//  ViewController.m
//  视频录制压缩
//
//  Created by lizhongfei on 26/10/17.
//  Copyright © 2017年 lizhongfei. All rights reserved.
//

#import "ViewController.h"
#import "FMWriteVideoController.h"
#import "voiceViewController.h"
#import<CommonCrypto/CommonDigest.h>
#import <AVFoundation/AVFoundation.h>
#import "NSString+calculateSHA.h"
#import <iconv.h>

#import <AssetsLibrary/AssetsLibrary.h>
#import <AssetsLibrary/ALAssetRepresentation.h>

@interface ViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
- (IBAction)selectedVideoFromLibrary:(id)sender;
- (IBAction)recordVideo:(id)sender;
- (IBAction)customRecoedVideo:(id)sender;
- (IBAction)voiceRecord:(id)sender;

@end

@implementation ViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertUploadSuccess) name:@"alertUploadSuccess" object:nil];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"alertUploadSuccess" object:nil];
}

#pragma mark 从手机选择
- (IBAction)selectedVideoFromLibrary:(id)sender {
    [self choosevideo];
    //下面三行测试中间代码段执行时间的
//    NSDate* tmpStartData = [NSDate date];

//    double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
//    NSLog(@">>>>>>>>>>cost time = %f ms", deltaTime*1000);
    
//8b007331828d926bb9046f07a3e4addfbb3c10a8315661e8ebf783d376bd5584 ceshi.mp4
}

#pragma mark 录制视频
- (IBAction)recordVideo:(id)sender {
    [self startvideo];
}

#pragma mark 定制化录制视频
- (IBAction)customRecoedVideo:(id)sender {
    FMWriteVideoController *writeVC = [[FMWriteVideoController alloc] init];
    UINavigationController *NAV = [[UINavigationController alloc] initWithRootViewController:writeVC];
    [self presentViewController:NAV animated:YES completion:nil];
}

#pragma mark -按住录制音频
- (IBAction)voiceRecord:(id)sender {
    [self presentViewController:[[voiceViewController alloc] init] animated:YES completion:nil];
}

#pragma mark -选择本地视频
- (void)choosevideo
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//sourcetype有三种分别是camera，photoLibrary和photoAlbum
    NSArray *availableMedia = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];//Camera所支持的Media格式都有哪些,共有两个分别是@"public.image",@"public.movie"
    ipc.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];//设置媒体类型为public.movie
    [self presentViewController:ipc animated:YES completion:nil];
    ipc.delegate = self;//设置委托
}

#pragma mark -录制视频
- (void)startvideo
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypeCamera;//sourcetype有三种分别是camera，photoLibrary和photoAlbum
    NSArray *availableMedia = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];//Camera所支持的Media格式都有哪些,共有两个分别是@"public.image",@"public.movie"
    ipc.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];//设置媒体类型为public.movie
    [self presentViewController:ipc animated:YES completion:nil];
    ipc.videoMaximumDuration = 30.0f;//30秒
    ipc.delegate = self;//设置委托
}

#pragma mark ---------------------------------
#pragma mark --------完成视频录制，并压缩后显示大小、时长
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    //计算hash256
    NSURL *imgurl = [info objectForKey:UIImagePickerControllerReferenceURL];
    if (imgurl) {//说明是从相册选择出来的视频进来的代理方法
        NSURL *sourceURL = [info objectForKey:UIImagePickerControllerMediaURL];
       NSLog(@"%@", [NSString stringWithFormat:@"%.2f kb", [self getFileSize:[sourceURL path]]]);
        ALAssetsLibrary * assetLiary = [[ALAssetsLibrary alloc] init];
        [assetLiary assetForURL:imgurl resultBlock:^(ALAsset *asset) {
            if (asset != nil) {
                NSString * hash256String = [NSString fileSHA256WithAsset:asset];
                UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"提示"
                                                                                          message: [NSString stringWithFormat:@"hash256:%@",hash256String]
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    
                }]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        } failureBlock:^(NSError *error) {
            NSLog(@"失败%@",error);
        }];
    } else {//说明是系统录制完毕进来的代理方法
        NSURL *URL = [info objectForKey:UIImagePickerControllerMediaURL];
        UISaveVideoAtPathToSavedPhotosAlbum([URL path], self, nil, NULL);//这个是保存到手机相册
        NSString * hash256String = [NSString getFileSHA256WithPath:[URL path]];
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"提示"
                                                                                  message: [NSString stringWithFormat:@"hash256:%@",hash256String]
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    //下面这段代码是压缩转换格式上传，如果只需要hash计算，以下可不看
    /**
    NSURL *sourceURL = [info objectForKey:UIImagePickerControllerMediaURL];
    NSLog(@"%@",[NSString stringWithFormat:@"%f s", [self getVideoLength:sourceURL]]);
    NSLog(@"%@", [NSString stringWithFormat:@"%.2f kb", [self getFileSize:[sourceURL path]]]);

    NSURL *newVideoUrl ; //一般.mp4
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];//用时间给文件全名，以免重复，在测试的时候其实可以判断文件是否存在若存在，则删除，重新生成文件即可
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    newVideoUrl = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", [formater stringFromDate:[NSDate date]]]] ;//这个是保存在app自己的沙盒路径里，后面可以选择是否在上传后删除掉。我建议删除掉，免得占空间。
    [self convertVideoQuailtyWithInputURL:sourceURL outputURL:newVideoUrl completeHandler:nil];
     */
    //不能压缩转换格式之后再计算hash256，这样算出来的和转换之前不一致，hash要一转换和压缩之前的为准，压缩转换之后视频可以作为上传服务器用
}
- (void) convertVideoQuailtyWithInputURL:(NSURL*)inputURL
                               outputURL:(NSURL*)outputURL
                         completeHandler:(void (^)(AVAssetExportSession*))handler
{
    
    //这里拿到选择的视频URL判断一下沙盒中是否存在过，如果沙盒中存在这个URL对应的转化后的视频就不要在转化了，否则两次进入相册选择同一视频生成的hash值不一样，原因是：如果不加这个判断，每次都会进行这个URL对应视频的压缩导出，造成即使是同一URL对应的MOV视频压缩转化出来的mp4生成的hash也不一样，我想跟这个转化方法不一致，至少这个转化方法针对同一个URL压缩生成的mp4有差别，要不然hash肯定是一致的，但是这也有个弊端，一旦清理了沙盒再从相册选择同一视频，则该视频又会生成一个hash值，好的结果是只要是同一视频永远只有一个hash值。（此问题已解决，解决方案为：转换压缩之前计算hash256）
//    if ([[NSFileManager defaultManager] fileExistsAtPath:[outputURL path]]) {
//        [self alertUploadVideo:outputURL];
//        return;
//    }
    
    //转码配置
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    //压缩输出MP4
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    //  NSLog(resultPath);
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         switch (exportSession.status) {
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"AVAssetExportSessionStatusCancelled");
                 break;
             case AVAssetExportSessionStatusUnknown:
                 NSLog(@"AVAssetExportSessionStatusUnknown");
                 break;
             case AVAssetExportSessionStatusWaiting:
                 NSLog(@"AVAssetExportSessionStatusWaiting");
                 break;
             case AVAssetExportSessionStatusExporting:
                 NSLog(@"AVAssetExportSessionStatusExporting");
                 break;
             case AVAssetExportSessionStatusCompleted:
                 NSLog(@"AVAssetExportSessionStatusCompleted");
                 NSLog(@"%@",[NSString stringWithFormat:@"%f s", [self getVideoLength:outputURL]]);
                 NSLog(@"%@", [NSString stringWithFormat:@"%.2f kb", [self getFileSize:[outputURL path]]]);
                 //UISaveVideoAtPathToSavedPhotosAlbum([outputURL path], self, nil, NULL);//这个是保存到手机相册
//                 [self alertUploadVideo:outputURL];
                 break;
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"AVAssetExportSessionStatusFailed");
                 break;
         }
     }];
}

#pragma mark ---------------------------------
#pragma mark --------上传提示
-(void)alertUploadVideo:(NSURL*)URL{
    CGFloat size = [self getFileSize:[URL path]];
    NSString *message;
    NSString *sizeString;
    CGFloat sizemb= size/1024;
    if(size<=1024){
        sizeString = [NSString stringWithFormat:@"%.2fKB",size];
    }else{
        sizeString = [NSString stringWithFormat:@"%.2fMB",sizemb];
    }
    if(sizemb<2){//小于2M直接上传
        [self uploadVideo:URL];
    } else if(sizemb<=5){
        message = [NSString stringWithFormat:@"视频%@，大于2MB会有点慢，确定上传吗？", sizeString];
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil
                                                                                  message: message
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshwebpages" object:nil userInfo:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[URL path] error:nil];//取消之后就删除，以免占用手机硬盘空间（沙盒）
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self uploadVideo:URL];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }else if(sizemb>5){
        message = [NSString stringWithFormat:@"视频%@，超过5MB，不能上传，抱歉。", sizeString];
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil
                                                                                  message: message
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshwebpages" object:nil userInfo:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[URL path] error:nil];//取消之后就删除，以免占用手机硬盘空间
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark ---------------------------------
#pragma mark --------上传代码
-(void)uploadVideo:(NSURL*)URL{
    NSLog(@"上传");

//    NSData *data = [NSData dataWithContentsOfURL:URL];
//    MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:@"www.ylhuakai.com" customHeaderFields:nil];
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    NSString *updateURL;
//    updateURL = @"/alflower/Data/sendupdate";
//
//    [dic setValue:[NSString stringWithFormat:@"%@",User_id] forKey:@"openid"];
//    [dic setValue:[NSString stringWithFormat:@"%@",[self.web objectForKey:@"web_id"]] forKey:@"web_id"];
//    [dic setValue:[NSString stringWithFormat:@"%i",insertnumber] forKey:@"number"];
//    [dic setValue:[NSString stringWithFormat:@"%i",insertType] forKey:@"type"];
//
//    MKNetworkOperation *op = [engine operationWithPath:updateURL params:dic httpMethod:@"POST"];
//    [op addData:data forKey:@"video" mimeType:@"video/mpeg" fileName:@"aa.mp4"];
//    [op addCompletionHandler:^(MKNetworkOperation *operation) {
//        NSLog(@"[operation responseData]-->>%@", [operation responseString]);
//        NSData *data = [operation responseData];
//        NSDictionary *resweiboDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
//        NSString *status = [[resweiboDict objectForKey:@"status"]stringValue];
//        NSLog(@"addfriendlist status is %@", status);
//        NSString *info = [resweiboDict objectForKey:@"info"];
//        NSLog(@"addfriendlist info is %@", info);
//        // [MyTools showTipsWithView:nil message:info];
//        // [SVProgressHUD showErrorWithStatus:info];
//        if ([status isEqualToString:@"1"])
//        {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshwebpages" object:nil userInfo:nil];
//            [[NSFileManager defaultManager] removeItemAtPath:[URL path] error:nil];//上传之后就删除，以免占用手机硬盘空间;
//
//        }else
//        {
//            //[SVProgressHUD showErrorWithStatus:dic[@"info"]];
//        }
//        // [[NSNotificationCenter defaultCenter] postNotificationName:@"StoryData" object:nil userInfo:nil];
//    }errorHandler:^(MKNetworkOperation *errorOp, NSError* err) {
//        NSLog(@"MKNetwork request error : %@", [err localizedDescription]);
//    }];
//    [engine enqueueOperation:op];
}
#pragma mark -提示
-(void)alertUploadSuccess{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"提示"
                                                                              message: @"上传压缩后的MP4视频文件到服务器吗？"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"提示"
                                                                                  message: @"上传成功"
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark ---------------------------------
#pragma mark --------辅助方法



#pragma mark 获取视频文件大小
- (CGFloat) getFileSize:(NSString *)path
{
    NSLog(@"%@",path);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024;
    }else{
        NSLog(@"找不到文件");
    }
    return filesize;
}//此方法可以获取文件的大小，返回的是单位是KB。
#pragma mark 获取视频文件时长
- (CGFloat) getVideoLength:(NSURL *)URL
{
    
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:URL];
    CMTime time = [avUrl duration];
    int second = ceil(time.value/time.timescale);
    return second;
}//此方法可以获取视频文件的时长。





@end
