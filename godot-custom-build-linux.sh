#!/usr/bin/env bash
# Godot Custom Linux Build Script v1.2
# Created by Polluted Mind
# Note: Only tested on Pop OS 22.04.
# TODO: optimize old file deletion, option to not include modules without further prompts, option for git pull on rebuild, more testing in different target modes

echo "Welcome to the Cult of the Blue Robot."

# go to the correct folder (back one), remove old folders
echo "Begin a new engine build, rebuild an existing one in this folder, or build templates? (BUILD/rebuild/templates)"
read BUILD_TYPE
if [ "$BUILD_TYPE" == "" ]
then
    BUILD_TYPE="build"
fi

#######################
### TEMPLATES ONLY ####
#######################

# templates are an entire branch of their own as they do not require git clones or module compilation as everything should already be there.
if [ $BUILD_TYPE == "templates" ]
then
    cd ..
    mv godot-* godot

    # build options
    echo "Below settings should match existing build (I need to learn how to cache this)."
    echo "Choose your Godot version (e.g. 4.1.3-stable, 4.1, master) or default - latest stable release."
    read GODOT_VERSION
    if [ "$GODOT_VERSION" == "" ]
    then
        GODOT_VERSION="4.1.3-stable"
    fi
    echo "What platform are you building for? (LINUXBSD, windows, macos, server, etc.)"
    read PLATFORM
    if [ "$PLATFORM" == "" ]
    then
        PLATFORM="linuxbsd"
    fi
    if [ $PLATFORM == "macos" ] # currently unsupported for cross-compile due to MoltenVK errors.
    then
        echo "NOTE: If osxcross initial setup is struggling, try installing the libbz2-dev package for SDK extraction."
        export OSXCROSS_ROOT="$HOME/osxcross"
    fi
    echo "What architecture are you building on? (X86_64, arm64, rv64, wasm32, etc.)"
    read ARCH
    if [ "$ARCH" == "" ]
    then
        ARCH="x86_64"
    fi
    echo "Are you using custom modules? (y/N)"
    read CUSTOM
    if [ "$CUSTOM" == "" ]
    then
        CUSTOM="n"
    fi
    echo "How many threads would you like to use for building? (default 16)"
    read THREADCOUNT
    if [ "$THREADCOUNT" == "" ]
    then
        THREADCOUNT="16"
    fi
    echo "Do you want PCK encryption support? (y/N)"
    read B_ENCRYPT
    if [ "$B_ENCRYPT" == "" ]
    then
        B_ENCRYPT="n"
    fi
    if [ $B_ENCRYPT == "y" ]
    then
        export SCRIPT_AES256_ENCRYPTION_KEY="8198992e4523238ab8f520d65b7c54b83347c33a6897855547e3639a594d6a91"
    fi
    echo "Choose template type (template_debug/template_release/BOTH)"
    read TEMPLATE_TYPE
    if [ "$TEMPLATE_TYPE" == "" ]
    then
        TEMPLATE_TYPE="both"
    fi
    echo "Enable .NET (C#) support? (YES/no) NOTE: requires .NET SDK 6/7 to be installed, ~/.dotnet may also need to be in PATH."
    read B_DOTNET
    if [ "$B_DOTNET" == "" ]
    then
        B_DOTNET="yes"
    fi
    echo "Enable dev_mode for warnings as errors and unit testing? (yes/NO) This is useful when doing engine development. NOTE: seems to not play well with some modules."
    read B_DEVMODE
    if [ "$B_DEVMODE" == "" ]
    then
        B_DEVMODE="no"
    fi
    if [ $B_DEVMODE == "no" ]
    then
        B_DEVBUILD="no"
        B_DEBUGSYMBOLS="no"
        echo "Enable production mode for better optimization and portability? (yes/NO) This is useful for exporting final game builds."
        read B_OPTIMIZE
        if [ "$B_OPTIMIZE" == "" ]
        then
            B_OPTIMIZE="no"
        fi
    else
        B_OPTIMIZE="no"
        echo "Enable dev_build mode for disabling optimization and enabling debug symbols? (yes/NO) Also useful for engine development. NOTE: seems to not play well with some modules."
        read B_DEVBUILD
        if [ "$B_DEVBUILD" == "" ]
        then
            B_DEVBUILD="no"
        fi
        if [ $B_DEVBUILD == "yes" ]
        then
            echo "Additionally enable debugging symbols for debugger and profiler support? (YES/no)"
            read B_DEBUGSYMBOLS
            if [ "$B_DEBUGSYMBOLS" == "" ]
            then
                B_DEBUGSYMBOLS="yes"
            fi
        else
            B_DEBUGSYMBOLS="no"
        fi
    fi
    echo "Choose an optimization level. This should align well with previous choices. (SPEED_TRACE/speed/size/debug/none)"
    read OPT_LEVEL
    if [ "$OPT_LEVEL" == "" ]
    then
        OPT_LEVEL="speed_trace"
    fi
    echo "Use single or double precision? (SINGLE/double)"
    read PRECISION_LEVEL
    if [ "$PRECISION_LEVEL" == "" ]
    then
        PRECISION_LEVEL="single"
    fi

    if [ $B_OPTIMIZE == 'no' ]
    then
        echo "Use Clang & LLVM instead of GCC to compile? (yes/NO)"
        read B_CLANG
        if [ "$B_CLANG" == "" ]
        then
            B_CLANG="no"
        fi
        echo "Use the Mold linker for faster compiles? (yes/NO) This may not work on all systems after setup."
        read B_MOLD
        if [ "$B_MOLD" == "" ]
        then
            B_MOLD="no"
        fi
    else
        B_CLANG="no"
        B_MOLD="no"
    fi

    cd godot/

    # rename Godot folder appropriately (do this late to avoid errors)
    if [ $CUSTOM == 'y' ]
    then
        mv ../godot ../godot-"$GODOT_VERSION"-CUSTOM
    else
        mv ../godot ../godot-"$GODOT_VERSION"
    fi

    echo "#### Now building export template(s). ####"
    if [ $TEMPLATE_TYPE == 'both' ]
    then
        pyston-scons platform="$PLATFORM" arch="$ARCH" target=template_debug dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
        pyston-scons platform="$PLATFORM" arch="$ARCH" target=template_release dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
    else
        pyston-scons platform="$PLATFORM" arch="$ARCH" target="$TEMPLATE_TYPE" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
    fi

    cd bin/
    echo "#### Build complete! Enjoy your cult membership! ####"

