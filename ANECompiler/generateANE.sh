#!/bin/sh

echo build dir = $BUILD_DIR
echo project dir = $PROJECT_DIR
echo configuration build dir = $CONFIGURATION_BUILD_DIR
echo air sdk path = $AIR_SDK_PATH

EXTENSION_SWC_FILE_NAME=`/usr/bin/basename "$NATIVEEXTENSION_SWC"`
echo native extension swc = $NATIVEEXTENSION_SWC

NATIVE_EXTENSION_STATIC_LIB_NAME=lib"$PRODUCT_NAME".a

#copy the extension.xml from $PROJECT_DIR/$PRODUCT_NAME/extension.xml to "$CONFIGURATION_BUILD_DIR"
cp -f "$PROJECT_DIR"/ANECompiler/extension.xml "$CONFIGURATION_BUILD_DIR"

#copy the platformoptions.xml from $PROJECT_DIR/$PRODUCT_NAME/platformoptions.xml to "$CONFIGURATION_BUILD_DIR"
cp -f "$PROJECT_DIR"/ANECompiler/platformRTMP.xml "$CONFIGURATION_BUILD_DIR"

#copy the swc from the original location to current configuration directory
echo copying the swc from the original location to the "$CONFIGURATION_BUILD_DIR"
cp -f "$NATIVEEXTENSION_SWC" "$CONFIGURATION_BUILD_DIR" 

echo copying framework file the "$PROJECT_DIR"/ANECompiler/libs.
cp -r "$PROJECT_DIR"/ANECompiler/libs "$CONFIGURATION_BUILD_DIR"/libs

#Extract library.swf from the swc
echo "Extracting library.swf from the swc provided by the user"
mkdir -p -v "$CONFIGURATION_BUILD_DIR"/swcContents
/usr/bin/unzip -o "$NATIVEEXTENSION_SWC" -d "$CONFIGURATION_BUILD_DIR"/swcContents
cp -f "$CONFIGURATION_BUILD_DIR"/swcContents/library.swf "$CONFIGURATION_BUILD_DIR"
#remove the directory swcContents
rm -rf "$CONFIGURATION_BUILD_DIR"/swcContents

read Link_Library
if [[ -z "$Link_Library" ]] ; then
    echo "link_library is empty."
else

    links="${Link_Library} "
    echo "ink_library is not empty."
fi

#Run the ADT command to generate the ANE
pushd "$CONFIGURATION_BUILD_DIR"
"$AIR_SDK_PATH"/bin/adt -package -target ane "$TARGET_NAME" "$CONFIGURATION_BUILD_DIR"/extension.xml -swc "$EXTENSION_SWC_FILE_NAME" -platform iPhone-ARM -platformoptions "$CONFIGURATION_BUILD_DIR"/platformRTMP.xml -C "$CONFIGURATION_BUILD_DIR" "$NATIVE_EXTENSION_STATIC_LIB_NAME" "${links}""$CONFIGURATION_BUILD_DIR"/library.swf
popd

echo "$TARGET_NAME" generated at "$CONFIGURATION_BUILD_DIR"/"$TARGET_NAME" 
