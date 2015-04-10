//
//  ScreenConnect.m
//  AirAirplay
//
//  Created by mobile on 2015/3/9.
//
//
#import "SplitScreen.h"
@interface SplitScreen ()

/** rtmp stream url **/
@property (nonatomic, retain) NSString *URL;

@end



@implementation SplitScreen
@synthesize windows;
@synthesize URL;
//static const char *SCREEN_CHANGE = "SCREEN_CHANGE";
/** OpenGL Darwing **/
static OpenGL *GLVideoView = nil;
//singleton
+ (SplitScreen *)singleton {
    static dispatch_once_t pred;
    static SplitScreen *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[SplitScreen alloc] initWithContext:nil];
        shared.windows = [NSMutableArray arrayWithCapacity:6];
        [shared.windows addObject:[[UIApplication sharedApplication] keyWindow]];
    });
    return shared;
}
/** 初始化物件 **/
- (id)initWithContext:(FREContext)ctx
{
    self = [super init];
    if (self)
    {
        NSInteger screenCount = [[UIScreen screens] count];
        int i = 11;
        NSString *str = [NSString stringWithFormat:@"v0.3.6.%i Screen Did Connect : screen count:%i", i, (int)screenCount];
        [[AirAirplay sharedInstance]asyncyToActionScriptWithString:str event:@"SCREEN_CHANGE"];
       
        [self setupOpenGLView];
        [self airPlayBeEnabled];
    }
    return self;
}
/** 檢查建立時是否有連接AirPlay設備 **/
- (BOOL)airPlayBeEnabled
{
    BOOL result = NO;
    NSArray *screens = [UIScreen screens];
    NSInteger screenCounnt = screens.count;
    if (screenCounnt > 1) {
        result = YES;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]postNotificationName:@"UIScreenDidConnectNotification" object:screens[1]];
        });
        
        [[AirAirplay sharedInstance]asyncyToActionScriptWithString:@"AirPlay-Enabled NO" event:@"SCREEN_CHANGE"];
    }
    return result;
}
/** Drawing Graphics into OpenGLES **/
- (void)setupOpenGLView
{
    GLVideoView = nil;
    GLVideoView = [[OpenGL alloc]init];
}

- (void)setupStreamWithPath:(NSString *)url
{
    if (url == NULL)
    {
        [self log:[NSString stringWithFormat:@"Please enter an RTMP URL."]];
        return;
    }
    
    URL = url;
    
    [[AirAirplay sharedInstance]asyncyToActionScriptWithString:[NSString stringWithFormat:@"Decoder Release is %@", _decoder == nil ? @"NULL" : @"Not NULL"] event:@"RTMPDecoderEvent"];
    
    _decoder = [[RTMPDecoder alloc]initWithRtmp:url];
    [GLVideoView setupOpenGLWithAVFrame:[_decoder iFrame] andCodec:[_decoder iCodecCtx]];
}
- (NSMutableArray *)getWindows
{
    return windows;
}
- (OpenGL *)getVideoView
{
    return GLVideoView;
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
#pragma mark - SplitScreen
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
    //=============================================================
    //                          繪出影像物件
    //=============================================================
    OpenGL *glView = GLVideoView;
    glView.frame = [_screen bounds];
    [_viewController.view addSubview:glView];
    NSString *str = [NSString stringWithFormat:@"Screen bounds:%@ Video Bounds:%@",NSStringFromCGRect(_screen.bounds),NSStringFromCGRect(glView.frame)];
    [[AirAirplay sharedInstance]asyncyToActionScriptWithString:str event:@"UIScreenDidConnecting"];
    [[AirAirplay sharedInstance]startVideoPlay]; // 開始播放
    //=============================================================
    // Add the view controller to it
    // This view controller does not do anything special, just presents a view that tells us
    // what screen we're on
    [_window setRootViewController:_viewController];
    [_window setHidden:NO];
    
}

/** 監聽螢幕設備是否取消連線 **/
+ (void)screenDidDisconnect:(NSNotification *) notification
{
    NSLog(@"Screen did disconnected");
    [[AirAirplay sharedInstance]asyncyToActionScriptWithString:@"Screen connected" event:@"UIScreenDidDisconnected"];
    UIScreen    *_screen    = nil;
    _screen = [notification object];
    NSMutableArray *_wins = [[SplitScreen singleton] getWindows];
    
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
            [GLVideoView removeFromSuperview];
            [[AirAirplay sharedInstance]asyncyToActionScriptWithString:[NSString stringWithFormat:@"Windows %lu", (unsigned long)windowIndex] event:@"UIScreenDidDisconnected"];
        }
    }
}
/**  **/
+ (UIWindow *) createWindowForScreenHandle:(UIScreen *)screen
{
    
    NSLog(@"+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
    NSLog(@"Create windows for screen.");
    
    UIWindow    *_window    = nil;
    NSMutableArray *_wins = [[SplitScreen singleton] getWindows];
    
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
