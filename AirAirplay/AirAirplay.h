#ifndef AirAirplay_AirAirplay_h
#define AirAirplay_AirAirplay_h
#endif

#import "FlashRuntimeExtensions.h"
#import <UIKit/UIKit.h>

@interface  AirAirplay : NSObject
@property (nonatomic, retain) UIImageView *viedoView;
@property float lastFrameTime;

+ (id)sharedInstance;

- (NSString *)createScreenNotify;

- (void)asyncyToActionScriptWithString:(NSString *)str event:(NSString *)evt;

- (void)startVideoPlay;

@end

FREObject init(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]);

void AirplayContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet);
void AirplayContextFinalizer(FREContext ctx);
void AirplayExtInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet );
void AirplayExtFinalizer(void *extData);