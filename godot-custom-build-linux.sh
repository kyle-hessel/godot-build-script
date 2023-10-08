#!/usr/bin/env bash
# TODO: optimize old file deletion, optimization levels, debugging symbols, export cross-compilation, PCK encryption, more testing in different target modes, double-precision support (scons precision=double - and for .NET! check docs) etc.

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
    echo "What platform are you building for? (linuxbsd, windows, server, etc.)"
    read PLATFORM
    echo "What architecture are you building on? (x86_64, arm64, rv64, wasm32, etc.)"
    read ARCH
    echo "Are you using custom modules?"
    read CUSTOM
    echo "How many threads would you like to use for building?"
    read THREADCOUNT
    echo "Choose template type (template_debug/template_release/BOTH)"
    read TEMPLATE_TYPE
    echo "Enable .NET (C#) support? (yes/no) NOTE: requires .NET SDK 6/7 to be installed, ~/.dotnet may also need to be in PATH."
    read B_DOTNET
    echo "Enable dev_mode for warnings as errors and unit testing? (y/n) This is useful when doing engine development. NOTE: seems to not play well with some modules."
    read B_DEVMODE
    if [ $B_DEVMODE == "n" ]
    then
        B_DEVBUILD="no"
        echo "Enable production mode for better optimization and portability? (yes/no) This is useful for exporting final game builds."
        read B_OPTIMIZE
    else
        B_OPTIMIZE="n"
        echo "Enable dev_build mode for disabling optimization and enabling debug symbols? (yes/no) Also useful for engine development. NOTE: seems to not play well with some modules."
        read B_DEVBUILD
    fi
    echo "Use Clang instead of GCC to compile? (yes/no)"
    read B_CLANG

    cd godot/

    # rename Godot folder appropriately (do this late to avoid errors)
    if [ $CUSTOM == 'y' ]
    then
        mv ../godot ../godot-"$GODOT_VERSION"-CUSTOM
    else
        mv ../godot ../godot-"$GODOT_VERSION"
    fi

    echo "#### Now building native export template(s). ####"
    if [ $TEMPLATE_TYPE == 'BOTH' ]
    then
        scons platform="$PLATFORM" arch="$ARCH" target=template_debug dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" production="$B_OPTIMIZE" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" -j"$THREADCOUNT"
        scons platform="$PLATFORM" arch="$ARCH" target=template_release dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" production="$B_OPTIMIZE" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" -j"$THREADCOUNT"
    else
        scons platform="$PLATFORM" arch="$ARCH" target="$TEMPLATE_TYPE" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" production="$B_OPTIMIZE" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" -j"$THREADCOUNT"
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
    echo "What platform are you building for? (linuxbsd, windows, server, etc.)"
    read PLATFORM
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
    fi
    echo "Enable .NET (C#) support? (yes/no) NOTE: requires .NET SDK 6/7 to be installed, ~/.dotnet may also need to be in PATH."
    read B_DOTNET
    echo "Enable dev_mode for warnings as errors and unit testing? (yes/no)"
    read B_DEVMODE
    if [ $B_DEVMODE == "no" ]
    then
        B_DEVBUILD="no"
        echo "Enable production mode for better optimization and portability? (yes/no)"
        read B_OPTIMIZE
    else
        B_OPTIMIZE="no"
        echo "Enable dev_build mode for disabling optimization and enabling extra debug symbols? (yes/no) NOTE: seems to not play well with some modules."
        read B_DEVBUILD
    fi
    echo "Use Clang instead of GCC to compile? (yes/no)"
    read B_CLANG
    echo "Launch editor upon completion? (y/n)"
    read B_EDITOR

    if [ $BUILD_TYPE == "rebuild" ]
    then
        echo "#### Now cleaning up generated files from previous build. ####"
        scons --clean platform="$PLATFORM" arch="$ARCH" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" production="$B_OPTIMIZE" target=editor module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" -j"$THREADCOUNT"
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

    scons platform="$PLATFORM" arch="$ARCH" target=editor dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" production="$B_OPTIMIZE" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" -j"$THREADCOUNT"

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
        if [ $B_DEVBUILD == 'yes' ]
        then
            ./bin/godot."$PLATFORM".editor.dev."$ARCH".mono --headless --generate-mono-glue modules/mono/glue
        else
            ./bin/godot."$PLATFORM".editor."$ARCH".mono --headless --generate-mono-glue modules/mono/glue
        fi
        ./modules/mono/build_scripts/build_assemblies.py --godot-output-dir=./bin --push-nupkgs-local ~/MyLocalNugetSource
    fi

    if [ $TEMPLATES == 'y' ]
    then
        echo "#### Now building native export template(s). ####"
        if [ $TEMPLATE_TYPE == 'BOTH' ]
        then
            scons platform="$PLATFORM" arch="$ARCH" target=template_debug dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" production="$B_OPTIMIZE" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" -j"$THREADCOUNT"
            scons platform="$PLATFORM" arch="$ARCH" target=template_release dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" production="$B_OPTIMIZE" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" -j"$THREADCOUNT"
        else
            scons platform="$PLATFORM" arch="$ARCH" target="$TEMPLATE_TYPE" dev_mode="$B_DEVMODE" dev_build="$B_DEVBUILD" production="$B_OPTIMIZE" module_mono_enabled="$B_DOTNET" use_llvm="$B_CLANG" -j"$THREADCOUNT"
        fi
    fi

    cd bin/
    echo "#### Build complete! Enjoy your cult membership! ####"

    if [ $B_EDITOR == 'y' ]
    then
        echo "#### Lauching Godot editor. Safe travels! ####"

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