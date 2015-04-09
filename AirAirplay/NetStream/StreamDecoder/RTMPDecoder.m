//
//  RTMPDecoder.m
//  iFrameExtractor
//
//  Created by mobile on 2015/3/31.
//
//
#import "frameYUV.h"
#import "RTMPDecoder.h"

#define fOpenGLFrmat PIX_FMT_RGB24

#define fVideoQualityDefault SWS_FAST_BILINEAR

//=========================================
//             Static var
//=========================================
static NSDate *rtmpTimeout; //超時跳出
static BOOL isRead = false;

@interface RTMPDecoder ()
@property (nonatomic, retain) NSString *urlPath;

@end

@implementation RTMPDecoder
@synthesize iCodecCtx, iFrame, ifomtCtx, iPacket, iPic, vStreamNode;
@synthesize outputHeight, outputWidth;
@synthesize urlPath;

+ (RTMPDecoder *)connectionWithPath:(NSString *)path
{
    RTMPDecoder *rtmp = [[RTMPDecoder alloc]initWithRtmp:path];
    if (rtmp) {
        NSLog(@"%@ is Not Connected.",path);
    }
    return rtmp;
}

- (id)initWithRtmp:(NSString *)path
{
    self = [super init];
    if (self)
    {
        assert(path != nil);
        [self initization];
        int state = [self setupOpenStream:path];
        if (state == -1) {
            return nil;
        }
    }
    return self;
}
/** reset **/
- (void)openStream:(NSString *)path
{
    [self setupOpenStream:path];
}

/** 初始化ffmpeg記憶體 **/
- (void)initization
{
    //註冊和初始化 formats and codecs
    avcodec_register_all();
    av_register_all();
    avformat_network_init();
}

/** 檢查是否讀取超過時間 **/
static int decode_interrupt_cb(void *ctx)
{
    AVFormatContext *ictx = ctx;
    if (ictx->duration != 0)
    {
        rtmpTimeout = 0;
        return FALSE;
    }
    NSTimeInterval timeInterval = [rtmpTimeout timeIntervalSinceNow];
    timeInterval = -timeInterval;
    //time out 5.0 sec
    if (timeInterval > 5.0)
    {
        NSLog(@"[DECODE] Failed is not stream file.");
        return TRUE; // abort
    }
    else
        return FALSE;
}

