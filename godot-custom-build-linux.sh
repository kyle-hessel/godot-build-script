#!/usr/bin/env bash
# TODO: .NET integration, export templates, PCK encryption, different architecture support, more testing in different target modes, etc.

# go to the correct folder (back one), remove old folders
echo "Begin a new engine build or rebuild an existing one in this folder? (build/rebuild)"
read build_type

if [ $build_type == "build" ]
then # if building, pick engine version and modules.
    cd ..
    echo "Deleting any old builds from this folder."
    sudo rm -r godot-* godotsteam limboai voxel

    echo "Welcome to the Cult of the Blue Robot."
    echo "Choose your Godot version (e.g. 4.1-stable, 4.1, master)"

    read godot_version

    # community engine modules
    echo "Do you want Godot Steam? (y/n) NOTE: requires Steamworks SDK to be unzipped in an adjacent folder called steam_sdk, and put your steam_appid.txt in there, too!"
    read b_gd_steam

    echo "Do you want LimboAI? (y/n)"
    read b_limboai
    if [ $b_limboai == 'y' ]
    then
        echo "Do you want the latest limboai nightly build? (y/n)"
        read b_limboai_nightly
    fi

    echo "Do you want Godot Voxel? (y/n)"
    read b_gd_voxel
else # if only rebuilding, simply rename existing godot folder.
    echo "Welcome to the Cult of the Blue Robot."
    echo "Choose your Godot version (e.g. 4.1-stable, 4.1, master)"
    read godot_version
    mv godot-* godot
fi

# build options
echo "What platform are you building for? (linuxbsd, windows, server, etc.)"
read platform
echo "How many threads would you like to use for building?"
read threadcount
echo "What's the target? (editor/template_debug/template_release)"
read target
echo "Use Clang instead of GCC to compile? (yes/no)"
read b_clang
echo "Launch editor upon completion? (y/n)"
read b_editor

if [ $build_type == "build" ]
then
    # clone godot
    echo "Cloning Godot and modules."
    git clone https://github.com/godotengine/godot.git -b "$godot_version"

    # clone modules, copy each into godot modules folder
    if [ $b_gd_steam == 'y' ] 
    then
        git clone https://github.com/CoaguCo-Industries/GodotSteam.git -b v4.4
        mv GodotSteam/ godotsteam/
        cp -rv godotsteam/ godot/modules/
        # steam SDK
        mkdir godot/modules/godotsteam/sdk
        cp -rv steam_sdk/sdk/public/ godot/modules/godotsteam/sdk/
        cp -rv steam_sdk/sdk/redistributable_bin/ godot/modules/godotsteam/sdk/
    fi

    if [ $b_limboai == 'y' ]
    then
        if [ $b_limboai_nightly == 'y' ]
        then
            git clone https://github.com/limbonaut/limboai.git -b master
        else
            git clone https://github.com/limbonaut/limboai.git -b v0.4.2-stable
        fi
        cp -rv limboai/ godot/modules/
    fi

    if [ $b_gd_voxel == 'y' ]
    then
        git clone https://github.com/Zylann/godot_voxel.git -b master
        mv godot_voxel/ voxel/
        cp -rv voxel/ godot/modules/
    fi
fi

cd godot/

if [ $build_type == "build" ]
then
    # rename Godot folder appropriately (do this late to avoid errors)
    if [ $b_gd_steam == 'y' ] || [ $b_limboai == 'y' ] || [ $b_gd_voxel == 'y' ]
    then
        mv ../godot ../godot-"$godot_version"-custom
    else
        mv ../godot ../godot-"$godot_version"
    fi
fi

echo "Now building Godot."

scons platform="$platform" target="$target" use_llvm="$b_clang" -j"$threadcount"

# final godotsteam setup if enabled
if [ $build_type == 'build' ] && [ $b_gd_steam == 'y' ] 
then
    cp -rv ../steam_sdk/steam_appid.txt bin/

    if [ $platform == 'linuxbsd' ]
    then
        cp -rv ../steam_sdk/sdk/redistributable_bin/linux64/libsteam_api.so bin/
    fi
fi

echo "Build complete! Enjoy your cult membership!"

if [ $b_editor == 'y' ]
then
    echo "Lauching Godot editor. Safe travels!"
    cd bin/
    ./godot."$platform".editor.x86_64
fi