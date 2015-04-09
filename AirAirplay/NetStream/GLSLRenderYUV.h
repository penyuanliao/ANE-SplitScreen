//
//  GLSLRenderYUV.h
//  iFrameExtractor
//
//  Created by mobile on 2015/3/27.
//
//
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import <Foundation/Foundation.h>
#import "OpenGL.h"
#import "frameYUV.h"

#pragma mark - gl view

enum {
    ATTRIBUTE_VERTEX,
   	ATTRIBUTE_TEXCOORD,
};

#define STR_Source(x) #x
#define openGLSLHandler(x) STR_Source(x)
#define OPGL_VERTX_SHADER_STR(text) @ openGLSLHandler(text)
/** OpenGL Shader GLSL **/
// 記錄頂點坐標 -> 頂點著色器(shader)
// vec4:4 個浮點數組成的向量
// vec2:2 個浮點數組成的向量
// mat4: 浮點數的 4X4 矩陣
static NSString *const vertexShaderString = OPGL_VERTX_SHADER_STR
(
 attribute vec4 position;
 attribute vec2 texcoord;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_texcoord;
 
 void main()
 {
     gl_Position = modelViewProjectionMatrix * position;
     v_texcoord = texcoord.xy;
 }
 );
// 記錄顏色數值 -> 片斷著色器(shader)
// sampler2D 用來存取二維紋理的句柄
// uniform:類似全域變數, attribute:只能使用在vertex, varying:使用在vertex與fragment shader傳遞
static NSString *const yuvFragmentShaderString = OPGL_VERTX_SHADER_STR
(
 
 varying highp vec2 v_texcoord;
 uniform sampler2D s_texture_y;
 uniform sampler2D s_texture_u;
 uniform sampler2D s_texture_v;
 
 void main()
 {
     highp float y = texture2D(s_texture_y, v_texcoord).r;
     highp float u = texture2D(s_texture_u, v_texcoord).r - 0.5;
     highp float v = texture2D(s_texture_v, v_texcoord).r - 0.5;
     
     highp float r = y +             1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;
     
     gl_FragColor = vec4(r,g,b,1.0);
 }
 
);
/** 正交投影(OpenGL ES 2.0需要自己實現) **/
static void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout)
{
    float r_l = right - left;
    float t_b = top - bottom;
    float f_n = far - near;
    float tx = - (right + left) / (right - left);
    float ty = - (top + bottom) / (top - bottom);
    float tz = - (far + near) / (far - near);
    
    mout[0] = 2.0f / r_l;
    mout[1] = 0.0f;
    mout[2] = 0.0f;
    mout[3] = 0.0f;
    
    mout[4] = 0.0f;
    mout[5] = 2.0f / t_b;
    mout[6] = 0.0f;
    mout[7] = 0.0f;
    
    mout[8] = 0.0f;
    mout[9] = 0.0f;
    mout[10] = -2.0f / f_n;
    mout[11] = 0.0f;
    
    mout[12] = tx;
    mout[13] = ty;
    mout[14] = tz;
    mout[15] = 1.0f;
}

#pragma mark - frame renderers
@protocol GLSLRender
- (BOOL) isValid;
- (NSString *) fragmentShader;
- (void) resolveUniforms: (GLuint) program;
- (void) setFrame: (frameYUV *) frame;
- (BOOL) prepareRender;
@end

@interface GLSLRenderYUV : NSObject <GLSLRender>
{
    GLuint _uniformSamplers[3];
    GLuint _textures[3];
}
@end
