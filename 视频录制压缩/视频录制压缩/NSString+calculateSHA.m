//
//  NSString+ceshi.m
//  视频录制压缩
//
//  Created by lizhongfei on 31/10/17.
//  Copyright © 2017年 lizhongfei. All rights reserved.
//  sha256加密方式(哈希算法，用于校验数据完整性和唯一性)

#import "NSString+calculateSHA.h"


#define FileHashDefaultChunkSizeForReadingData 1024*8

@implementation NSString (ceshi)

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





@end
