//
//  iRTMPPlayer.m
//  iFrameExtractor
//
//  Created by mobile on 2015/3/16.
//
//
#import "AirAirplay.h"
#import "iRTMPPlayer.h"

#define fOpenGLFrmat PIX_FMT_RGB24
#define fVideoQualityDefault SWS_FAST_BILINEAR

static NSDate *rtmpTimeout; //超時跳出
static BOOL isRead = false;

@interface iRTMPPlayer ()

@end


@implementation iRTMPPlayer
@synthesize ifomtCtx, iCodecCtx, iFrame, iPacket, iPic;
@synthesize streamNode, outputWidth, outputHeight, sourceWidth, sourceHeight;
@synthesize imgSwsCtx, currentImage, duration, curTime;



- (id)init {
    NSLog(@"init");
    self = [super init];
    if (self) {
    
        _UUID = [[NSUUID UUID] UUIDString];
        
    };
    return self;
}

- (void)setupWithVieo:(NSString *)rtmpPath {
    
    [self initization];
    
    [self setupOpenStream:rtmpPath];
    
}
- (void)initization
{
    //註冊和初始化 formats and codecs
    avcodec_register_all();
    av_register_all();
    avformat_network_init();
    ifomtCtx = avformat_alloc_context();
    //Initialize intrrupt callback
    ifomtCtx->interrupt_callback.callback = decode_interrupt_cb;
    ifomtCtx->interrupt_callback.opaque = ifomtCtx;
}
/** 檢查是否讀取超過時間 **/
static int decode_interrupt_cb(void *ctx)
{
    
    AVFormatContext *ictx = ctx;
    if (ictx->duration != 0)
    {
        rtmpTimeout = 0;
        return 0;
    }
    NSTimeInterval timeInterval = [rtmpTimeout timeIntervalSinceNow];
    timeInterval = -timeInterval;
    //time out 5.0 sec
    if (timeInterval > 5.0)
    {
        return 1; // abort
    }
    else
        return 0;
}
- (int)setupOpenStream:(NSString *)fileName
{
    const char *_fileName = [fileName cStringUsingEncoding:NSASCIIStringEncoding];
    isRead = false;
    if (avformat_open_input(&ifomtCtx, _fileName, nil, nil) != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file\n");
        return -1;
    }else
    {
        isRead = true;
        av_log(nil, AV_LOG_INFO, "function::avformat_open_input();\n");
    }
    //取得時間訊息(自動建立)
    if (avformat_find_stream_info(ifomtCtx, nil) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information\n");
        return -1;
    }else
    {
        av_log(NULL, AV_LOG_INFO, "function::avformat_find_stream_info();\n");
    }
    
    //找出視訊格式編號
    AVCodec *rtmpCodec = nil;
    
    //find the video stream and its decoder
    if ((streamNode = av_find_best_stream(ifomtCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &rtmpCodec, 0)) < 0) {
        NSLog(@"Could not find a video streaming information.");
        return -1;
    }else
    {
        NSLog(@"video-stream id: %d", (int)streamNode);
    }
    
    iCodecCtx = ifomtCtx->streams[streamNode]->codec;
    NSLog(@"video-codec_id:%d",iCodecCtx->codec_id);
    // Find the decoder for the video stream
    rtmpCodec = avcodec_find_decoder(iCodecCtx->codec_id);
    
    if (rtmpCodec == NULL) av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
    
    if (avcodec_open2(iCodecCtx, rtmpCodec, NULL) < 0) av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
    
    iFrame = av_frame_alloc(); //Allocates an AVFrame and sets its fields to default values
    
    outputWidth = iCodecCtx->width;
    outputHeight = iCodecCtx->height;
    
    return 1;
}

- (BOOL)startStreaming
{
    if (!isRead) return NO;
    int frameFinished = 0;
    //Init Packet
    av_init_packet(&iPacket);
    
    while (!frameFinished && av_read_frame(ifomtCtx, &iPacket) >= 0)
    {
        // A Packet of video stream.
        if (iPacket.stream_index == streamNode)
        {
            //進行解碼將資料寫入到frame
            avcodec_decode_video2(iCodecCtx, iFrame, &frameFinished, &iPacket);
        }
    }
    //Release Packet
    av_free_packet(&iPacket);
    return frameFinished!=0;
}


#pragma setup image

