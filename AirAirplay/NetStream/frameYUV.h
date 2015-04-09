//
//  frameYUV.h
//  iFrameExtractor
//
//  Created by mobile on 2015/3/30.
//
//
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavcodec/avcodec.h"
#import <Foundation/Foundation.h>

@interface frameYUV : NSObject
/** Y:明亮度 **/
@property (readonly, nonatomic, strong) NSData *luma;
/** U:藍色濃度 **/
@property (readonly, nonatomic, strong) NSData *chromaB;
/** V:紅色濃度 **/
@property (readonly, nonatomic, strong) NSData *chromaR;
/** Piexl:寬度 **/
@property (readonly, nonatomic) NSUInteger width;
/** Piexl:高度 **/
@property (readonly, nonatomic) NSUInteger height;
/** 長度 **/
@property (readonly, nonatomic) float duration;
/** 執行秒數 **/
@property (nonatomic) float position;

@property (readonly, nonatomic) AVFrame *avframe;

- (id)initWithAVFrame:(AVFrame *)frame andCodec:(AVCodecContext *)coderCtx;

@end
