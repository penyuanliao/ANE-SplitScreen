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
#import "iRTMPPlayer.h"

@interface ScreenConnect : NSObject
/** screen window object **/
@property (nonatomic, retain) NSMutableArray *windows;

+ (void) load;

+ (void) screenDidConnect:(NSNotification *) notification;

+ (id)singleton;

- (id) initWithContext:(FREContext)ctx;

- (void) setupStreamWithStream:(NSString *)url;

- (NSMutableArray *)getWindows;

- (UIImageView *) getVideoView;

- (iRTMPPlayer *) getPlayer;

@end
