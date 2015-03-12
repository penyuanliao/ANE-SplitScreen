#!/bin/sh
dir=$PROJECT_DIR
compiler=${dir}/ANECompiler

AudioToolbox=${compiler}/libs/AudioToolbox.framework
AVFoundation=${compiler}libs/AVFoundation.framework
CoreAudio=${compiler}libs/CoreAudio.framework
CoreGraphics=${compiler}libs/CoreGraphics.framework
CoreMotion=${compiler}libs/CoreMotion.framework
GLKit=${compiler}libs/GLKit.framework
libbz2=${compiler}libs/libbz2.1.0.dylib
libz=${compiler}libs/libz.1.dylib
OpenGLES=${compiler}libs/OpenGLES.framework
QuartzCore=${compiler}libs/QuartzCore.framework

echo ${AudioToolbox}

echo “ANE Starting…”

adt -package -target ane ${compiler}/output.ane ${compiler}/extension.xml -swc ${compiler}/iOSExtension.swc -platform iPhone-ARM -platformoptions ${compiler}/platformRTMP.xml -C ${compiler}/ libAirAirplay.a ${compiler}/libs/libffengine-armv7.a ${AudioToolbox} ${AVFoundation} ${CoreAudio} ${CoreGraphics} ${CoreMotion} ${GLKit} ${libbz2} ${libz} ${OpenGLES} ${QuartzCore} ${compiler}/library.swf

echo “ane complete.”

exit 0