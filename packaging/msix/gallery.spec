# -*- mode: python ; coding: utf-8 -*-

from pathlib import Path

import PySide6


ROOT = Path(SPECPATH).resolve().parent
PYSIDE6_DIR = Path(PySide6.__file__).resolve().parent


def _is_external_system_binary(entry):
    name = Path(entry[0]).name.lower()
    if name == "ucrtbase.dll" or name.startswith("api-ms-win-"):
        return True
    if name.startswith("icu") and name.endswith(".dll"):
        # PySide6 6.10 uses the ICU shipped by Windows. Do not pick up
        # unrelated ICU builds from the build machine's PATH.
        return not (PYSIDE6_DIR / Path(entry[0]).name).exists()
    return False


a = Analysis(
    [str(ROOT / "examples" / "gallery.py")],
    pathex=[str(ROOT)],
    binaries=[],
    datas=[
        (str(ROOT / "RinUI"), "RinUI"),
        (str(ROOT / "examples" / "assets"), "assets"),
        (str(ROOT / "examples" / "components"), "components"),
        (str(ROOT / "examples" / "languages"), "languages"),
        (str(ROOT / "examples" / "pages"), "pages"),
        (str(ROOT / "examples" / "gallery.qml"), "."),
    ],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)

a.binaries = [
    entry for entry in a.binaries if not _is_external_system_binary(entry)
]

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="gallery",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=[str(ROOT / "examples" / "assets" / "gallery.ico")],
    contents_directory=".",
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="gallery",
)
