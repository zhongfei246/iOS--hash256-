//
//  NSString+ceshi.h
//  视频录制压缩
//
//  Created by lizhongfei on 31/10/17.
//  Copyright © 2017年 lizhongfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import<CommonCrypto/CommonDigest.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AssetsLibrary/ALAssetRepresentation.h>

@interface NSString (calculateSHA)

+(NSString *)getFileSHA256WithPath:(NSString*)path;

+(NSString *)getSHA256WithFilePathByHandle:(NSString *)path;

+(NSString *)fileSHA256WithAsset:(ALAsset *)asset;

@end
