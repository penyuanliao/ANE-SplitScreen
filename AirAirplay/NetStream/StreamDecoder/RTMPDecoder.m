//
//  RTMPDecoder.m
//  iFrameExtractor
//
//  Created by mobile on 2015/3/31.
//
//
#import "frameYUV.h"
#import "RTMPDecoder.h"
#import "opt.h"
typedef NS_ENUM(NSUInteger, RTMPDecoderError) {
    RegisteredDecoderError
};
#define fOpenGLFrmat PIX_FMT_RGB24

#define fVideoQualityDefault SWS_FAST_BILINEAR
#define DEFIN_BUFFER_TIME 0.5
//=========================================
//             Static var
//=========================================
static NSDate *rtmpTimeout; //超時跳出
static BOOL isRead = false;
static int64_t start_time;

@interface RTMPDecoder ()
@property (nonatomic, retain) NSString *urlPath;
/** current time 檢查buffer是否時間是否有誤差 **/
@property (nonatomic, retain) NSDate *currentTime;

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
    if (timeInterval > 10.0)
    {
        NSLog(@"[DECODE] Failed is not stream file.");
        return TRUE; // abort
    }
    else
        return FALSE;
}

- (int)setupOpenStream:(NSString *)fileName
{
    const int decodecVP6F = AV_CODEC_ID_VP6F;
    const char *fmtName = "flv";
    vStreamNode = 0;
    
    // 重置狀態
    if (isRead == true)
    {
        avformat_network_init();
    }
    urlPath = fileName;
    _vStartTime = [NSDate new];
    
    const char *_fileName = [fileName cStringUsingEncoding:NSASCIIStringEncoding];
    isRead = false; //檢查是否在讀取
    
    ifomtCtx = avformat_alloc_context(); //Allocates an AVFrame and sets its fields to default values
    // Initialize intrrupt callback
    ifomtCtx->interrupt_callback.callback = decode_interrupt_cb;
    ifomtCtx->interrupt_callback.opaque = ifomtCtx;
    
    rtmpTimeout = [NSDate date]; //設定檢查時間點
    
    AVInputFormat *inputFmt = av_find_input_format(fmtName);
    ifomtCtx->iformat = inputFmt;
    // 設定初始化參數
    AVDictionary *codec_options = [self initConfigAVFormatOptions];
    
    if (avformat_open_input(&ifomtCtx, _fileName, nil, &codec_options) < 0)
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
    ifomtCtx->flags |= AVFMT_FLAG_NOBUFFER; //No Buffer
    ifomtCtx->flags |= AVFMT_FLAG_NOPARSE;
    ifomtCtx->flags |= AVFMT_FLAG_GENPTS;
    ifomtCtx->flags |= AVFMT_FLAG_FLUSH_PACKETS;
    ifomtCtx->flags |= AVFMT_FLAG_DISCARD_CORRUPT;
    ifomtCtx->probe_score = 0; //格式探測的分值，上限為AVPROBE_SCORE_MAX；
    ifomtCtx->max_delay = 0;
    ifomtCtx->max_index_size = 0; //用於檢索碼流的索引值的最大字長；
    ifomtCtx->max_picture_buffer = 0;//圖像緩存的最大尺寸；
    ifomtCtx->duration = 0;
    ifomtCtx->probesize2 = 32; //在解碼時用於探測的數據的大小
    
    // Find the decoder for the video stream
    AVCodec *rtmpCodec = avcodec_find_decoder(decodecVP6F);
    
    if(sizeof(int*) == 4) // 32bit code
    {
        avformat_find_stream_info(ifomtCtx, &codec_options);
        if ((vStreamNode = av_find_best_stream(ifomtCtx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0)) < 0)
        {
            av_log(NULL, AV_LOG_ERROR, "Could not find a video streaming information.");
            return -1;
        }else
        {
            av_log(NULL, AV_LOG_INFO, "video-stream id: %d\n", (int)vStreamNode);
        }
    }
    
    if (rtmpCodec == NULL) {
        av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
        return RegisteredDecoderError;
    }
    
    //Init the video codec (RTMP flv H264)
    AVStream *videoStream = ifomtCtx->streams[vStreamNode];
    
    //Allocate an AVCodecContext and set default value
    videoStream->codec = avcodec_alloc_context3(rtmpCodec);
    // Get a pointer to the codec context for the video stream
    iCodecCtx = videoStream->codec;
    
    [self configAVCodecContext:iCodecCtx];
    
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
    //    iCodecCtx->gop_size = 12; // Group of Pictures : emit one intra frame every ten frames (intra frame)
//    iCodecCtx->refs = 1; // 1 - 16 reference frames 數字越大畫質越好
//    iCodecCtx->max_b_frames = 0; // B-frames 預測和前後預測區塊
    ifomtCtx->nb_streams = 1;
    
    //find the video stream and its decoder
//    if ((vStreamNode = av_find_best_stream(ifomtCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &rtmpCodec, 0)) < 0)
//    {
//        av_log(NULL, AV_LOG_ERROR, "Could not find a video streaming information.");
//        return -1;
//    }else
//    {
//        av_log(NULL, AV_LOG_INFO, "video-stream id: %d", (int)vStreamNode);
//    }
    
    if (avcodec_open2(iCodecCtx, rtmpCodec, NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
        return 0;
    }
    
    iFrame = av_frame_alloc(); // Allocates an AVFrame and sets its fields to default values
    
    if (iFrame == NULL) {
        avcodec_close(iCodecCtx);
        av_log(NULL, AV_LOG_ERROR, "Cannot Allocate AVFrame Error\n");
        return 0;
    }
    
    outputWidth = iCodecCtx->width;
    outputHeight = iCodecCtx->height;
    
    start_time = av_gettime_relative();// compute the fps
    
    return YES;
}
/** 只解碼影像 **/
- (BOOL)decodeFrame
{
    const double frames = 25.0;
    int ret = 0;
    int cur_frame_number;
    int frame_number;
    NSTimeInterval timeInterval;
    float ended;
    float start;
    AVPacket *pkt;
    AVStream *st;
    
    
    
    if (!isRead) return NO;
    
    int frameFinished = 0;
    /** 所有解碼存放陣列 **/
//    NSMutableArray *result = [NSMutableArray array];
    
    // Init Packet
    av_init_packet(&iPacket);
    // 清除暫存
    avcodec_flush_buffers(iCodecCtx);
    
    while (!frameFinished && av_read_frame(ifomtCtx, &iPacket) >= 0)
    {
        pkt = &iPacket;
        st = ifomtCtx->streams[vStreamNode];
        cur_frame_number = ((int)pkt->dts/pkt->duration);
        frame_number = iCodecCtx->frame_number;
        start = iCodecCtx->frame_number / frames;
        ended = pkt->pts * av_q2d(st->time_base);
        timeInterval = [_currentTime timeIntervalSinceNow];
        _time = pkt->pts * av_q2d(st->time_base);
        // A Packet of video stream.
        if (iPacket.stream_index == vStreamNode)
        {
            //進行解碼將資料寫入到frame
            avcodec_decode_video2(iCodecCtx, iFrame, &frameFinished, &iPacket);
        }
        
        av_free_packet(&iPacket);
    }
    
    //檢查時間點誤差不能超過0.5 sec
    while (((-timeInterval) - DEFIN_BUFFER_TIME) > ended)
    {
        av_read_frame(ifomtCtx, pkt);
        if (iPacket.stream_index == vStreamNode)
        {
            avcodec_decode_video2(iCodecCtx, iFrame, &frameFinished, &iPacket);
        }
        ended = pkt->pts * av_q2d(st->time_base);
        av_free_packet(&iPacket);
    }
    
    [self avStreamFPSWithStart:start_time end:av_gettime_relative()];
    
    return frameFinished!=0;
    
}
#pragma -mark Set AVOption, AVDictionary
- (AVDictionary *)initConfigAVFormatOptions
{
    AVDictionary *codec_options = NULL;
    av_dict_set( &codec_options, "preset", "ultrafast", 0 ); // 這是坑設定沒有用
    av_dict_set(&codec_options, "tune", "film", 0);// 這也是坑設定沒有用
    av_dict_set(&codec_options, "nobuffer", 0, 0); // 設定關閉Buffer
    av_dict_set(&codec_options, "probesize", "32", 0);// 關閉Streaming大小尺寸
    av_dict_set(&codec_options, "rtbufsize", "0", 0);
    av_dict_set(&codec_options, "analyzeduration", "0", 0);// 關閉分析延遲時間
    av_dict_set_int(&codec_options, "max_delay", 0, 0);
    av_dict_set(&codec_options, "max_interleave_delta", "0", 0);
    av_dict_set(&codec_options, "time_base", "25", 0);
    av_dict_set(&codec_options, "formatprobesize", "2048", 0);
    //    av_dict_set_int(&codec_options, "lowres", 0, 0);
    
    /*
     av_opt_set(ifomtCtx->priv_data, "nobuffer", "0", 0);
     av_opt_set(ifomtCtx->priv_data, "preset", "superfast", 0);
     av_opt_set(ifomtCtx->priv_data, "tune", "zerolatency", 0);
     av_opt_set(ifomtCtx->priv_data, "probesize", 0, 0);
     */
    
    return codec_options;
}
- (void)freeConfigAVFormatOptions:(AVDictionary *)opts
{
    av_dict_free(&opts);
}
/** 參數設定 **/
- (void)configAVCodecContext:(AVCodecContext *)c
{
    av_opt_set(c->priv_data, "rtmp_buffer", "0", 0);
    av_opt_set(c->priv_data, "live", "1", 0);
    av_opt_set(c->priv_data, "rtmp_live", "1", 0);
}
#pragma -mark FrameRate
- (int)frameRate
{
    AVStream *stream = ifomtCtx->streams[vStreamNode];
    NSLog(@"framerate:%i",stream->r_frame_rate.num / stream->r_frame_rate.den);
    return stream->r_frame_rate.num / stream->r_frame_rate.den;
}
/** 計算FPS **/
- (void)avStreamFPSWithStart:(int64_t)start_time end:(int64_t)curr_time{
    float fps;
    float t = ( curr_time - start_time ) / 1000000.0;
    int frameNumber = iCodecCtx->frame_number;
    
    fps = t > 1 ? frameNumber / t : 0;
    
}

#pragma -mark Get MetaData Information

- (NSDictionary *)RTMPMetaDataWithFmtCtxt:(AVFormatContext *)fmt
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    AVDictionaryEntry *tag = NULL;
    while ((tag = av_dict_get(ifomtCtx->metadata, "", tag,
                              AV_DICT_IGNORE_SUFFIX)))
    {
        printf("%s=%s\n", tag->key, tag->value);
        NSString *k = [NSString stringWithFormat:@"%s", tag->key];
        NSString *v = [NSString stringWithFormat:@"%s", tag->value];
        [dict setObject:v forKey:k];
    }
    return dict;
}

- (NSString *)AVStreamDump:(int)_id
{
    switch (_id)
    {
        case AVMEDIA_TYPE_VIDEO:
            return @"video";
            break;
        case AVMEDIA_TYPE_AUDIO:
            return @"audio";
            break;
        case AVMEDIA_TYPE_DATA:
            return @"data";
            break;
        case AVMEDIA_TYPE_SUBTITLE:
            return @"subtitle";
            break;
        case AVMEDIA_TYPE_ATTACHMENT:
            return @"attachment";
            break;
        case AVMEDIA_TYPE_NB:
            return @"nb";
            break;
        default:
            return @"unknown";
            break;
    }
}

- (void)start
{
    _currentTime = [NSDate new];
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
- (void)dealloc
{
    [self close];
    [super dealloc];
}

@end
