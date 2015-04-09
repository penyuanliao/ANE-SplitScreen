//
//  OpenGL.m
//  iFrameExtractor
//
//  Created by mobile on 2015/3/27.
//
//
#import "OpenGL.h"
#import "frameYUV.h"
@interface OpenGL ()

@property (nonatomic) AVFrame *avFrame;
@property (nonatomic) AVCodecContext *avCoderCtx;

@end

@implementation OpenGL {
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLint  _backingWidth;
    GLint  _backingHeight;
    GLfloat _vertices[8];
    GLuint _program;
    GLint  _uniformMatrix;
    
    GLSLRenderYUV *_yuvRender;
    
}

@synthesize context;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
    }
    return self;

}

- (void)setupAVFrame:(AVFrame *)frame andCodec:(AVCodecContext *)coderCtx
{
    _avCoderCtx = coderCtx;
    _avFrame = frame;
}

- (void)setupOpenGLWithAVFrame:(AVFrame *)frame andCodec:(AVCodecContext *)coderCtx
{
    [self setupAVFrame:frame andCodec:coderCtx];
    _yuvRender = [[GLSLRenderYUV alloc]init];
    
    // 準備繪圖的地方
    CAEAGLLayer *eagLayer = (CAEAGLLayer *)self.layer;
    eagLayer.opaque = YES;
    //Init 暫存顏色格式kEAGLColorFormatRGBA8
    [eagLayer setDrawableProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                   kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                   nil]];
    //Init OpenGL ES2 Context
    context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //layer add context
    if (!context || ![EAGLContext setCurrentContext:context]) {
        NSLog(@"[GLSL] Failed to setup EAGLContext.");
    }
    //Init Buffers (一段線性記憶體空間對應圖形顏色)
    glGenFramebuffers(1, &_frameBuffer);
    glGenRenderbuffers(1, &_renderBuffer);
    //Setup Buffers
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    //width & Height buffers (必需小於GL_MAX_RENDERBUFFER_SIZE_EXT value.)
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _frameBuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"[GLSL]Failed to make complete framebuffer object %x", status);
    }
    
    GLenum glErr = glGetError();
    if (GL_NO_ERROR != glErr) {
        NSLog(@"failed to setup GL %x", glErr);
    }
    // 讀取圖形物件
    if (![self loadShaders]) {
        NSLog(@"[GLSL]Failed to load shaders.");
    }
    
    // 應該是四個頂點坐標
    _vertices[0] = -1.0f;  // x0
    _vertices[1] = -1.0f;  // y0
    _vertices[2] =  1.0f;  // x1
    _vertices[3] = -1.0f;  // y1
    _vertices[4] = -1.0f;  // x2
    _vertices[5] =  1.0f;  // y2
    _vertices[6] =  1.0f;  // x3
    _vertices[7] =  1.0f;  // y3
    
    NSLog(@"[ OK ]setupOpenGL");
}
- (BOOL)loadShaders
{
    BOOL result = NO;
    GLuint vertShader = 0;
    GLuint fragShader = 0;
    
    _program = glCreateProgram(); // 建立編譯程序
    
    vertShader = [OpenGL compileShaderWithType:GL_VERTEX_SHADER andShader:vertexShaderString];
    if (!vertShader) goto gotoExit;
    
    fragShader = [OpenGL compileShaderWithType:GL_FRAGMENT_SHADER andShader:yuvFragmentShaderString];
    if (!fragShader) goto gotoExit;
    
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);
    glBindAttribLocation(_program, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIBUTE_TEXCOORD, "texcoord");
    
    glLinkProgram(_program);
    
    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"[GLSL]Failed to link program %d", _program);
        goto gotoExit;
    }
    result = [OpenGL validateProgram:_program];
    _uniformMatrix = glGetUniformLocation(_program, "modelViewProjectionMatrix"); //取出uniform參數
    [_yuvRender resolveUniforms:_program];
    
