//
//  AVAssetWriteManager.m
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/15.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753

#import "AVAssetWriteManager.h"
#import "XCFileManager.h"
#import "aw_all.h"
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import<CommonCrypto/CommonDigest.h>

@interface AVAssetWriteManager (){
//    CC_SHA1_CTX ctx;
    CC_SHA256_CTX ctx;
    uint8_t * hashBytes ;
    NSData * hash ;
    NSInteger dataFileFirstSize ;
    BOOL onceFlag;
}


@property (nonatomic, strong) dispatch_queue_t writeQueue;
@property (nonatomic, strong) NSURL           *videoUrl;

@property (nonatomic, strong)AVAssetWriter *assetWriter;

@property (nonatomic, strong)AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong)AVAssetWriterInput *assetWriterAudioInput;



@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;


@property (nonatomic, assign) BOOL canWrite;
@property (nonatomic, assign) FMVideoViewType viewType;
@property (nonatomic, assign) CGSize outputSize;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat recordTime;

@end

@implementation AVAssetWriteManager

#pragma mark - private method
- (void)setUpInitWithType:(FMVideoViewType )type
{
    switch (type) {
        case Type1X1:
            _outputSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
            break;
        case Type4X3:
            _outputSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width*4/3);
            break;
        case TypeFullScreen:
            _outputSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            break;
        default:
            _outputSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
            break;
    }
    
    //解决录制的视频屏幕绿边
    /**
     因为使用MPEG-2和MPEG-4（和其他基于DCT的编解码器），压缩被应用于16×16像素宏块的网格。使用MPEG-4第10部分（AVC / H.264），4和8的倍数也是有效的，但16是最有效的。
     
     如果水平或垂直尺寸不能被16整除，那么编码器在右边缘或下边缘用合适数量的黑色”悬垂“样本贴图，这些样本在解码时被丢弃。例如，当在1920x1080编码HDTV时，编码器将8行黑色像素附加到h e eimage阵列，使行数为1088。如果播放器/编解码器在解码时丢弃那些“悬垂”样本，可能会出现我所说的绿线。
     */
    CGFloat outputSizeWidth = floor(_outputSize.width / 16) * 16;
    CGFloat outputSizeHeight = floor(_outputSize.height / 16) * 16;
    _outputSize = CGSizeMake(outputSizeWidth, outputSizeHeight);
    
    _writeQueue = dispatch_queue_create("com.5miles", DISPATCH_QUEUE_SERIAL);
    _recordTime = 0;
    
}

- (instancetype)initWithURL:(NSURL *)URL viewType:(FMVideoViewType )type andPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _videoUrl = URL;
        _viewType = type;
        _filePath = path;
        onceFlag = YES;
        [self setUpInitWithType:type];
    }
    return self;
}

//开始写入数据
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    if (sampleBuffer == NULL){
        NSLog(@"empty sampleBuffer");
        return;
    }
    
    @synchronized(self){
        if (self.writeState < FMRecordStateRecording){
            NSLog(@"not ready yet");
            return;
        }
    }
    
    
    
    CFRetain(sampleBuffer);
    dispatch_async(self.writeQueue, ^{
        @autoreleasepool {
            @synchronized(self) {
                if (self.writeState > FMRecordStateRecording){
                    CFRelease(sampleBuffer);
                    return;
                }
            }
     
            
            if (!self.canWrite && mediaType == AVMediaTypeVideo) {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.canWrite = YES;
            }
            
            if (!_timer) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
                });
            }
            //写入视频数据
            if (mediaType == AVMediaTypeVideo) {
//                NSData * yuvData = [self convertVideoSmapleBufferToYuvData:sampleBuffer];
//                NSLog(@"AVMediaTypeVideo--------:%lu",(unsigned long)yuvData.length);
                if (self.assetWriterVideoInput.readyForMoreMediaData) {
                    BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self stopWrite];
                            [self destroyWrite];
                        }
                    } else {
                        
//                        if (_yuvData.length>0 && _pcmData.length>0) { //说明之前没有采集过音频数据，即对_yuvData先进行的设置值，第一帧先采集的视频数据1
//                            [self getHashBytes:_yuvData andPcmData:_pcmData];
//                            [_yuvData appendData:yuvData];
//                        } else if (_yuvData.length==0 && _pcmData.length==0){//第一次采集的是视频数据 1
//                            [_yuvData appendData:yuvData];
//                            _yuvFlag = YES;
//                        } else if (_yuvData.length>0 && _pcmData.length==0) {
//
//                        } else if (_yuvData.length==0 && _pcmData.length>0) {// 说明之前已经采集过至少一次音频数据了，即对_pcmData进行设置值2
//                            [_yuvData appendData:yuvData];
//                            [self getHashBytes:_yuvData andPcmData:_pcmData];
//                            _yuvFlag = NO;
//                        }
                    }
                }
            }
            
            //写入音频数据
            if (mediaType == AVMediaTypeAudio) {
//                NSData * pcmData = [self convertAudioSmapleBufferToPcmData:sampleBuffer];
//                NSLog(@"AVMediaTypeAudio--------:%lu",(unsigned long)pcmData.length);
                if (self.assetWriterAudioInput.readyForMoreMediaData) {
                    BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self stopWrite];
                            [self destroyWrite];
                        }
                    } else {
//                        [_pcmData appendData:pcmData];
                    }
                }
            }
            NSLog(@"--------------------------------------------------------");
            CFRelease(sampleBuffer);
        }
    } );
}
#pragma mark -从CMSampleBufferRef中提取PCM数据(音频数据)
-(NSData *) convertAudioSmapleBufferToPcmData:(CMSampleBufferRef) audioSample{
    //获取pcm数据大小
    NSInteger audioDataSize = CMSampleBufferGetTotalSampleSize(audioSample);
    
    //分配空间
    int8_t *audio_data = aw_alloc((int32_t)audioDataSize);
    
    //获取CMBlockBufferRef
    //这个结构里面就保存了 PCM数据
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(audioSample);
    //直接将数据copy至我们自己分配的内存中
    CMBlockBufferCopyDataBytes(dataBuffer, 0, audioDataSize, audio_data);
    
    //返回数据
    return [NSData dataWithBytesNoCopy:audio_data length:audioDataSize];
}
#pragma mark -从CMSampleBufferRef中提取yuv420数据(视频数据)
-(NSData *) convertVideoSmapleBufferToYuvData:(CMSampleBufferRef) videoSample{
    // 获取yuv数据
    // 通过CMSampleBufferGetImageBuffer方法，获得CVImageBufferRef。
    // 这里面就包含了yuv420(NV12)数据的指针
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoSample);
    
    //表示开始操作数据
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    //图像宽度（像素）
    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
    //图像高度（像素）
    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
    //yuv中的y所占字节数
    size_t y_size = pixelWidth * pixelHeight;
    //yuv中的uv所占的字节数
    size_t uv_size = y_size / 2;
    
    uint8_t *yuv_frame = aw_alloc(uv_size + y_size);
    
    //获取CVImageBufferRef中的y数据
    uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(yuv_frame, y_frame, y_size);
    
    //获取CMVImageBufferRef中的uv数据
    uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(yuv_frame + y_size, uv_frame, uv_size);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    //返回数据
    return [NSData dataWithBytesNoCopy:yuv_frame length:y_size + uv_size];
}


