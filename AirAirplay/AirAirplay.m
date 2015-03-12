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

#define DEFINE_ANE_FUNCTION(fn) FREObject (fn)(FREContext context, void* functionData, uint32_t argc, FREObject argv[])

FREContext myCtx = nil;

@implementation AirAirplay

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
    ScreenConnect *sc = [[ScreenConnect alloc]initWithContext:myCtx];
    return @"sharedInstance";
}
/* Remote Response Event ActionScript */
- (void)asyncyToActionScriptWithString:(NSString *)str event:(NSString *)evt
{
    FREDispatchStatusEventAsync(myCtx, (const uint8_t *)[evt UTF8String], (const uint8_t *)[str UTF8String]);
}
@end




FREObject init(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[])
{
    FREDispatchStatusEventAsync(myCtx, (const uint8_t *)[@"SCREEN_CHANGE" UTF8String], (const uint8_t *)[@"init" UTF8String]);
//    airplay = [[screenNotify alloc] initWithContext:myCtx];
    
    NSString *str = [[AirAirplay sharedInstance] createScreenNotify];
    FREDispatchStatusEventAsync(myCtx, (const uint8_t *)[@"SCREEN_CHANGE" UTF8String], (const uint8_t *)[str UTF8String]);
    return NULL;
}

// AirplayContextInitializer()
//
// The context initializer is called when the runtime creates the extension context instance.
void AirplayContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx,
                               uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet)
{
    
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    NSInteger nbFuntionsToLink = 1;
    *numFunctionsToTest = (int)nbFuntionsToLink;
    
    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * nbFuntionsToLink);
    
    func[0].name = (const uint8_t*) "init";
    func[0].functionData = NULL;
    func[0].function = &init;
    
    
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