- (int)setupOpenStream:(NSString *)fileName
{
    // 重置狀態
    if (isRead == true) {
        avformat_network_init();
    }
    urlPath = fileName;
    
    const char *_fileName = [fileName cStringUsingEncoding:NSASCIIStringEncoding];
    isRead = false; //檢查是否在讀取
    
    ifomtCtx = avformat_alloc_context(); //Allocates an AVFrame and sets its fields to default values
    // Initialize intrrupt callback
    ifomtCtx->interrupt_callback.callback = decode_interrupt_cb;
    ifomtCtx->interrupt_callback.opaque = ifomtCtx;
    
    rtmpTimeout = [NSDate date]; //設定檢查時間點
    
    if (avformat_open_input(&ifomtCtx, _fileName, nil, nil) < 0)
    {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file\n");
        return 0;
    }else
    {
        isRead = true;
        av_log(NULL, AV_LOG_INFO, "Open an input stream and read the header.\n");
    }
    //=================================
    // 我只使用RTMP VP6格式固定
    // 取代avformat_find_stream_info();
    //=================================
    //No Buffer
    ifomtCtx->flags |= AVFMT_FLAG_NOBUFFER;
    
    ifomtCtx->probesize2 = 4096;
    
    
    //av_opt_set(videoStream ->priv_data, "preset", "superfast", 0);  
    //av_opt_set(videoStream ->priv_data, "tune", "zerolatency", 0);
    //Init the video codec (RTMP flv H264)
    AVStream *videoStream = ifomtCtx->streams[0];
    iCodecCtx = videoStream->codec;
    
    //找出視訊格式編號
    AVCodec *rtmpCodec = NULL;
    //Create New stream code
    avformat_new_stream(ifomtCtx, rtmpCodec);
    
    videoStream->avg_frame_rate.num = 3;
    videoStream->avg_frame_rate.den = 90;
    videoStream->r_frame_rate.num = 25;
    videoStream->r_frame_rate.den = 1;
    videoStream->pts_wrap_bits = 32;
    iCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
    iCodecCtx->codec_id = AV_CODEC_ID_VP6F;
    iCodecCtx->bit_rate = 819200; //frame rate
    iCodecCtx->width = 1280;
    iCodecCtx->height = 720;
    iCodecCtx->ticks_per_frame = 1;
    iCodecCtx->time_base.num = 1;
    iCodecCtx->time_base.den = 1000; // 29.97fps (1000/1001)
    
    iCodecCtx->pix_fmt = PIX_FMT_YUV420P;
    iCodecCtx->flags |= 0;
    //    iCodecCtx->gop_size = 12; // Group of Pictures : emit one intra frame every ten frames (intra frame)
    iCodecCtx->refs = 1; // 1 - 16 reference frames 數字越大畫質越好
    iCodecCtx->max_b_frames = 0; // B-frames 預測和前後預測區塊
    ifomtCtx->nb_streams = 2;
    
    //find the video stream and its decoder
    if ((vStreamNode = av_find_best_stream(ifomtCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &rtmpCodec, 0)) < 0)
    {
        av_log(NULL, AV_LOG_ERROR, "Could not find a video streaming information.");
        return -1;
    }else
    {
        av_log(NULL, AV_LOG_INFO, "video-stream id: %d", (int)vStreamNode);
    }
    // Get a pointer to the codec context for the video stream
    iCodecCtx = ifomtCtx->streams[vStreamNode]->codec;
    
    // Find the decoder for the video stream
    rtmpCodec = avcodec_find_decoder(iCodecCtx->codec_id);
    
    if (rtmpCodec == NULL) {
        av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
        return 0;
    }
    
    if (avcodec_open2(iCodecCtx, rtmpCodec, NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
        return 0;
    }
    
    iFrame = av_frame_alloc(); //Allocates an AVFrame and sets its fields to default values
    
    if (iFrame == NULL) {
        avcodec_close(iCodecCtx);
        av_log(NULL, AV_LOG_ERROR, "Cannot Allocate AVFrame Error\n");
        return 0;
    }
    
    outputWidth = iCodecCtx->width;
    outputHeight = iCodecCtx->height;
    
    avStreamFPSTimeBase(videoStream, 0.04, &_fps, &_vTimeBase);
    NSLog(@"Streaming FPS:%f, timeBase:%f", _fps, _vTimeBase);
    
    return YES;
}
/** 只解碼影像 **/
- (BOOL)decodeFrame
{
    if (!isRead) return NO;
    
    int frameFinished = 0;
    /** 所有解碼存放陣列 **/
//    NSMutableArray *result = [NSMutableArray array];
    
    //Init Packet
    av_init_packet(&iPacket);
    
    while (!frameFinished && av_read_frame(ifomtCtx, &iPacket) >= 0)
    {
        
        // A Packet of video stream.
        if (iPacket.stream_index == vStreamNode)
        {
            //進行解碼將資料寫入到frame
            avcodec_decode_video2(iCodecCtx, iFrame, &frameFinished, &iPacket);
        }
        
        
//        if (frameFinished) {
//            frameYUV *frame = [[frameYUV alloc] initWithAVFrame:iFrame andCodec:iCodecCtx];
//            [result addObject:frame];
//            [frame release];
//            
//        }
        
        av_free_packet(&iPacket);
    }
    
    
    return frameFinished!=0;
    
}
#pragma FrameRate
- (int)frameRate {
    AVStream *stream = ifomtCtx->streams[vStreamNode];
    NSLog(@"framerate:%i",stream->r_frame_rate.num / stream->r_frame_rate.den);
    return stream->r_frame_rate.num / stream->r_frame_rate.den;
}
- (void)close
{
    [self closeVideoStream];
    
    vStreamNode = nil;
    
    if (ifomtCtx != NULL) {
        
        ifomtCtx->interrupt_callback.opaque = NULL;
        ifomtCtx->interrupt_callback.callback = NULL;
        avformat_close_input(&ifomtCtx); // Close the video file
        ifomtCtx = NULL;
    }
    
}
- (void)closeVideoStream
{
    if (&iPic != NULL) avpicture_free(&iPic); // Release AVPicture
    
    if (&iPacket != NULL) av_free_packet(&iPacket); // Free the packet that was allocated by av_read_frame
    
    if (iFrame != NULL) av_free(iFrame); // Release frame
    
    if (iCodecCtx != NULL) avcodec_close(iCodecCtx); // Close the codec
    
    iFrame = NULL;
    
    iCodecCtx = NULL;
    
    vStreamNode = -1;
}

//計時
static void avStreamFPSTimeBase(AVStream *st, float defaultTimeBase, float *pFPS, float *pTimeBase)
{
    float fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(st->codec->time_base.den && st->codec->time_base.num)
        timebase = av_q2d(st->codec->time_base);
    else
        timebase = defaultTimeBase;
    
    if (st->codec->ticks_per_frame != 1)
    {
        av_log(NULL,AV_LOG_INFO, "WARNING: st.codec.ticks_per_frame=%d", st->codec->ticks_per_frame);
    }
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    
    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
}

- (void)dealloc
{
    [self close];
    [super dealloc];
}

@end
