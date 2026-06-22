#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "wallpaper_picker"

FLAG="$QS_STATE_WALLPAPER_PICKER/wallpaper_initialized"
CACHE_IMG="$QS_CACHE_WALLPAPER_PICKER/current_wallpaper.png"

RELOAD_SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")/quickshell/wallpaper/matugen_reload.sh"

# Determine the original wallpaper path (could be image or video)
ORIG_WALLPAPER="$QS_CACHE_WALLPAPER_PICKER/current_wallpaper.orig"
REAL_WALLPAPER=""
if [ -L "$ORIG_WALLPAPER" ] || [ -f "$ORIG_WALLPAPER" ]; then
    REAL_WALLPAPER=$(readlink -f "$ORIG_WALLPAPER")
fi

if [ -z "$REAL_WALLPAPER" ] || [ ! -f "$REAL_WALLPAPER" ]; then
    REAL_WALLPAPER="$CACHE_IMG"
fi

MIME_TYPE=$(file -b --mime-type "$REAL_WALLPAPER" 2>/dev/null)

# If the flag exists, run awww/mpvpaper, matugen and the reload script, then exit
if [ -f "$FLAG" ]; then
    if [ -f "$REAL_WALLPAPER" ]; then
        if [[ "$MIME_TYPE" == video/* ]]; then
            pkill mpvpaper || true
            mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' '*' "$REAL_WALLPAPER" &
        else
            # Determine real image extension because awww crashes if extension doesn't match mime-type
            REAL_EXT="png"
            if [[ "$MIME_TYPE" == "image/jpeg" ]]; then
                REAL_EXT="jpg"
            fi
            AWWW_LINK="$QS_CACHE_WALLPAPER_PICKER/current_wallpaper_awww.$REAL_EXT"
            ln -sf "$REAL_WALLPAPER" "$AWWW_LINK"
            awww img "$AWWW_LINK" --transition-type any --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
        fi
    fi

    # Use the cached static image for matugen colors
    if [ -f "$CACHE_IMG" ]; then
        CACHE_MIME=$(file -b --mime-type "$CACHE_IMG" 2>/dev/null)
        CACHE_EXT="png"
        if [[ "$CACHE_MIME" == "image/jpeg" ]]; then
            CACHE_EXT="jpg"
        fi
        MATUGEN_LINK="$QS_CACHE_WALLPAPER_PICKER/current_wallpaper_matugen.$CACHE_EXT"
        ln -sf "$CACHE_IMG" "$MATUGEN_LINK"
        matugen image "$MATUGEN_LINK" --source-color-index 0
    fi
    
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        chmod +x "$RELOAD_SCRIPT_PATH"
        bash "$RELOAD_SCRIPT_PATH"
    fi
    
    exit 0
fi

# If no wallpaper dir is set, default to a common one to prevent find from failing
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

sleep 0.5

# Find a random file (images or videos)
file=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) 2>/dev/null | shuf -n 1)

if [ -n "$file" ]; then
    # Create persistent symlink and copy cache
    ln -sf "$file" "$ORIG_WALLPAPER"
    
    # Check mime type of the randomly chosen file
    RAND_MIME=$(file -b --mime-type "$file" 2>/dev/null)
    
    if [[ "$RAND_MIME" == video/* ]]; then
        # For videos, try to generate a thumbnail frame or just copy a default
        # (We will just copy a placeholder/black or let wallpaper picker handle it,
        # but to keep it simple, we touch or link current_wallpaper.png)
        touch "$CACHE_IMG"
        pkill mpvpaper || true
        mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' '*' "$file" &
    else
        cp "$file" "$CACHE_IMG"
        
        REAL_EXT="png"
        if [[ "$RAND_MIME" == "image/jpeg" ]]; then
            REAL_EXT="jpg"
        fi
        AWWW_LINK="$QS_CACHE_WALLPAPER_PICKER/current_wallpaper_awww.$REAL_EXT"
        ln -sf "$CACHE_IMG" "$AWWW_LINK"
        awww img "$AWWW_LINK" --transition-type any --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
        
        # Determine format for matugen
        MATUGEN_LINK="$QS_CACHE_WALLPAPER_PICKER/current_wallpaper_matugen.$REAL_EXT"
        ln -sf "$CACHE_IMG" "$MATUGEN_LINK"
        matugen image "$MATUGEN_LINK" --source-color-index 0
    fi
    
    # Execute reload script if it exists
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        chmod +x "$RELOAD_SCRIPT_PATH"
        bash "$RELOAD_SCRIPT_PATH"
    fi
fi

mkdir -p "$(dirname "$FLAG")"
touch "$FLAG"