#pragma mark - public methed
- (void)startWrite
{
    self.writeState = FMRecordStatePrepareRecording;
    if (!self.assetWriter) {
        [self setUpWriter];
    }
    
    
}
- (void)stopWrite
{
    self.writeState = FMRecordStateFinish;
    [self.timer invalidate];
    self.timer = nil;
    __weak __typeof(self)weakSelf = self;
    if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting){
        dispatch_async(self.writeQueue, ^{
            [_assetWriter finishWritingWithCompletionHandler:^{
                ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
                [lib writeVideoAtPathToSavedPhotosAlbum:weakSelf.videoUrl completionBlock:nil];
                
            }];
        });
    }
}

- (void)updateProgress
{
    if (_recordTime >= RECORD_MAX_TIME) {
        [self stopWrite];
        if (self.delegate && [self.delegate respondsToSelector:@selector(finishWriting)]) {
            [self.delegate finishWriting];
        }
        return;
    }
    _recordTime += 0.05;
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateWritingProgress:)]) {
        [self.delegate updateWritingProgress:_recordTime/RECORD_MAX_TIME * 1.0];
    }
}

#pragma mark - private method
//设置写入视频属性
- (void)setUpWriter
{
    self.assetWriter = [AVAssetWriter assetWriterWithURL:self.videoUrl fileType:AVFileTypeMPEG4 error:nil];
    //写入视频大小
    NSInteger numPixels = self.outputSize.width * self.outputSize.height;
    //每像素比特
    CGFloat bitsPerPixel = 6.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(30),
                                             AVVideoMaxKeyFrameIntervalKey : @(30),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
    
    //视频属性 self.outputSize.height*2 扩大写入的视频流范围：录制输出视频体积大小确定的情况下，里面像素越多越清晰，乘以2使一定体积内的像素翻倍
    self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                       AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                       AVVideoWidthKey : @(self.outputSize.height*2),
                                       AVVideoHeightKey : @(self.outputSize.width*2),
                                       AVVideoCompressionPropertiesKey : compressionProperties };

    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
    //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    
    
    // 音频设置
    self.audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                       AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                       AVNumberOfChannelsKey : @(1),
                                       AVSampleRateKey : @(22050) };
    
    
    _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionSettings];
    _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    
    if ([_assetWriter canAddInput:_assetWriterVideoInput]) {
        [_assetWriter addInput:_assetWriterVideoInput];
    }else {
        NSLog(@"AssetWriter videoInput append Failed");
    }
    if ([_assetWriter canAddInput:_assetWriterAudioInput]) {
        [_assetWriter addInput:_assetWriterAudioInput];
    }else {
        NSLog(@"AssetWriter audioInput Append Failed");
    }
    
    
    self.writeState = FMRecordStateRecording;

}


//检查写入地址
- (BOOL)checkPathUrl:(NSURL *)url
{
    if (!url) {
        return NO;
    }
    if ([XCFileManager isExistsAtPath:[url path]]) {
        return [XCFileManager removeItemAtPath:[url path]];
    }
    return YES;
}

- (void)destroyWrite
{
    self.assetWriter = nil;
    self.assetWriterAudioInput = nil;
    self.assetWriterVideoInput = nil;
    self.videoUrl = nil;
    self.recordTime = 0;
    [self.timer invalidate];
    self.timer = nil;
    
}

- (void)dealloc
{
    [self destroyWrite];
}

@end
