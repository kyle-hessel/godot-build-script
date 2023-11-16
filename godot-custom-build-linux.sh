#!/usr/bin/env bash
# Godot Custom Linux Build Script 1.0
# Created by Polluted Mind
# TODO: optimize old file deletion, option to not include modules without further prompts, option for git pull on rebuild, more testing in different target modes

echo "Welcome to the Cult of the Blue Robot."

# go to the correct folder (back one), remove old folders
echo "Begin a new engine build, rebuild an existing one in this folder, or build templates? (build/rebuild/templates)"
read BUILD_TYPE

#######################
### TEMPLATES ONLY ####
#######################

# templates are an entire branch of their own as they do not require git clones or module compilation as everything should already be there.
if [ $BUILD_TYPE == "TEMPLATES" ]
then
    cd ..
    mv godot-* godot

    # build options
    echo "Below settings should match existing build (I need to learn how to cache this)."
    echo "Choose your Godot version (e.g. 4.1.2-stable, 4.1, master)"
    read GODOT_VERSION
    echo "What platform are you building for? (linuxbsd, windows, macos, server, etc.)"
    read PLATFORM
    if [ $PLATFORM == "macos" ] # currently unsupported for cross-compile due to MoltenVK errors.
    then
        echo "NOTE: If osxcross initial setup is struggling, try installing the libbz2-dev package for SDK extraction."
        export OSXCROSS_ROOT="$HOME/osxcross"
    fi
    echo "What architecture are you building on? (x86_64, arm64, rv64, wasm32, etc.)"
    read ARCH
    echo "Are you using custom modules?"
    read CUSTOM
    echo "How many threads would you like to use for building?"
    read THREADCOUNT
    echo "Do you want PCK encryption support? (y/n)"
    read B_ENCRYPT
    if [ $B_ENCRYPT == "y" ]
    then
        export SCRIPT_AES256_ENCRYPTION_KEY="8198992e4523238ab8f520d65b7c54b83347c33a6897855547e3639a594d6a91"
    fi
    echo "Choose template type (template_debug/template_release/BOTH)"
    read TEMPLATE_TYPE
    echo "Enable .NET (C#) support? (yes/no) NOTE: requires .NET SDK 6/7 to be installed, ~/.dotnet may also need to be in PATH."
    read B_DOTNET
    echo "Enable dev_mode for warnings as errors and unit testing? (yes/no) This is useful when doing engine development. NOTE: seems to not play well with some modules."
    read B_DEVMODE
    if [ $B_DEVMODE == "no" ]
    then
        B_DEVBUILD="no"
        B_DEBUGSYMBOLS="no"
        echo "Enable production mode for better optimization and portability? (yes/no) This is useful for exporting final game builds."
        read B_OPTIMIZE
    else
        B_OPTIMIZE="no"
        echo "Enable dev_build mode for disabling optimization and enabling debug symbols? (yes/no) Also useful for engine development. NOTE: seems to not play well with some modules."
        read B_DEVBUILD
        if [ $B_DEVBUILD == "yes" ]
        then
            echo "Additionally enable debugging symbols for debugger and profiler support? (yes/no)"
            read B_DEBUGSYMBOLS
        else
            B_DEBUGSYMBOLS="no"
        fi
    fi
    echo "Choose an optimization level. This should align well with previous choices. (speed_trace/speed/size/debug/none)"
    read OPT_LEVEL
    echo "Use single or double precision? (single/double)"
    read PRECISION_LEVEL
    if [ $B_OPTIMIZE == 'no' ]
    then
        echo "Use Clang & LLVM instead of GCC to compile? (yes/no)"
        read B_CLANG
        echo "Use the Mold linker for faster compiles? (yes/no) This may not work on all systems after setup."
        read B_MOLD
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
    if [ $TEMPLATE_TYPE == 'BOTH' ]
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

        echo "Choose your Godot version (e.g. 4.1-stable, 4.1, master)"
        read GODOT_VERSION

        # community engine modules
        echo "Do you want Godot Steam? (y/n) NOTE: requires Steamworks SDK to be unzipped in an adjacent folder called steam_sdk, and put your steam_appid.txt in there, too!"
        echo "Double NOTE: Don't cross-compile on Linux for Windows using MinGW with this module; compile natively on Windows using MSVC instead. See GodotSteam Github note."
        read B_GD_STEAM

        echo "Do you want LimboAI? (y/n)"
        read B_LIMBOAI
        if [ $B_LIMBOAI == 'y' ]
        then
            echo "Do you want the latest limboai nightly build? (y/n)"
            read B_LIMBOAI_NIGHTLY
        fi

        echo "Do you want Godot Voxel? (y/n)"
        read B_GD_VOXEL
    else # if only rebuilding/creating templates, simply rename existing godot folder.
        echo "Welcome to the Cult of the Blue Robot."
        echo "Choose your Godot version (e.g. 4.1.2-stable, 4.1, master)"
        read GODOT_VERSION
        cd ..
        mv godot-* godot
    fi

    if [ $BUILD_TYPE == "rebuild" ]
    then
        echo "Below settings should match previous builds (I need to learn how to cache this)."
    fi

    # build options
    echo "What platform are you building for? (linuxbsd, windows, macos, server, etc.)"
    read PLATFORM
    if [ $PLATFORM == "macos" ] # currently unsupported for cross-compile due to MoltenVK errors.
    then
        echo "NOTE: If osxcross initial setup is struggling, try installing the libbz2-dev package for SDK extraction."
        export OSXCROSS_ROOT="$HOME/osxcross"
    fi
    echo "What architecture are you building on? (x86_64, arm64, rv64, wasm32, etc.)"
    read ARCH
    echo "How many threads would you like to use for building?"
    read THREADCOUNT
    echo "Build export templates as well? (y/n)"
    read TEMPLATES
    if [ $TEMPLATES == "y" ]
    then
        echo "Choose template type (template_debug/template_release/BOTH)"
        read TEMPLATE_TYPE
        echo "Do you want PCK encryption support? (y/n)"
        read B_ENCRYPT
        if [ $B_ENCRYPT == "y" ]
        then
            export SCRIPT_AES256_ENCRYPTION_KEY="8198992e4523238ab8f520d65b7c54b83347c33a6897855547e3639a594d6a91"
        fi
    fi
    echo "Enable .NET (C#) support? (yes/no) NOTE: requires .NET SDK 6/7 to be installed, ~/.dotnet may also need to be in PATH."
    read B_DOTNET
    echo "Enable dev_mode for warnings as errors and unit testing? (yes/no) This is useful when doing engine development. NOTE: seems to not play well with some modules."
    read B_DEVMODE
    if [ $B_DEVMODE == "no" ]
    then
        B_DEVBUILD="no"
        B_DEBUGSYMBOLS="no"
        echo "Enable production mode for better optimization and portability? (yes/no) This is useful for exporting final game builds."
        read B_OPTIMIZE
    else
        B_OPTIMIZE="no"
        echo "Enable dev_build mode for disabling optimization and enabling debug symbols? (yes/no) Also useful for engine development. NOTE: seems to not play well with some modules."
        read B_DEVBUILD
        if [ $B_DEVBUILD == "yes" ]
        then
            echo "Additionally enable debugging symbols for debugger and profiler support? (yes/no)"
            read B_DEBUGSYMBOLS
        else
            B_DEBUGSYMBOLS="no"
        fi
    fi
    echo "Choose an optimization level. This should align well with previous choices. (speed_trace/speed/size/debug/none)"
    read OPT_LEVEL
    echo "Use single or double precision? (single/double)"
    read PRECISION_LEVEL
    if [ $B_OPTIMIZE == 'no' ]
    then
        echo "Use Clang & LLVM instead of GCC to compile? (yes/no)"
        read B_CLANG
        echo "Use the Mold linker for faster compiles? (y/n) This may not work on all systems after setup."
        read B_MOLD
    else
        B_CLANG="no"
        B_MOLD="no"
    fi
    if [ $PLATFORM == "linuxbsd" ]
    then
        echo "Launch editor upon completion? (y/n)"
        read B_EDITOR
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
        if [ $B_GD_STEAM == 'y' ] 
        then
            git clone https://github.com/CoaguCo-Industries/GodotSteam.git -b v4.4.1
            mv GodotSteam/ godotsteam/
            cp -rv godotsteam/ godot/modules/
            # steam SDK
            mkdir godot/modules/godotsteam/sdk
            cp -rv steam_sdk/sdk/public/ godot/modules/godotsteam/sdk/
            cp -rv steam_sdk/sdk/redistributable_bin/ godot/modules/godotsteam/sdk/
        fi

        if [ $B_LIMBOAI == 'y' ]
        then
            if [ $B_LIMBOAI_NIGHTLY == 'y' ]
            then
                git clone https://github.com/limbonaut/limboai.git -b master
            else
                git clone https://github.com/limbonaut/limboai.git -b v0.4.2-stable
            fi
            cp -rv limboai/ godot/modules/
        fi

        if [ $B_GD_VOXEL == 'y' ]
        then
            git clone https://github.com/Zylann/godot_voxel.git -b master
            mv godot_voxel/ voxel/
            cp -rv voxel/ godot/modules/
        fi
    fi

    cd godot/

    # rename Godot folder appropriately (do this late to avoid errors)
    if [ $B_GD_STEAM == 'y' ] || [ $B_LIMBOAI == 'y' ] || [ $B_GD_VOXEL == 'y' ]
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
        pyston-scons --clean platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm=no precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
    # Otherwise, determine if mold/lld/ld is used or not.
    else
        if [ $B_MOLD == 'y' ]
        then
            pyston-scons --clean platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" linker=mold precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
        else
            # If not using mold, use lld with clang & LLVM and just use the default (ld) with GCC.
            if [ $B_CLANG == 'yes' ]
            then
                pyston-scons --clean platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" linker=lld precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
            else
                pyston-scons --clean platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" debug_symbols="$B_DEBUGSYMBOLS" production="$B_OPTIMIZE" optimize="$OPT_LEVEL" target=editor module_mono_enabled="$B_DOTNET" use_llvm=no precision="$PRECISION_LEVEL" -j"$THREADCOUNT"
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
        if [ $TEMPLATE_TYPE == 'BOTH' ]
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