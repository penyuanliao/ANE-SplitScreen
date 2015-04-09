//
//  OpenGL.h
//  iFrameExtractor
//
//  Created by mobile on 2015/3/27.
//
//
#import "OpenGL.h"
#import "frameYUV.h"
#import "avformat.h"
#import <UIKit/UIKit.h>
#import "GLSLRenderYUV.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>
//需要規範是planar YUV 4:2:0
@interface OpenGL : UIView

@property (readonly, nonatomic, strong) EAGLContext *context;

- (void)setupOpenGLWithAVFrame:(AVFrame *)frame andCodec:(AVCodecContext *)coderCtx;

- (void)setupAVFrame:(AVFrame *)frame andCodec:(AVCodecContext *)coderCtx;

- (void)render:(frameYUV *)frame;

@end
