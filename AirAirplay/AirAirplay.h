#ifndef AirAirplay_AirAirplay_h
#define AirAirplay_AirAirplay_h
#endif

#import "FlashRuntimeExtensions.h"
#import <UIKit/UIKit.h>

#define DEFINE_ANE_FUNCTION(fun) FREObject fun(FREContext context, void* functionData, uint32_t argc, FREObject argv[])

@interface  AirAirplay : NSObject

@property float lastFrameTime;

+ (id)sharedInstance;

- (NSString *)createScreenNotify;

- (void)asyncyToActionScriptWithString:(NSString *)str event:(NSString *)evt;

- (void)startVideoPlay;

@end

DEFINE_ANE_FUNCTION(init);
DEFINE_ANE_FUNCTION(videoStreamingStartup);

void AirplayContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet);
void AirplayContextFinalizer(FREContext ctx);
void AirplayExtInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet );
void AirplayExtFinalizer(void *extData);



/** ObjC to Flash **/
FREObject BoolToFREObject(BOOL boolean);

/** Flash to ObjC **/
NSString* FREObjectToNSString(FREObject arg);