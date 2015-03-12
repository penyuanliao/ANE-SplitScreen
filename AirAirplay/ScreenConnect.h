//
//  ScreenConnect.h
//  AirAirplay
//
//  Created by mobile on 2015/3/9.
//
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"
#import "AirAirplay.h"

@interface ScreenConnect : NSObject

+ (void) load;

+ (void) screenDidConnect:(NSNotification *) notification;

- (id)initWithContext:(FREContext)ctx;

@end
