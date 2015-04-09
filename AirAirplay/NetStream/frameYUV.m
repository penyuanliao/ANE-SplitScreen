//
//  frameYUV.m
//  iFrameExtractor
//
//  Created by mobile on 2015/3/30.
//
//

#import "frameYUV.h"

@implementation frameYUV
@synthesize luma, chromaB, chromaR;
@synthesize width, height, duration;

+ (frameYUV *) createNewFrameYUVWithAVFrame:(AVFrame *)avframe andCodec:(AVCodecContext *)coderCtx {
    
    frameYUV *frame = [[frameYUV alloc]initWithAVFrame:avframe andCodec:coderCtx];
    
    return frame;
}
/****/
- (id)initWithAVFrame:(AVFrame *)frame andCodec:(AVCodecContext *)coderCtx
{
    self = [super init];
    if (self) {
        luma = [frameYUV copyFrameData:frame->data[0] frameSize:frame->linesize[0] fWidth:coderCtx->width fHeight:coderCtx->height];
        chromaB = [frameYUV copyFrameData:frame->data[1] frameSize:frame->linesize[1] fWidth:coderCtx->width/2 fHeight:coderCtx->height/2];
        chromaR = [frameYUV copyFrameData:frame->data[2] frameSize:frame->linesize[2] fWidth:coderCtx->width/2 fHeight:coderCtx->height/2];
        width = coderCtx->width;
        height = coderCtx->height;
        _avframe = frame;
    }
    return self;
}


+ (NSData *)copyFrameData:(UInt8 *)src frameSize:(int)linesize fWidth:(int)width fHeight:(int)height
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

-(void)dealloc
{
    [super dealloc];
    luma = nil;
    chromaB = nil;
    chromaR = nil;
    width = 0;
    height = 0;
    duration = 0;
    _avframe = nil;
}

@end
