#!/usr/bin/env python3
import os
import glob
import json
import subprocess
import time

_CACHE_DIR = os.path.expanduser('~/.cache/quickshell')
_CACHE_FILE = os.path.join(_CACHE_DIR, 'icon_cache.json')
_CACHE_MAX_AGE = 3600  # seconds


def _get_icon_theme():
    """Get the current icon theme name via gsettings."""
    try:
        result = subprocess.run(
            ['gsettings', 'get', 'org.gnome.desktop.interface', 'icon-theme'],
            capture_output=True, text=True, timeout=3
        )
        return result.stdout.strip().strip("'")
    except Exception:
        return 'hicolor'


def _load_disk_cache():
    """Load icon cache from disk if it exists and is fresh."""
    try:
        if not os.path.exists(_CACHE_FILE):
            return None
        age = time.time() - os.path.getmtime(_CACHE_FILE)
        if age > _CACHE_MAX_AGE:
            return None
        with open(_CACHE_FILE, 'r') as f:
            return json.load(f)
    except Exception:
        return None


def _save_disk_cache(cache):
    """Persist icon cache to disk."""
    try:
        os.makedirs(_CACHE_DIR, exist_ok=True)
        with open(_CACHE_FILE, 'w') as f:
            json.dump(cache, f)
    except Exception:
        pass


def _build_icon_index(theme):
    """Walk icon directories once and build a name→path index.
    
    Priority: theme SVG > theme PNG > hicolor SVG > hicolor PNG > pixmaps.
    Larger sizes preferred within each category.
    """
    home = os.path.expanduser('~')
    
    # Directories in priority order (first match wins per priority tier)
    search_dirs = []
    for base in ['/usr/share/icons', f'{home}/.local/share/icons']:
        if theme and theme != 'hicolor':
            search_dirs.append(('theme', os.path.join(base, theme)))
        search_dirs.append(('hicolor', os.path.join(base, 'hicolor')))
    search_dirs.append(('pixmaps', '/usr/share/pixmaps'))

    # Size priority scores (higher = better)
    size_scores = {
        'scalable': 100, '512x512': 90, '256x256': 80, '128x128': 70,
        '96x96': 60, '64x64': 55, '48x48': 50, '32x32': 40,
        '24x24': 30, '22x22': 25, '16x16': 20,
    }
    ext_scores = {'svg': 3, 'png': 2, 'xpm': 1}
    valid_exts = {'.svg', '.png', '.xpm'}

    # name → (priority_score, path)
    best = {}

    for tier_idx, (tier, base_dir) in enumerate(search_dirs):
        if not os.path.isdir(base_dir):
            continue
        tier_bonus = (len(search_dirs) - tier_idx) * 1000  # theme > hicolor > pixmaps

        if tier == 'pixmaps':
            # Flat directory — just list files
            try:
                for entry in os.scandir(base_dir):
                    if not entry.is_file():
                        continue
                    name_part, ext = os.path.splitext(entry.name)
                    if ext not in valid_exts:
                        continue
                    score = tier_bonus + ext_scores.get(ext[1:], 0)
                    if name_part not in best or score > best[name_part][0]:
                        best[name_part] = (score, entry.path)
            except OSError:
                pass
        else:
            # Walk standard icon theme structure
            try:
                for dirpath, _, filenames in os.walk(base_dir):
                    # Extract size from path component
                    parts = dirpath.split(os.sep)
                    size_name = ''
                    for p in parts:
                        if p in size_scores:
                            size_name = p
                            break
                    s_score = size_scores.get(size_name, 10)

                    for fname in filenames:
                        name_part, ext = os.path.splitext(fname)
                        if ext not in valid_exts:
                            continue
                        score = tier_bonus + s_score * 10 + ext_scores.get(ext[1:], 0)
                        if name_part not in best or score > best[name_part][0]:
                            best[name_part] = (score, os.path.join(dirpath, fname))
            except OSError:
                pass

    return {name: path for name, (_, path) in best.items()}


def _get_icon_resolver(theme):
    """Return a cached name→path dict, loading from disk or building fresh."""
    cache = _load_disk_cache()
    if cache and cache.get('_theme') == theme:
        return cache

    index = _build_icon_index(theme)
    index['_theme'] = theme
    _save_disk_cache(index)
    return index


def _resolve_icon(name, resolver):
    """Resolve an icon name to a full path using the pre-built index."""
    if not name:
        return name
    if name.startswith('/'):
        return name
    return resolver.get(name, name)


def fetch_apps():
    apps = {}
    home = os.path.expanduser('~')
    
    # Expanded directories to catch Flatpaks, system apps, and Nix packages
    dirs = [
        '/usr/share/applications',
        '/usr/local/share/applications',
        f'{home}/.local/share/applications',
        '/var/lib/flatpak/exports/share/applications',
        f'{home}/.local/share/flatpak/exports/share/applications',
        f'{home}/.nix-profile/share/applications',
        '/run/current-system/sw/share/applications'
    ]

    theme = _get_icon_theme()
    resolver = _get_icon_resolver(theme)
    
    for d in dirs:
        if not os.path.exists(d):
            continue
            
        for f in glob.glob(os.path.join(d, '**/*.desktop'), recursive=True):
            try:
                with open(f, 'r', encoding='utf-8') as file:
                    app = {'name': '', 'exec': '', 'icon': ''}
                    is_desktop = False
                    no_display = False
                    
                    for line in file:
                        line = line.strip()
                        if line == '[Desktop Entry]':
                            is_desktop = True
                        elif line.startswith('['):
                            is_desktop = False
                            
                        if is_desktop:
                            if line.startswith('Name=') and not app['name']:
                                app['name'] = line[5:]
                            elif line.startswith('Exec=') and not app['exec']:
                                # Strip %u, %f, and @@ placeholders
                                app['exec'] = line[5:].split(' %')[0].split(' @@')[0]
                            elif line.startswith('Icon=') and not app['icon']:
                                app['icon'] = line[5:]
                            elif line.startswith('NoDisplay=true') or line.startswith('NoDisplay=1'):
                                no_display = True
                                
                    if app['name'] and app['exec'] and not no_display:
                        # Resolve icon to full path for reliable rendering
                        app['icon'] = _resolve_icon(app['icon'], resolver)
                        apps[app['name']] = app
            except Exception:
                pass
                
    # Sort alphabetically and return as JSON
    res = list(apps.values())
    res.sort(key=lambda x: x['name'].lower())
    print(json.dumps(res))

if __name__ == "__main__":
    fetch_apps()
