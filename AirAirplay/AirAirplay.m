//
//  AirAirplay.m
//  AirAirplay
//
//  Created by mobile on 2015/3/9.
// adt -package -target ane /Users/mobile/Documents/build/output.ane /Users/mobile/Documents/build/extension.xml -swc /Users/mobile/Documents/build/iOSExtension.swc -platform iPhone-ARM -C /Users/mobile/Documents/build/ libAirAirplay.a library.swf -platformoptions /Users/mobile/Documents/build/platformRTMP.xml

//
#import "FlashRuntimeExtensions.h"
#import <UIKit/UIApplication.h>
#import <UIKit/UIAlertView.h>
#import "AirAirplay.h"
#import "SplitScreen.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "frameYUV.h"

FREContext myCtx = nil;
SplitScreen *_splitScreen;

@implementation AirAirplay
@synthesize lastFrameTime;

//static iRTMPPlayer *player = nil;
static AirAirplay *sharedInstance = nil;

+ (AirAirplay *)sharedInstance
{
    if (sharedInstance == nil)
    {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

- (id)copy
{
    return self;
}


- (NSString *)createScreenNotify
{
    _splitScreen = [SplitScreen singleton];
//    [self setupVideoPlay];
    return @"sharedInstance";
}
///** 初始化設定播放器 **/
- (void)startVideoPlay
{
    __block RTMPDecoder *_decoder = [_splitScreen decoder];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_decoder != nil) {
            [_decoder start];
            _decoder = NULL;
        }
        [NSTimer scheduledTimerWithTimeInterval:1.0/60.0
                                         target:self
                                       selector:@selector(displayNextFrame:)
                                       userInfo:nil
                                        repeats:YES];
    });
}

-(void)displayNextFrame:(NSTimer *)timer
{
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    
    RTMPDecoder *_decoder = [_splitScreen decoder];
    
    if (![_decoder decodeFrame]) {
        [timer invalidate];
        return;
    }
    
    frameYUV *yuv = [[frameYUV alloc]initWithAVFrame:_decoder.iFrame andCodec:_decoder.iCodecCtx];
    [[_splitScreen getVideoView] render:yuv];
    
    float frameTime = 1.0/([NSDate timeIntervalSinceReferenceDate]-startTime);
    if (lastFrameTime<0) {
        lastFrameTime = frameTime;
    } else {
    }
    NSLog(@"time:%@",[NSString stringWithFormat:@"%.0f",lastFrameTime]);
}
/* Remote Response Event ActionScript */
- (void)asyncyToActionScriptWithString:(NSString *)str event:(NSString *)evt
{
    FREDispatchStatusEventAsync(myCtx, (const uint8_t *)[evt UTF8String], (const uint8_t *)[str UTF8String]);
}
@end
/** 初始化物件 **/
DEFINE_ANE_FUNCTION(init)
{
    FREDispatchStatusEventAsync(myCtx, (const uint8_t *)[@"SCREEN_CHANGE" UTF8String], (const uint8_t *)[@"init" UTF8String]);
//    airplay = [[screenNotify alloc] initWithContext:myCtx];
    
    NSString *str = [[AirAirplay sharedInstance] createScreenNotify];
    
    FREDispatchStatusEventAsync(myCtx, (const uint8_t *)[@"SCREEN_CHANGE" UTF8String], (const uint8_t *)[str UTF8String]);
    return NULL;
}
/** 開始播放 **/
DEFINE_ANE_FUNCTION(videoConnect)
{
    NSString *url = FREObjectToNSString(argv[0]);
    FREDispatchStatusEventAsync(myCtx, (const uint8_t *)[@"stremStartup" UTF8String], (const uint8_t *)[url UTF8String]);
    //@"rtmp://183.182.70.196:443/video/dabbb/videohd"
    [_splitScreen setupStreamWithPath:url]; // 新增影片網址
    return BoolToFREObject(true);
}
/** 停止播放 **/
DEFINE_ANE_FUNCTION(videoClose)
{
    [_splitScreen videoClose];
    
    return BoolToFREObject(true);
}
DEFINE_ANE_FUNCTION(dispatchStreamFPSInfo)
{
    BOOL fpsEnabled = FREObjectToBOOL(argv[0]);
    
    [_splitScreen dispatchStreamFPSInfo:fpsEnabled];
    
    return BoolToFREObject(true);
}

DEFINE_ANE_FUNCTION(dispatchStreamMetaDataInfo)
{
    BOOL metaDataEnabled = FREObjectToBOOL(argv[0]);
    
    [_splitScreen dispatchStreamMetaDataInfo:metaDataEnabled];
    
    return BoolToFREObject(true);
}

DEFINE_ANE_FUNCTION(isSupported)
{
    NSLog(@"Entering IsSupported()");
    
    FREObject fo;
    
    FREResult aResult = FRENewObjectFromBool(YES, &fo);
    if (aResult == FRE_OK)
    {
        NSLog(@"Result = %d", aResult);
    }
    else
    {
        NSLog(@"Result = %d", aResult);
    }
    
    NSLog(@"Exiting IsSupported()");
    return fo;
}

// Return FREObject
FREObject BoolToFREObject(BOOL boolean)
{
    FREObject result;
    uint32_t value = boolean;
    FRENewObjectFromBool(value, &result);
    return result;
}
NSString* FREObjectToNSString(FREObject arg)
{
    uint32_t strSize;
    const uint8_t *strCr;
    FREGetObjectAsUTF8(arg, &strSize, &strCr);
    NSString *str = [NSString stringWithUTF8String:(char *)strCr];
    return str;
}
BOOL FREObjectToBOOL(FREObject arg)
{
    uint32_t val;
    FREGetObjectAsBool(arg, &val);
    return (BOOL)val;
}

/** AirplayContextInitializer() **/
// The context initializer is called when the runtime creates the extension context instance.
void AirplayContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx,
                               uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet)
{
    
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    NSInteger nbFuntionsToLink = 6;
    *numFunctionsToTest = (int)nbFuntionsToLink;
    
    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * nbFuntionsToLink);
    
    func[0].name = (const uint8_t*) "init";
    func[0].functionData = NULL;
    func[0].function = &init;
    
    func[1].name = (const uint8_t*) "videoConnect";
    func[1].functionData = NULL;
    func[1].function = &videoConnect;
    
    func[2].name = (const uint8_t*) "videoClose";
    func[2].functionData = NULL;
    func[2].function = &videoClose;
    
    func[3].name = (const uint8_t*) "dispatchStreamFPSInfo";
    func[3].functionData = NULL;
    func[3].function = &dispatchStreamFPSInfo;

    func[4].name = (const uint8_t*) "dispatchStreamMetaDataInfo";
    func[4].functionData = NULL;
    func[4].function = &dispatchStreamMetaDataInfo;
    
    *functionsToSet = func;
    
    myCtx = ctx;
}

// Set when the context extension is created.

void AirplayContextFinalizer(FREContext ctx) {
    NSLog(@"Entering ContextFinalizer()");
    
    NSLog(@"Exiting ContextFinalizer()");
}

// The extension initializer is called the first time the ActionScript side of the extension
// calls ExtensionContext.createExtensionContext() for any context.

void AirplayExtInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet )
{
    
    NSLog(@"Entering ExtInitializer()");
    
    *extDataToSet = NULL;
    *ctxInitializerToSet = &AirplayContextInitializer;
    *ctxFinalizerToSet = &AirplayContextFinalizer;
    
    NSLog(@"Exiting ExtInitializer()");
}

void AirplayExtFinalizer(void *extData) { }