#######################
#### ENGINE BUILD #####
#######################

else
    if [ $BUILD_TYPE == "build" ]
    then # if building, pick engine version and modules.
        cd ..
        echo "Deleting any old builds from owning folder."
        sudo rm -r godot-* godotsteam limboai voxel

        echo "Choose your Godot version (e.g. 4.1.3-stable, 4.1, master) or default - latest stable release."
        read GODOT_VERSION
        if [ "$GODOT_VERSION" == "" ]
        then
            GODOT_VERSION="4.1.3-stable"
        fi
        
        echo "Include community modules? (y/N)"
        read B_COMMUNITY
        if [ "$B_COMMUNITY" = "" ]
        then
            B_COMMUNITY="n"
        fi

        if [ $B_COMMUNITY = "y" ]
        then
            # community engine modules
            echo "Do you want LimboAI? (Y/n)"
            read B_LIMBOAI
            if [ "$B_LIMBOAI" == "" ]
            then
                B_LIMBOAI="y"
            fi
            if [ $B_LIMBOAI == 'y' ]
            then
                echo "Do you want the latest limboai nightly build? (Y/n)"
                read B_LIMBOAI_NIGHTLY
                if [ "$B_LIMBOAI_NIGHTLY" == "" ]
                then
                    B_LIMBOAI_NIGHTLY="y"
                fi
            fi

            echo "Do you want Godot Steam? (y/N) NOTE: requires Steamworks SDK to be unzipped in an adjacent folder called steam_sdk, and put your steam_appid.txt in there, too!"
            echo "Double NOTE: Don't cross-compile on Linux for Windows using MinGW with this module; compile natively on Windows using MSVC instead. See GodotSteam Github note."
            read B_GD_STEAM
            if [ "$B_GD_STEAM" == "" ]
            then
                B_GD_STEAM="n"
            fi

            echo "Do you want Godot Voxel? (y/N)"
            read B_GD_VOXEL
            if [ "$B_GD_VOXEL" == "" ]
            then
                B_GD_VOXEL="n"
            fi
        fi

    else # if only rebuilding/creating templates, simply rename existing godot folder.
        echo "Welcome to the Cult of the Blue Robot."
        echo "Choose your Godot version (e.g. 4.1.3-stable, 4.1, master) or default - latest stable release."
        read GODOT_VERSION
        if [ "$GODOT_VERSION" == "" ]
        then
            GODOT_VERSION="4.1.3-stable"
        fi
        cd ..
        mv godot-* godot
    fi

    if [ $BUILD_TYPE == "rebuild" ] # just a warning, not a code header
    then
        echo "Below settings should match previous builds (I need to learn how to cache this)."
    fi

    # build options
    echo "What platform are you building for? (LINUXBSD, windows, macos, server, etc.)"
    read PLATFORM
    if [ "$PLATFORM" == "" ]
    then
        PLATFORM="linuxbsd"
    fi
    if [ $PLATFORM == "macos" ] # currently unsupported for cross-compile due to MoltenVK errors.
    then
        echo "NOTE: If osxcross initial setup is struggling, try installing the libbz2-dev package for SDK extraction."
        export OSXCROSS_ROOT="$HOME/osxcross"
    fi
    echo "What architecture are you building on? (X86_64, arm64, rv64, wasm32, etc.)"
    read ARCH
    if [ "$ARCH" == "" ]
    then
        ARCH="x86_64"
    fi
    echo "How many threads would you like to use for building? (default 16)"
    read THREADCOUNT
    if [ "$THREADCOUNT" == "" ]
    then
        THREADCOUNT="16"
    fi
    echo "Build export templates as well? (y/N)"
    read TEMPLATES
    if [ "$TEMPLATES" == "" ]
    then
        TEMPLATES="n"
    fi
    if [ $TEMPLATES == "y" ]
    then
        echo "Choose template type (template_debug/template_release/BOTH)"
        read TEMPLATE_TYPE
        if [ "$TEMPLATE_TYPE" == "" ]
        then
            TEMPLATE_TYPE="both"
        fi
        echo "Do you want PCK encryption support? (y/N)"
        read B_ENCRYPT
         if [ "$B_ENCRYPT" == "" ]
        then
            B_ENCRYPT="n"
        fi
        if [ $B_ENCRYPT == "y" ]
        then
            export SCRIPT_AES256_ENCRYPTION_KEY="8198992e4523238ab8f520d65b7c54b83347c33a6897855547e3639a594d6a91"
        fi
    fi
    echo "Enable .NET (C#) support? (YES/no) NOTE: requires .NET SDK 6/7 to be installed, ~/.dotnet may also need to be in PATH."
    read B_DOTNET
    if [ "$B_DOTNET" == "" ]
    then
        B_DOTNET="yes"
    fi
    echo "Enable dev_mode for warnings as errors and unit testing? (yes/NO) This is useful when doing engine development. NOTE: seems to not play well with some modules."
    read B_DEVMODE
    if [ "$B_DEVMODE" == "" ]
    then
        B_DEVMODE="no"
    fi
    if [ $B_DEVMODE == "no" ]
    then
        B_DEVBUILD="no"
        B_DEBUGSYMBOLS="no"
        echo "Enable production mode for better optimization and portability? (yes/NO) This is useful for exporting final game builds."
        read B_OPTIMIZE
        if [ "$B_OPTIMIZE" == "" ]
        then
            B_OPTIMIZE="no"
        fi
    else
        B_OPTIMIZE="no"
        echo "Enable dev_build mode for disabling optimization and enabling debug symbols? (yes/NO) Also useful for engine development. NOTE: seems to not play well with some modules."
        read B_DEVBUILD
        if [ "$B_DEVBUILD" == "" ]
        then
            B_DEVBUILD="no"
        fi
        if [ $B_DEVBUILD == "yes" ]
        then
            echo "Additionally enable debugging symbols for debugger and profiler support? (yes/no)"
            read B_DEBUGSYMBOLS
            if [ "$B_DEBUGSYMBOLS" == "" ]
            then
                B_DEBUGSYMBOLS="yes"
            fi
        else
            B_DEBUGSYMBOLS="no"
        fi
    fi
    echo "Choose an optimization level. This should align well with previous choices. (SPEED_TRACE/speed/size/debug/none)"
    read OPT_LEVEL
    if [ "$OPT_LEVEL" == "" ]
    then
        OPT_LEVEL="speed_trace"
    fi
    echo "Use single or double precision? (SINGLE/double)"
    read PRECISION_LEVEL
    if [ "$PRECISION_LEVEL" == "" ]
    then
        PRECISION_LEVEL="single"
    fi

    if [ $B_OPTIMIZE == 'no' ]
    then
        echo "Use Clang & LLVM instead of GCC to compile? (yes/NO)"
        read B_CLANG
        if [ "$B_CLANG" == "" ]
        then
            B_CLANG="no"
        fi
        echo "Use the Mold linker for faster compiles? (y/N) This may not work on all systems after setup."
        read B_MOLD
        if [ "$B_MOLD" == "" ]
        then
            B_MOLD="no"
        fi
    else
        B_CLANG="no"
        B_MOLD="no"
    fi
    if [ $PLATFORM == "linuxbsd" ]
    then
        echo "Launch editor upon completion? (Y/n)"
        read B_EDITOR
        if [ "$B_EDITOR" == "" ]
        then
            B_EDITOR="y"
        fi
    else
        B_EDITOR="n"
    fi

    if [ $BUILD_TYPE == "rebuild" ]
    then
        echo "#### Now cleaning up generated files from previous build. ####"
        if [ $B_OPTIMIZE == 'yes' ]
        then
            pyston-scons --clean platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm=no precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
        else
            if [ $B_MOLD == 'y' ]
            then
                pyston-scons --clean platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" linker=mold precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
            else
                if [ $B_CLANG == 'yes' ]
                then
                    pyston-scons --clean platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" linker=lld precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
                else
                    pyston-scons --clean platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm=no precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
                fi
            fi
        fi
    fi

    if [ $BUILD_TYPE == "build" ]
    then
        # clone godot
        echo "#### Cloning Godot and modules. ####"
        git clone https://github.com/godotengine/godot.git -b "$GODOT_VERSION"

        # clone modules, copy each into godot modules folder
        if [ "$B_GD_STEAM" == 'y' ] 
        then
            git clone https://github.com/CoaguCo-Industries/GodotSteam.git -b v4.4.1
            mv GodotSteam/ godotsteam/
            cp -rv godotsteam/ godot/modules/
            # steam SDK
            mkdir godot/modules/godotsteam/sdk
            cp -rv steam_sdk/sdk/public/ godot/modules/godotsteam/sdk/
            cp -rv steam_sdk/sdk/redistributable_bin/ godot/modules/godotsteam/sdk/
        fi

        if [ "$B_LIMBOAI" == 'y' ]
        then
            if [ $B_LIMBOAI_NIGHTLY == 'y' ]
            then
                git clone https://github.com/limbonaut/limboai.git -b master
            else
                git clone https://github.com/limbonaut/limboai.git -b v0.4.2-stable
            fi
            cp -rv limboai/ godot/modules/
        fi

        if [ "$B_GD_VOXEL" == 'y' ]
        then
            git clone https://github.com/Zylann/godot_voxel.git -b master
            mv godot_voxel/ voxel/
            cp -rv voxel/ godot/modules/
        fi
    fi

    cd godot/

    # rename Godot folder appropriately (do this late to avoid errors)
    if [ "$B_GD_STEAM" == 'y' ] || [ "$B_LIMBOAI" == 'y' ] || [ "$B_GD_VOXEL" == 'y' ]
    then
        mv ../godot ../godot-"$GODOT_VERSION"-custom
    else
        mv ../godot ../godot-"$GODOT_VERSION"
    fi

    # doing this step before the later .NET steps below as this folder should be removed first, NOT after, contrary to what the docs imply.
    if [ $B_DOTNET == 'yes' ] && [ $BUILD_TYPE == "build" ]
    then
        # clear godot C# NuGet package cache (see https://github.com/godotengine/godot/issues/44532 and note on Godot docs for compiling .NET)
        sudo rm -r ~/.local/share/godot/mono/GodotNuGetFallbackFolder
    fi

    echo "#### Now building Godot. ####"
    # If optimizing, don't use LLVM and use default linker.
    if [ $B_OPTIMIZE == 'yes' ]
    then
        pyston-scons platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm=no precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
    # Otherwise, determine if mold/lld/ld is used or not.
    else
        if [ $B_MOLD == 'y' ]
        then
            pyston-scons platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" linker=mold precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
        else
            # If not using mold, use lld with clang & LLVM and just use the default (ld) with GCC.
            if [ $B_CLANG == 'yes' ]
            then
                pyston-scons platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" linker=lld precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
            else
                pyston-scons platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm=no precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
            fi
        fi
    fi

    # final godotsteam setup if enabled
    if [ $BUILD_TYPE == 'build' ] && [ $B_GD_STEAM == 'y' ] 
    then
        cp -rv ../steam_sdk/steam_appid.txt bin/

        if [ $PLATFORM == 'linuxbsd' ]
        then
            cp -rv ../steam_sdk/sdk/redistributable_bin/linux64/libsteam_api.so bin/
        fi
    fi

    if [ $B_DOTNET == 'yes' ]
    then
        echo "#### Generating .NET glue. ####"
        mkdir ~/.local/share/godot/mono/GodotNuGetFallbackFolder
        # this nightmare should be rewritten when I suck less at shell scripting
        if [ $B_CLANG == 'yes' ]
        then
            if [ $PRECISION_LEVEL == 'double' ]
            then
                if [ $B_DEVBUILD == 'yes' ]
                then
                    ./bin/godot."$PLATFORM".editor.dev.double."$ARCH".llvm.mono --headless --generate-mono-glue modules/mono/glue
                else
                    ./bin/godot."$PLATFORM".editor.double."$ARCH".llvm.mono --headless --generate-mono-glue modules/mono/glue
                fi
            else
                if [ $B_DEVBUILD == 'yes' ]
                then
                    ./bin/godot."$PLATFORM".editor.dev."$ARCH".llvm.mono --headless --generate-mono-glue modules/mono/glue
                else
                    ./bin/godot."$PLATFORM".editor."$ARCH".llvm.mono --headless --generate-mono-glue modules/mono/glue
                fi
            fi
        else
            if [ $PRECISION_LEVEL == 'double' ]
            then
                if [ $B_DEVBUILD == 'yes' ]
                then
                    ./bin/godot."$PLATFORM".editor.dev.double."$ARCH".mono --headless --generate-mono-glue modules/mono/glue
                else
                    ./bin/godot."$PLATFORM".editor.double."$ARCH".mono --headless --generate-mono-glue modules/mono/glue
                fi
            else
                if [ $B_DEVBUILD == 'yes' ]
                then
                    ./bin/godot."$PLATFORM".editor.dev."$ARCH".mono --headless --generate-mono-glue modules/mono/glue
                else
                    ./bin/godot."$PLATFORM".editor."$ARCH".mono --headless --generate-mono-glue modules/mono/glue
                fi
            fi
        fi

        if [ $PRECISION_LEVEL == 'double' ]
        then
            ./modules/mono/build_scripts/build_assemblies.py --godot-output-dir=./bin --push-nupkgs-local ~/MyLocalNugetSource --godot-platform="$PLATFORM" --precision=double
        else
            ./modules/mono/build_scripts/build_assemblies.py --godot-output-dir=./bin --push-nupkgs-local ~/MyLocalNugetSource --godot-platform="$PLATFORM"
        fi
    fi

    if [ $TEMPLATES == 'y' ]
    then
        echo "#### Now building export template(s). ####"
        if [ $TEMPLATE_TYPE == 'both' ]
        then
            pyston-scons platform="$PLATFORM" arch="$ARCH" target=template_debug dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
            pyston-scons platform="$PLATFORM" arch="$ARCH" target=template_release dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
        else
            pyston-scons platform="$PLATFORM" arch="$ARCH" target="$TEMPLATE_TYPE" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
        fi
    fi

    cd bin/
    echo "#### Build complete! Enjoy your cult membership! ####"

    if [ $B_EDITOR == 'y' ]
    then
        echo "#### Lauching Godot editor. Safe travels! ####"

        # this nightmare can be ignored and should be rewritten when I suck less at shell scripting
        if [ $PRECISION_LEVEL == 'double' ]
        then
            if [ $B_DEVBUILD == 'yes' ]
            then
                if [ $B_CLANG == 'yes' ]
                then
                    if [ $B_DOTNET == 'yes' ]
                    then
                        ./godot."$PLATFORM".editor.dev.double."$ARCH".llvm.mono
                    else
                        ./godot."$PLATFORM".editor.dev.double."$ARCH".llvm
                    fi
                else
                    if [ $B_DOTNET == 'yes' ]
                    then
                        ./godot."$PLATFORM".editor.dev.double."$ARCH".mono
                    else
                        ./godot."$PLATFORM".editor.dev.double."$ARCH"
                    fi
                fi
            else
                if [ $B_CLANG == 'yes' ]
                then
                    if [ $B_DOTNET == 'yes' ]
                    then
                        ./godot."$PLATFORM".editor.double."$ARCH".llvm.mono
                    else
                        ./godot."$PLATFORM".editor.double."$ARCH".llvm
                    fi
                else
                    if [ $B_DOTNET == 'yes' ]
                    then
                        ./godot."$PLATFORM".editor.double."$ARCH".mono
                    else
                        ./godot."$PLATFORM".editor.double."$ARCH"
                    fi
                fi
            fi
        else
            if [ $B_DEVBUILD == 'yes' ]
            then
                if [ $B_CLANG == 'yes' ]
                then
                    if [ $B_DOTNET == 'yes' ]
                    then
                        ./godot."$PLATFORM".editor.dev."$ARCH".llvm.mono
                    else
                        ./godot."$PLATFORM".editor.dev."$ARCH".llvm
                    fi
                else
                    if [ $B_DOTNET == 'yes' ]
                    then
                        ./godot."$PLATFORM".editor.dev."$ARCH".mono
                    else
                        ./godot."$PLATFORM".editor.dev."$ARCH"
                    fi
                fi
            else
                if [ $B_CLANG == 'yes' ]
                then
                    if [ $B_DOTNET == 'yes' ]
                    then
                        ./godot."$PLATFORM".editor."$ARCH".llvm.mono
                    else
                        ./godot."$PLATFORM".editor."$ARCH".llvm
                    fi
                else
                    if [ $B_DOTNET == 'yes' ]
                    then
                        ./godot."$PLATFORM".editor."$ARCH".mono
                    else
                        ./godot."$PLATFORM".editor."$ARCH"
                    fi
                fi
            fi
        fi
    fi
fi
