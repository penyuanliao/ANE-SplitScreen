//
//  GLSLRenderYUV.m
//  iFrameExtractor
//
//  Created by mobile on 2015/3/27.
//
//
#import "frameYUV.h"
#import "GLSLRenderYUV.h"

@implementation GLSLRenderYUV
/** 檢查物件是否存在 **/
- (BOOL) isValid
{
    return (_textures[0] != 0);
}
/** compiler fragment shader slgl **/
- (NSString *) fragmentShader
{
    return yuvFragmentShaderString;
}
/** Bind texture2D YUV, Uniform變量 Vertex Shader和Fragment Shader 所共享**/
- (void) resolveUniforms: (GLuint) program
{
    _uniformSamplers[0] = glGetUniformLocation(program, "s_texture_y");
    _uniformSamplers[1] = glGetUniformLocation(program, "s_texture_u");
    _uniformSamplers[2] = glGetUniformLocation(program, "s_texture_v");
}
/** Set YUV Color for texture2D **/
- (void) setFrame: (frameYUV *) frame
{
    frameYUV *yuvFrame = (frameYUV *)frame;
    
    assert(yuvFrame.luma.length == yuvFrame.width * yuvFrame.height);
    assert(yuvFrame.chromaB.length == (yuvFrame.width * yuvFrame.height) / 4);
    assert(yuvFrame.chromaR.length == (yuvFrame.width * yuvFrame.height) / 4);
    
    const NSUInteger frameWidth = frame.width;
    const NSUInteger frameHeight = frame.height;
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4); // 像素儲存格式(圖片大小調整為1個字節)
    
    if (0 == _textures[0])
        glGenTextures(3, _textures); // 1.生成texture文件
    
    const UInt8 *pixels[3] = { yuvFrame.luma.bytes, yuvFrame.chromaB.bytes, yuvFrame.chromaR.bytes };
    const NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
    const NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
    
    for (int i = 0; i < 3; ++i) {
        // 2.綁定物件屬性
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        // 3.將圖片讀進顯示卡的記憶體
        glTexImage2D(GL_TEXTURE_2D,   // 使用Texture2d
                     0,               // 多材質時強化程度
                     GL_LUMINANCE,    // 圖片資料類型[Luminance亮度(yuv)]
                     (int)widths[i],  // Texture高度
                     (int)heights[i], // Texture寬度
                     0,               // 產生圖片邊界大小
                     GL_LUMINANCE,    // 資料組成類型是由yuv
                     GL_UNSIGNED_BYTE,// 資料內容是無符號字節類型
                     pixels[i]);      // 圖片來源資料
        // 4.圖片縮小放大處理
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        // 5.填補圖片大小為2的次方大小
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}
/** 初始化Texture **/
- (BOOL) prepareRender
{
    if (_textures[0] == 0) return NO;
    
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i); // 啟用Texture
        glBindTexture(GL_TEXTURE_2D, _textures[i]); // 綁定Texture to GLSL
        glUniform1i(_uniformSamplers[i], i); // OpenGL 綁定 GLSL
    }
    
    return YES;
}
/** 移除所有物件 **/
- (void) dealloc
{
    if (_textures[0])
        glDeleteTextures(3, _textures);
    
    [super dealloc];
}
@end