/** 初始化轉檔 **/
- (void)setupSwscalerOfQuality:(int)quality {
    
    //Release avpicture and swscaler
    avpicture_free(&iPic);
    sws_freeContext(imgSwsCtx);
    //Init avpicture RGB
    avpicture_alloc(&iPic, fOpenGLFrmat, outputWidth, outputHeight);
    //{ sourceW, sourceH, source format, scaleW, scaleH, output format, 壓縮演算法 }
    //Init swscaler
    int sws_flags = quality;
    imgSwsCtx = sws_getContext(iCodecCtx->width,
                               iCodecCtx->height,
                               iCodecCtx->pix_fmt,
                               outputWidth,
                               outputHeight,
                               fOpenGLFrmat,
                               sws_flags, NULL, NULL, NULL);
    
}

- (void)setScreenSize:(CGSize)size
{
    if (!isRead) return;
    //    if (CGSizeEqualToSize(size, CGSizeMake(outputWidth, outputHeight))) return;
    float ratios = [self scaleRatiosWithSize:size];
    NSLog(@"rations:%f",ratios);
    if (size.width != outputWidth) outputWidth = iCodecCtx->width * ratios;
    if (size.height != outputHeight) outputHeight = iCodecCtx->height * ratios;
    [self setupSwscalerOfQuality:fVideoQualityDefault];
}
- (float) scaleRatiosWithSize:(CGSize)size
{
    float ratios = 1.0;
    float ratiosW = size.height / outputWidth;
    float ratiosH = size.width / outputHeight;
    return ratios = (ratiosH > ratiosW ? ratiosW : ratiosH);
}
#pragma -mark Getter Value
- (int)frameRate {
    if (!isRead) return 0;
    AVStream *stream = ifomtCtx->streams[streamNode];
    NSLog(@"framerate:%i",stream->r_frame_rate.num / stream->r_frame_rate.den);
    return stream->r_frame_rate.num / stream->r_frame_rate.den;
}
#pragma -mark Setter Value
- (double)duration {
    return ((double)ifomtCtx->duration / AV_TIME_BASE);
}
- (double)currentTime {
    AVRational time_base = ifomtCtx->streams[streamNode]->time_base;
    
    return iPacket.pts * (double)time_base.num / time_base.den;
}
- (int)sourceWidth { return iCodecCtx->width;  }
- (int)sourceHeight { return iCodecCtx->height; }

#pragma -mark Drawing Image

- (UIImage *)currentImage {
    if ( !iFrame->data[0] ) return nil;
    [self convertFromRGB];
    //產生圖片
    return [iRTMPPlayer drawingImageWithAvPicture:iPic width:(int)outputWidth height:(int)outputHeight];
}
//sws_scale換成需要的格式、大小
- (void)convertFromRGB {
    sws_scale(imgSwsCtx, (const uint8_t *const *)iFrame->data, iFrame->linesize, 0, iCodecCtx->height,
              iPic.data, iPic.linesize);
}
//Create video stream data on UIImage
+ (UIImage *)drawingImageWithAvPicture:(AVPicture)avpic width:(int)width height:(int)height {
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, avpic.data[0], avpic.linesize[0]*height, kCFAllocatorNull);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colrSpc = CGColorSpaceCreateDeviceRGB();
    CGColorRenderingIntent rndrIntnt = kCGRenderingIntentDefault;
    const size_t bitsPx = 8; //RGB 8 bit
    const size_t bytesPerRow = 24; // RGB 3*8
    
    CGImageRef cgImage = CGImageCreate(width, height, bitsPx, bytesPerRow, avpic.linesize[0], colrSpc, bitmapInfo, provider, NULL, NO, rndrIntnt);
    
    CGColorSpaceRelease(colrSpc);
    UIImage *img = [UIImage imageWithCGImage:cgImage];
    
    //import need dealloc
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    return img;
}

-(void)dealloc
{
    [[AirAirplay sharedInstance]asyncyToActionScriptWithString:[NSString stringWithFormat:@"Release UUID:%@", _UUID] event:@"iRTMPPlayerEvent"];
    
    if (imgSwsCtx != NULL) sws_freeContext(imgSwsCtx); // Release swsCaler
    
    if (&iPic != NULL) avpicture_free(&iPic); // Release AVPicture
    
    if (&iPacket != NULL) av_free_packet(&iPacket); // Free the packet that was allocated by av_read_frame
    
    if (iFrame != NULL) av_free(iFrame); // Release frame
    
    if (iCodecCtx != NULL) avcodec_close(iCodecCtx); // Close the codec
    
    if (ifomtCtx != NULL) avformat_close_input(&ifomtCtx); // Close the video file
    
    [super dealloc];
}

@end
