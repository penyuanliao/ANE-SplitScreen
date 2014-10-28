AirExtensionDeviceInfo
======================

<a>設定</a>
Java
-----

ANT
-----
```xml
<?xml version="1.0"?>
<!- default_預設開始編譯 basedir_檔案位置路徑-->
<project name="ANT編譯名稱" default="main" basedir=".">
<!-- 設定變數 -->
<property name=" FLEX_HOME " value="你的Flex SDK 路徑"/>
<!-- 重要flash編譯需要的jar -->
<taskdef resource="flexTasks.tasks" classpath="${FLEX_HOME}/ant"/>
<!-- Flash Develop swf檔案位置 -->
<property name="DEPLOY.dir" value="${basedir}/bin"/>
<!-- 主要編譯事件depends:執行順序 -->
<target name="main" depends="clean, compile"/>
<!-- Dos 刪除指令 -->
<target name="clean">
    <delete dir="${DEPLOY.dir}"/>
    <mkdir dir="${DEPLOY.dir}"/>
</target>
<!-- 編譯SWF物件 -->
    <target name="compile">
        <mxmlc
        file="${basedir}/src/SedieHDMain.as"
        output="${DEPLOY_DIR}/output.swf"  
        show-actionscript-warnings="true" 
        failonerror="true" 
        debug="false" 
        maxmemory="1024m">
            <!-- Embed links -->
            <static-link-runtime-shared-libraries>true</static-link-runtime-shared-libraries>
            <load-config filename="${FLEX_HOME}/frameworks/flex-config.xml"/>
            <load-config append="true" filename="${basedir}\obj\soundConfig.xml"/>
            <source-path path-element="${basedir}/src"/>
            <!-- classpath檔案 -->
            <source-path path-element="${FLEX_HOME}/frameworks"/>
        </mxmlc>
    </target>
</project>
```
