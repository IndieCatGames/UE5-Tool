@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
rem 设置UE版本号数组
set "UE_VERSIONS=5.5 5.4"

rem 设置插件目录和输出目录
set "PLUGIN_DIR=D:\UE_Project\PluginsDevProject\Plugins"
set "OUTPUT_DIR=D:\IndieCatGoogleDrive\Fab\UE\Plugins"

rem 初始化结果变量
set "RESULTS="

rem 设置Fab
set "FAB_CONTENT="

echo ==============================================
echo 开始批量打包插件...
echo ==============================================

rem 遍历Plugins目录下的所有.uplugin文件
for /r "%PLUGIN_DIR%" %%P in (*.uplugin) do (
    rem 获取插件名称
    set "PLUGIN_NAME=%%~nP"
    echo ----------------------------------------------
    echo 正在打包插件：!PLUGIN_NAME!
    echo 插件路径：%%P
    
    set "PLUGIN_VERSION="
    rem 从插件文件中提取版本号
    for /f "delims=" %%V in ('findstr /i "VersionName" "%%P"') do (
        rem 获取插件版本号并去掉多余字符
        for /f "tokens=2 delims=:," %%A in ("%%V") do (
            set "PLUGIN_VERSION=%%~A"
            set "PLUGIN_VERSION=!PLUGIN_VERSION: =!"
        )
    )
    
    set "FAB_CONTENT="
    rem 从插件文件中Fab内容
    for /f "delims=" %%F in ('findstr /i "FabURL" "%%P"') do (
        set "FAB_CONTENT=%%~F"
    )
    
    rem 遍历每个UE版本号进行打包
    for %%V in (%UE_VERSIONS%) do (
        set "UE_DIR=D:\Program Files\Epic Games\UE_%%V"
        echo 正在打包UE%%V版本的 !PLUGIN_NAME! 插件...
        
        if not exist "%OUTPUT_DIR%\!PLUGIN_NAME!\!PLUGIN_NAME!_%%V" mkdir "%OUTPUT_DIR%\!PLUGIN_NAME!\!PLUGIN_NAME!_%%V"
        
        rem 检查输出目录中是否已经有同名插件并获取已打包插件的版本号
        set "EXISTING_VERSION="
        set "PLUGIN_FILE=%OUTPUT_DIR%\!PLUGIN_NAME!\!PLUGIN_NAME!_%%V\!PLUGIN_NAME!.uplugin"
        if exist !PLUGIN_FILE! (
            for /f "delims=" %%X in ('findstr /i "VersionName" !PLUGIN_FILE!') do (
                for /f "tokens=2 delims=:," %%C in ("%%X") do (
                    set "EXISTING_VERSION=%%~C"
                    set "EXISTING_VERSION=!EXISTING_VERSION: =!"
                )
            )
        )
        rem 如果版本号不同才执行打包
        if not !PLUGIN_VERSION!==!EXISTING_VERSION! (
            echo 插件版本号不同，开始打包插件：!PLUGIN_NAME! 版本：!PLUGIN_VERSION!
            
            rem 调用RunUAT.bat进行打包
            call "%%UE_DIR%%\Engine\Build\BatchFiles\RunUAT.bat" BuildPlugin ^
                -Plugin=%%P ^
                -Package=%OUTPUT_DIR%\!PLUGIN_NAME!\!PLUGIN_NAME!_%%V ^
                -TargetPlatforms=Win64

            rem 根据打包结果更新RESULTS变量
            if errorlevel 1 (
                set "RESULTS=!RESULTS!❌ 打包UE%%V版本的 !PLUGIN_NAME! 失败！------------------"
            ) else (
                set "RESULTS=!RESULTS!✅ UE%%V版本的 !PLUGIN_NAME! 打包成功！ ------------------"
                
                 rem 创建一个临时文件来存储修改后的内容
                set TEMP_FILE=!PLUGIN_FILE!.tmp
                
                if exist !PLUGIN_FILE! (
                    > !TEMP_FILE! (
                        for /f "delims=" %%P in ('type !PLUGIN_FILE!') do (
                            if !lineNumber! equ 10 (
                                echo !FAB_CONTENT%!
                            )
                            echo %%P
                            set /a lineNumber+=1
                        )
                    )
                     echo !TEMP_FILE!
                     echo !PLUGIN_FILE!
                     move /y !TEMP_FILE! !PLUGIN_FILE!
                     echo 已在11行插入内容。
                )
              
                rem 删除不必要的文件夹
                rd /s /q %OUTPUT_DIR%\!PLUGIN_NAME!\!PLUGIN_NAME!_%%V\Build
                rd /s /q %OUTPUT_DIR%\!PLUGIN_NAME!\!PLUGIN_NAME!_%%V\Intermediate
                rd /s /q %OUTPUT_DIR%\!PLUGIN_NAME!\!PLUGIN_NAME!_%%VSaved
                
                rem 打包整个插件目录为ZIP文件
                echo 正在打包插件为ZIP文件
                powershell -Command Compress-Archive -Path %OUTPUT_DIR%\!PLUGIN_NAME!\!PLUGIN_NAME!_%%V -DestinationPath %OUTPUT_DIR%\!PLUGIN_NAME!\!PLUGIN_NAME!_%%V.zip -Force
            )
        ) else (
            echo 插件版本号相同，跳过打包：!PLUGIN_NAME! 版本：!PLUGIN_VERSION!
        )
        echo ----------------------------------------------
    )
)

rem 输出最终打包结果
echo ==============================================
echo 所有插件的多版本打包任务已完成！
echo !RESULTS!
echo 输出路径为：%OUTPUT_DIR% 
echo ==============================================

pause
