AirExtensionDeviceInfo
======================
建立執行adt
cd ~
vi ~/.bash_profile
輸入
export PATH=<AIR_SDK_BIN>:$PATH



adobe air sdk 編譯swc問題如果使用xml設定擋的話指令要改成
```
acompc -load-config+=<compiler_swc.xml輸入檔案>-output <mylib.swc輸出檔案>
 
```
### Build ERROR :
not found for architecture armv7
```
Apple LLVM 6.0 - Language - C++
        > C++ Language Dialect GNU++11 [-std=gnu++11]
        > C++ Standard Library libc++ (LLVM C++ standard library with C++11 support)
```

###Using External Frameworks and Libraries

```

AudioToolbox        |  AVFoundation
CoreFoundation      |  CoreGraphics
CoreLocation        |  CoreMedia
CFNetwork           |  CoreVideo
Foundation          |  MobileCoreServices
OpenGLES            |  QuartzCore
SystemConfiguration |  Security
UIKit

```

1. Flash SWC 

..需要設定檔案位置在Project > Targets > AirAirplay.ane > User-Defined
...NATIVEEXTENSION_PATH : 編譯swc需要位置
...NATIVEEXTENSION_SWC : 編譯產生swc檔案位置
...SWF_Include_Classes : class 檔案名稱
...SWF_Version : swf版

2. Compiler ShellScript

generateANE.sh



3. 
...frameYUV.h : 將ffmpeg資料
...GLSLRenderYUV.h : 產生opengl fragment shader
...OpenGL.h : 繪圖主程式
...SplitScreen.h : airplay morrir Controller
...RTMPDecoder.h : FFmpeg rtmp解碼器





//=============================================
File des