gotoExit:
    
    if (vertShader) glDeleteShader(vertShader);
    if (fragShader) glDeleteShader(fragShader);
    if (result) {
        NSLog(@"[ OK ] setup GL program");
    }else
    {
        glDeleteProgram(_program);
        _program = 0;
    }
    return result;
}
#pragma -mark Super Class
-(void)layoutSubviews
{
    NSLog(@"Update Display layout subviews.");
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER); // 狀態檢查
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", status);
    } else {
        NSLog(@"[ OK ] setup GL framebuffer %d:%d", _backingWidth, _backingHeight);
    }
    [self updateVertices];
    
    [self render:nil];
    
}

-(void)setContentMode:(UIViewContentMode)contentMode
{
    NSLog(@"log::setContentMode");
    [super setContentMode:contentMode];
     [self updateVertices];
    if (_yuvRender.isValid) {
        [self render:nil];
    }
}

//
- (void)updateVertices
{
    const BOOL fit      = (self.contentMode == UIViewContentModeScaleAspectFit);
    const float _width   = _avCoderCtx != NULL ? _avCoderCtx->width : 0;
    const float _height  = _avCoderCtx != NULL ? _avCoderCtx->height : 0;
    const float dH      = (float)_backingHeight / _height;
    const float dW      = (float)_backingWidth	  / _width;
    const float dd      = fit ? MIN(dH, dW) : MAX(dH, dW);
    const float h       = (_height * dd / (float)_backingHeight);
    const float w       = (_width  * dd / (float)_backingWidth );
    
    _vertices[0] = - w;
    _vertices[1] = - h;
    _vertices[2] =   w;
    _vertices[3] = - h;
    _vertices[4] = - w;
    _vertices[5] =   h;
    _vertices[6] =   w;
    _vertices[7] =   h;
}
/**繪圖**/
- (void)render:(frameYUV *)yuvframe
{
    // texture坐標 GLfloat(u,v);
    static const GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    [EAGLContext setCurrentContext:context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    // 執行 program 程式
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);
    
    if (yuvframe) {
        [_yuvRender setFrame:yuvframe];
    }
    
    if ([_yuvRender prepareRender]) {
        
        GLfloat modelviewProj[16];
        
        mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelviewProj); // 變換矩陣
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
        
        glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);// 當使用glDrawArrays禁止使用
        // (定義的指針, 頂點偏移量, 類型, 0, 資料大小, 資料結構的偏移量)
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
        glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
        
#if 0
        if (!validateProgram(_program))
        {
            LoggerVideo(0, @"Failed to validate program");
            return;
        }
#endif
//        NSLog(@"glDrawArrays();");
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4); // !! 繪圖顯示
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
    
    
    
}

-(void)dealloc
{
    if (_yuvRender) {
        [_yuvRender release]; _yuvRender = nil;
    }
    
    if (_frameBuffer) {
        glDeleteBuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    if (_renderBuffer) {
        glDeleteBuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    context = nil;
    
    [super dealloc];
}

+ (GLuint)compileShaderWithType:(GLenum)type andShader:(NSString *)str
{
    GLint status;
    const GLchar *sources = (GLchar *)str.UTF8String;
    // 1.Create new shader
    GLuint shader = glCreateShader(type);
    if (shader == 0 || shader == GL_INVALID_ENUM)
    {
        NSLog(@"[GLSL] Failed to create shader %d", type);
        return 0;
    }
    glShaderSource(shader, 1, &sources, NULL); // 2.Open Source
    glCompileShader(shader); // 3.Compile code
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        glDeleteShader(shader);
        NSLog(@"[GLSL] Failed to compile shader:\n");
        return 0;
    }
    
    return shader;
}
+ (BOOL)validateProgram:(GLuint)prog
{
    GLint status;
    
    glValidateProgram(prog);
    
    //STR_DEBUG
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    //END_DEBUG
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"[GLSL]Failed to validate program %d", prog);
        return NO;
    }
    
    return YES;
}
/** GLKit layer NOT UIKit layer (Crash drawableProperties method) **/
+ (Class) layerClass
{
    return [CAEAGLLayer class];
}
@end
