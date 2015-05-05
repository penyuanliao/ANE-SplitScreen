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
#import "RTMPDecoder.h"
#import "OpenGL.h"

@interface SplitScreen : NSObject
/** screen window object **/
@property (nonatomic, retain) NSMutableArray *windows;
/** ffmpeg decoder RTMP VP6 movie **/
@property (nonatomic, retain) RTMPDecoder *decoder;

+ (void) load;

+ (void) screenDidConnect:(NSNotification *) notification;

+ (id) singleton;

- (id)initWithContext:(FREContext)ctx;

- (void)setupStreamWithPath:(NSString *)url;

- (NSMutableArray *)getWindows;

- (OpenGL *) getVideoView;

- (void)videoClose;

@end
