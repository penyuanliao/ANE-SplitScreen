//
//  ScreenConnect.m
//  AirAirplay
//
//  Created by mobile on 2015/3/9.
//
//

#import "ScreenConnect.h"
@interface ScreenConnect ()

/** rtmp stream url **/
@property (nonatomic, retain) NSString *URL;

@end



@implementation ScreenConnect
@synthesize windows;
@synthesize URL;
//static const char *SCREEN_CHANGE = "SCREEN_CHANGE";
static UIImageView *videoView = nil;
static iRTMPPlayer *player = nil;
//singleton
+ (ScreenConnect *)singleton {
    static dispatch_once_t pred;
    static ScreenConnect *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[ScreenConnect alloc] initWithContext:nil];
        shared.windows = [NSMutableArray arrayWithCapacity:6];
        [shared.windows addObject:[[UIApplication sharedApplication] keyWindow]];
    });
    return shared;
}

- (id)initWithContext:(FREContext)ctx
{
    self = [super init];
    if (self)
    {
        NSInteger screenCount = [[UIScreen screens] count];
        NSString *str = [NSString stringWithFormat:@"v3.5.24 Screen Did Connect : screen count:%i", (int)screenCount];
        [[AirAirplay sharedInstance]asyncyToActionScriptWithString:str event:@"SCREEN_CHANGE"];
       
        [self setupVideoView];
    }
    return self;
}

- (void)setupVideoView {
    
    videoView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 1280, 720)];
    videoView.backgroundColor = [UIColor blackColor];

}
- (void)setupStreamWithStream:(NSString *)url
{
    if (url == NULL)
    {
        [self log:[NSString stringWithFormat:@"Please enter an RTMP URL."]];
        return;
    }
    
    URL = url;
    
    if (player != nil)
    {
        [[AirAirplay sharedInstance]asyncyToActionScriptWithString:@"Player Release" event:@"UIScreenDidDisconnected"];
        [player release]; player = nil;
    }
    player = [[iRTMPPlayer alloc]init];
    [player setupWithVieo:url];
    [player setScreenSize:CGSizeMake(1280, 720)];
}
- (NSMutableArray *)getWindows
{
    return windows;
}
- (UIImageView *)getVideoView
{
    return videoView;
}
- (iRTMPPlayer *)getPlayer
{
    return player;
}
- (void)log:(NSString *)str
{
     [[AirAirplay sharedInstance]asyncyToActionScriptWithString:str event:@"Stream_Error_Event"];
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
    _viewController = [[[UIViewController alloc] init]autorelease];
    _viewController.view.backgroundColor = [UIColor blueColor];
    UIImageView *view = videoView;
    view.frame = [_screen bounds];
    [_viewController.view addSubview:view];
    NSString *str = [NSString stringWithFormat:@"Screen bounds:%@ Video Bounds:%@",NSStringFromCGRect(_screen.bounds),NSStringFromCGRect(view.frame)];
    [[AirAirplay sharedInstance]asyncyToActionScriptWithString:str event:@"UIScreenDidConnecting"];
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
    NSMutableArray *_wins = [[ScreenConnect singleton] getWindows];
    
    if (_wins == NULL)
    {
        [[AirAirplay sharedInstance]asyncyToActionScriptWithString:@"Windows Array is Null." event:@"UIScreenDidDisconnected"];
        return;
    }
    
    // Find any window attached to this screen, remove it from our window list, and release it.
    for (UIWindow *_window in _wins)
    {
        if (_window.screen == _screen)
        {
            NSUInteger windowIndex = [_wins indexOfObject:_window];
            [_wins removeObjectAtIndex:windowIndex];
            // If it wasn't autorelease, you would deallocate it here.
            [videoView removeFromSuperview];
            [[AirAirplay sharedInstance]asyncyToActionScriptWithString:[NSString stringWithFormat:@"Windows %lu", (unsigned long)windowIndex] event:@"UIScreenDidDisconnected"];
        }
    }
}
+ (UIWindow *) createWindowForScreenHandle:(UIScreen *)screen
{
    
    NSLog(@"+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
    NSLog(@"Create windows for screen.");
    
    UIWindow    *_window    = nil;
    NSMutableArray *_wins = [[ScreenConnect singleton] getWindows];
    
    NSLog(@"Init windows NSArray.");
    
    if (_wins == nil) {
        //初始化記錄所有介面物件
        _wins = [[NSMutableArray alloc]initWithCapacity:6];
        //增加當下視窗物件
        [_wins addObject:[[UIApplication sharedApplication] keyWindow]];
        
        [[AirAirplay sharedInstance]asyncyToActionScriptWithString:[NSString stringWithFormat:@"Create windows Array.%i", (int)[_wins count]] event:@"UIScreenDidDisconnected"];
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
