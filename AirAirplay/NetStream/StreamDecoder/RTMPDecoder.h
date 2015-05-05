//
//  RTMPDecoder.h
//  iFrameExtractor
//
//  Created by mobile on 2015/3/31.
//
//
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavcodec/avcodec.h"
#import <Foundation/Foundation.h>

@interface RTMPDecoder : NSObject
/** 格式化 **/
@property (nonatomic, assign, readonly) AVFormatContext *ifomtCtx;
/** 解碼器 **/
@property (nonatomic, assign, readonly) AVCodecContext *iCodecCtx;
/** 每個串流資料 **/
@property (nonatomic, assign, readonly) AVFrame *iFrame;
/** 封包流 **/
@property (nonatomic, assign, readonly) AVPacket iPacket;
/** 轉換成圖片資料(如果有使用swsContext) **/
@property (nonatomic, assign, readonly) AVPicture iPic;
/** 串流影音編號 **/
@property (nonatomic, assign, readonly) int vStreamNode;
/** 影片大小 **/
@property (nonatomic, assign, readonly) int outputWidth;
@property (nonatomic, assign, readonly) int outputHeight;

@property (nonatomic, assign, readonly) float fps;
@property (nonatomic, assign, readonly) float vTimeBase;
@property (nonatomic, assign, readonly) float time;
/** 開始時間 **/
@property (nonatomic, assign, readonly) NSDate *vStartTime;

+ (RTMPDecoder *)connectionWithPath:(NSString *)path;

/** 輸入RTMP網址 **/
- (id)initWithRtmp:(NSString *)path;
/** 開啟新的RTMP網址 **/
- (void)openStream:(NSString *)path;
/** Stream 解碼視訊KeyFrame **/
- (BOOL)decodeFrame;
- (int)frameRate;

- (void)start;
/** 停止所有Stream視訊跟移除所有物件 **/
- (void)close;

@end
