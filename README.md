## iOS录制音视频计算hash256（SHA256）

这是一个iOS录制音视频计算hash256（SHA256）值的demo，适用于大文件快速计算hash256值。以下是简要介绍，具体还请看demo源码。如有不对的地方欢迎指正，如有帮助欢迎给star，谢谢！

先看两张图：

<figure>
    <img src="https://github.com/zhongfei246/iOS--hash256-/blob/master/%E8%A7%86%E9%A2%91%E5%BD%95%E5%88%B6%E5%8E%8B%E7%BC%A9/images/123.png" width="300" align="center"/>
    <img src="https://github.com/zhongfei246/iOS--hash256-/blob/master/%E8%A7%86%E9%A2%91%E5%BD%95%E5%88%B6%E5%8E%8B%E7%BC%A9/images/456.png" width="300" align="center"/>
</figure>

## 主要功能模块（Contents）

* 从本地选择视频计算hash256
* 采用系统普通的录制方法录制视频计算
* 定制化相机录制视频计算
* 录音对音频文件进行计算

## 使用注意
* 直接下载即可
* 运行需用真机，否则点击录制会崩溃

## 功能介绍
### 从本地选择视频计算hash256
```objc
#pragma mark -选择本地视频计算hash256
- (void)choosevideo
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//sourcetype有三种分别是camera，photoLibrary和photoAlbum
    NSArray *availableMedia = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];//Camera所支持的Media格式都有哪些,共有两个分别是@"public.image",@"public.movie"
    ipc.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];//设置媒体类型为public.movie,也可以添加availableMedia[0]，就可以加载出图片，图片一样可以计算hash256
    [self presentViewController:ipc animated:YES completion:nil];
    ipc.delegate = self;//设置委托
}
```

### 系统录制视频计算hash256
```objc
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

#pragma mark --------代理方法
#pragma mark --------完成视频录制并计算显示
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
}

```
### 定制化相机录制视频计算hash256
```objc
#pragma mark 定制化录制视频
- (IBAction)customRecoedVideo:(id)sender {
    FMWriteVideoController *writeVC = [[FMWriteVideoController alloc] init];
    UINavigationController *NAV = [[UINavigationController alloc] initWithRootViewController:writeVC];
    [self presentViewController:NAV animated:YES completion:nil];
}

注：这里使用的是别人写的一个录制视频的类，录制结束会调用代理方法
recordFinishWithvideoUrl，我们在这个代理方法中计算视频的hash256值

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

```

### 音频文件进行计算hash256
```objc
#pragma mark -按住录制音频
- (IBAction)voiceRecord:(id)sender {
    [self presentViewController:[[voiceViewController alloc] init] animated:YES completion:nil];
}

//voiceViewController是录制音频的控制器

#pragma mark -按下录制音频和计算
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
                NSLog(@"Error: %@ [%4.4s])",[error localizedDescription],(char*)&errorCode);
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

```
### hash256计算类（字符串分类）介绍
这个类中共有三个方法，分别介绍其功能

* 第一个方法：getFileSHA256WithPath，二进制流读取方法计算

```objc
#pragma mark ---------------------------------
#pragma mark --------第一种方式：二进制流读取方法
+(NSString *)getFileSHA256WithPath:(NSString*)path
{
    
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
    
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,
                                      size_t chunkSizeForReadingData) {
    
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    
    // Initialize the hash object
    CC_SHA256_CTX hashObject;
    CC_SHA256_Init(&hashObject);
    
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_SHA256_Update(&hashObject,
                         (const void *)buffer,
                         (CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,
                                       (const char *)hash,
                                       kCFStringEncodingUTF8);
    
done:
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}
```
* 第二个方法：getSHA256WithFilePathByHandle，句柄读取方法计算，实际上是读取出来data，但是性能相当于上面第一种的50%

```objc
#pragma mark ---------------------------------
#pragma mark --------方法二：句柄(实际上是读取出来data，但是性能相当于上面第一种的50%)
+(NSString *)getSHA256WithFilePathByHandle:(NSString *)path{
    return [self getFileSHA256WithPath:path];
}

- (NSString *)SHA256WithFilePath:(NSURL *)path {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingFromURL:path error:nil];
    if( handle== nil ) {
        return nil;
    }
    CC_SHA256_CTX md5;
    CC_SHA256_Init(&md5);
    BOOL done = NO;
    while(!done)
    {
        NSData* fileData = [handle readDataOfLength: 100*1024];//100KB
        NSLog(@"当前文件的偏移量：%llu",handle.offsetInFile);
        CC_SHA256_Update(&md5, [fileData bytes], (CC_LONG)[fileData length]);
        if( [fileData length] == 0 ) done = YES;
    }
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &md5);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    NSLog(@"长度：%lu",(unsigned long)output.length);
    [handle closeFile];
    handle = nil;
    return output;
}
```
* 第三个方法：fileSHA256WithAsset：从本地选择视频的计算hash256计算方式

```objc
//注意:从本地选择图片或视频必须采用这种方式计算hash256（创建缓存读取字节），否则每次选择同一个视频或图片时计算出来的hash256会不一样
#pragma mark ---------------------------------
#pragma mark --------从本地选择视频的计算hash256计算方式
+(NSString *)fileSHA256WithAsset:(ALAsset *)asset
{
    if (!asset) {
        return nil;
    }
    
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    unsigned long readStep = 100*1024;
    uint8_t *buffer = calloc(readStep, sizeof(*buffer));
    unsigned long long offset = 0;
    unsigned long long bytesRead = 0;
    NSError *error = nil;
    unsigned long long fileSize = [rep size];
    int chunks = (int)((fileSize + readStep - 1)/readStep);
    unsigned long long lastChunkSize = fileSize%readStep;
    
    CC_SHA256_CTX md5;
    CC_SHA256_Init(&md5);
    BOOL isExp = NO;
    int currentChunk = 0;
    while(!isExp && currentChunk < chunks){
        @try {
            if(currentChunk < chunks - 1){
                bytesRead = [rep getBytes:buffer fromOffset:offset length:(unsigned long)readStep error:&error];
            }else{
                bytesRead = [rep getBytes:buffer fromOffset:offset length:(unsigned long)lastChunkSize error:&error];
            }
            NSData * fileData = [NSData dataWithBytesNoCopy:buffer length:(unsigned long)bytesRead freeWhenDone:NO];
            CC_SHA256_Update(&md5, [fileData bytes], (CC_LONG)[fileData length]);
            offset += readStep;
        } @catch(NSException * exception) {
            isExp = YES;
            free(buffer);
        }
        currentChunk += 1;
    }
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &md5);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    NSLog(@"长度：%lu",(unsigned long)output.length);
    
    return output;
    
}
```

## PC在线计算hash值对比

* [PC在线计算hash值](http://www.atool.org/file_hash.php)

## 感谢
感谢以下的项目的开源贡献

* [3种方式视频录制详细对比](https://github.com/suifengqjn/VideoRecord) 

## 有问题反馈
在使用中有任何问题，欢迎反馈给我，可以用以下联系方式跟我交流

* 邮件(1440182323@qq.com)
* QQ: 1440182323

