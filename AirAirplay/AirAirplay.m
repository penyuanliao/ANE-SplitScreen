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
#import "ScreenConnect.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "iRTMPPlayer.h"

FREContext myCtx = nil;
ScreenConnect *splitScreen;
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
    splitScreen = [ScreenConnect singleton];
//    [self setupVideoPlay];
    return @"sharedInstance";
}
///** 初始化設定播放器 **/
//- (void)setupVideoPlay
//{
//    player = [[iRTMPPlayer alloc]init];
//    [player setupWithVieo:@"rtmp://183.182.70.196:443/video/dabbb/videohd"];
//    [player setScreenSize:CGSizeMake(1280, 720)];
//}
- (void)startVideoPlay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:1.0/25
                                         target:self
                                       selector:@selector(displayNextFrame2:)
                                       userInfo:nil
                                        repeats:YES];
    });
}


-(void)displayNextFrame2:(NSTimer *)timer {
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    
    iRTMPPlayer *player = [splitScreen getPlayer];
    
    if (![player startStreaming]) {
        [timer invalidate];
        return;
    }
    
    [splitScreen getVideoView].image = player.currentImage;
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

DEFINE_ANE_FUNCTION(init)
{
    FREDispatchStatusEventAsync(myCtx, (const uint8_t *)[@"SCREEN_CHANGE" UTF8String], (const uint8_t *)[@"init" UTF8String]);
//    airplay = [[screenNotify alloc] initWithContext:myCtx];
    
    NSString *str = [[AirAirplay sharedInstance] createScreenNotify];
    
    FREDispatchStatusEventAsync(myCtx, (const uint8_t *)[@"SCREEN_CHANGE" UTF8String], (const uint8_t *)[str UTF8String]);
    return NULL;
}
DEFINE_ANE_FUNCTION(videoStreamingStartup)
{
    NSString *url = FREObjectToNSString(argv[0]);
    //@"rtmp://183.182.70.196:443/video/dabbb/videohd"
    [splitScreen setupStreamWithStream:url];
    
    return BoolToFREObject(true);
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

/** AirplayContextInitializer() **/
// The context initializer is called when the runtime creates the extension context instance.
void AirplayContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx,
                               uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet)
{
    
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    NSInteger nbFuntionsToLink = 2;
    *numFunctionsToTest = (int)nbFuntionsToLink;
    
    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * nbFuntionsToLink);
    
    func[0].name = (const uint8_t*) "init";
    func[0].functionData = NULL;
    func[0].function = &init;
    
    func[1].name = (const uint8_t*) "videoStreamingStartup";
    func[1].functionData = NULL;
    func[1].function = &videoStreamingStartup;
    
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

