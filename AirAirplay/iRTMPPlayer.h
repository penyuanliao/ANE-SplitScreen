//
//  iRTMPPlayer.h
//  iFrameExtractor
//
//  Created by mobile on 2015/3/16.
//
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavcodec/avcodec.h"
#import "avformat.h"
#import "swscale.h"
#import "avcodec.h"

typedef NS_ENUM(NSInteger, StreamType) {
    STREAM_TYPE_UNKNOWN     = -1,
    STREAM_TYPE_VIDEO       = 0,
    STREAM_TYPE_AUDIO       = 1,
    STREAM_TYPE_DATA        = 2,
    STREAM_TYPE_SUB         = 3,
    STREAM_TYPE_ATTACHMENT  = 4,
    STREAM_TYPE_NB          = 5
};


@interface iRTMPPlayer : NSObject

@property (nonatomic, assign) AVFormatContext *ifomtCtx;
@property (nonatomic, assign) AVCodecContext *iCodecCtx;
@property (nonatomic, assign) AVFrame *iFrame;
@property (nonatomic, assign) AVPacket iPacket;
@property (nonatomic, assign) AVPicture iPic;
@property (nonatomic, assign) StreamType streamNode;
@property (nonatomic, assign) int outputWidth;
@property (nonatomic, assign) int outputHeight;
@property (nonatomic, assign) int sourceWidth;
@property (nonatomic, assign) int sourceHeight;

@property (nonatomic, assign) struct SwsContext *imgSwsCtx;
@property (nonatomic, assign) UIImage *currentImage;
@property (nonatomic, assign) double duration;
@property (nonatomic, assign) double curTime;
@property (nonatomic, readonly) int frameRate;
@property (nonatomic, retain) NSString *UUID;

- (void)setupWithVieo:(NSString *)rtmpPath;

- (int)setupOpenStream:(NSString *)fileName;

- (BOOL)startStreaming;

- (void)setScreenSize:(CGSize)size;

+ (UIImage *)drawingImageWithAvPicture:(AVPicture)avpic width:(int)width height:(int)height;

@end
