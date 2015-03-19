//
//  ScreenConnect.m
//  AirAirplay
//
//  Created by mobile on 2015/3/9.
//
//

#import "ScreenConnect.h"

@implementation ScreenConnect

static const char *SCREEN_CHANGE = "SCREEN_CHANGE";

static FREContext g_cxt;
static NSMutableArray *_windows = nil;

- (id)initWithContext:(FREContext)ctx
{
    self = [super init];
    if (self)
    {
        g_cxt = ctx;
        NSInteger screenCount = [[UIScreen screens] count];
        NSString *str = [NSString stringWithFormat:@"v3.5.0 Screen Did Connect : screen count:%i", (int)screenCount];
        FREDispatchStatusEventAsync(g_cxt, (const uint8_t *)SCREEN_CHANGE, (const uint8_t *)[str UTF8String]);
        [[AirAirplay sharedInstance]asyncyToActionScriptWithString:@"Starting..." event:@"SCREEN_CHANGE"];
    }
    return self;
}
//hack, this is called before UIApplicationDidFinishLaunching
+ (void) load
{
    NSLog(@"UIScreen Did Connect load()");
    // Register for notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenDidConnect:)
                                                 name:@"UIScreenDidConnectNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenDidDisconnect:)
                                                 name:@"UIScreenDidDisconnectNotification"
                                               object:nil];
}
#pragma mark - screen connect
+ (void)screenDidConnect:(NSNotification *) notification
{
    [[AirAirplay sharedInstance]asyncyToActionScriptWithString:@"Screen connected" event:@"UIScreenDidConnecting"];
    NSLog(@"Screen did connecting");
    UIScreen                    *_screen            = nil;
    UIWindow                    *_window            = nil;
    UIViewController            *_viewController    = nil;
    
    _screen = [notification object];
    _window = [self createWindowForScreenHandle:_screen];
    
    // Get a window for it
    _viewController = [[[UIViewController alloc] init] autorelease];
    _viewController.view.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    [_viewController.view addSubview:[[AirAirplay sharedInstance]viedoView]];
    [[AirAirplay sharedInstance]startVideoPlay];
    // Add the view controller to it
    // This view controller does not do anything special, just presents a view that tells us
    // what screen we're on
    [_window setRootViewController:_viewController];
    [_window setHidden:NO];
    
}

/** 監聽螢幕設備是否連線 **/
+ (void)screenDidDisconnect:(NSNotification *) notification
{
    NSLog(@"Screen did disconnected");
    [[AirAirplay sharedInstance]asyncyToActionScriptWithString:@"Screen connected" event:@"UIScreenDidDisconnected"];
    UIScreen    *_screen    = nil;
    _screen = [notification object];

    // Find any window attached to this screen, remove it from our window list, and release it.
    for (UIWindow *_window in _windows)
    {
        if (_window.screen == _screen)
        {
            NSUInteger windowIndex = [_windows indexOfObject:_window];
            [_windows removeObjectAtIndex:windowIndex];
            // If it wasn't autorelease, you would deallocate it here.
        }
    }
    return;
}
+ (UIWindow *) createWindowForScreenHandle:(UIScreen *)screen
{
    
    NSLog(@"+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
    NSLog(@"Create windows for screen.");
    
    UIWindow    *_window    = nil;
    NSMutableArray *_wins = _windows;
    
    NSLog(@"Init windows NSArray.");
    
    if (_wins == nil) {
        //初始化記錄所有介面物件
        _wins = [[NSMutableArray alloc]initWithCapacity:6];
        //增加當下視窗物件
        [_wins addObject:[[UIApplication sharedApplication] keyWindow]];
    }
    
    NSLog(@"Search current window for this screen.");
    
    // Do we already have a window for this screen?
    for (UIWindow *window in _wins) {
        if (window.screen == screen) {
            _window = window;
        }
    }
    
    NSLog(@"Is Null Create a new one Window.");
    
    // Still nil? Create a new one.
    if (_window == nil) {
        _window = [[UIWindow alloc] initWithFrame:[screen bounds]];
        [_window setScreen:screen];
        [_wins addObject:_window];
    }
    NSLog(@"return ended.");
    NSLog(@"+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
    return _window;
}
@end
