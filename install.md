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
