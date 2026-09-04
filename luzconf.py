import shutil
from pathlib import Path

from luz import Control, Meta, Module

meta = Meta(
    debug=False,
    sdk="iPhoneOS14.5.sdk",
    rootless=True,
    archs=[
        # "armv7",
        # "armv7s",
        "arm64",
        "arm64e",
    ],
    min_vers="10.0",
)

if meta.rootless:
    meta.min_vers = "15.0"

# My repo
additional_fields: dict = {
    "maintainer": "Dhinak G <dhinak@dhinak.net>",
}
# BigBoss
# additional_fields: dict = {
#     "maintainer": "BigBoss <bigboss@thebigboss.org>",
#     "homepage": "http://moreinfo.thebigboss.org/moreinfo/depiction.php?file=preferenceloader2Data",
#     "depiction": "http://moreinfo.thebigboss.org/moreinfo/depiction.php?file=preferenceloader2Data",
#     "tag": ["role::hacker", "purpose::library"],
#     "dev": "dhinakg",
# }
# Procursus
# additional_fields: dict = {
#     "maintainer": "ProcursusTeam <support@procurs.us>",
# }

# Define control metadata here
control = Control(
    name="PreferenceLoader",
    id="preferenceloader",
    version="2.2.7",
    author="Dhinak G <dhinak@dhinak.net>",
    description="load preferences in style",
    depends=["mobilesubstrate"],
    section="System",
    architecture="iphoneos-arm64" if meta.rootless else "iphoneos-arm",
    **additional_fields,
)

install_dir = meta.root_dir.relative_to(meta.staging_dir)
if install_dir == Path("."):
    install_dir = ""
else:
    install_dir = str(install_dir)

install_prefix = f'-DINSTALL_PREFIX=\\"{install_dir}\\"'
global_c_flags = [install_prefix, f"-DROOTLESS={int(meta.rootless)}"]
if meta.debug:
    global_c_flags.append("-DDEBUG=1")

def copy_libprefs_headers():
    libprefs_path = meta.root_dir / "usr/include/libprefs"
    libprefs_path.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(Path("prefs.h"), libprefs_path / "prefs.h")


def create_preference_folders():
    (meta.root_dir / "Library/PreferenceLoader/Preferences").mkdir(parents=True, exist_ok=True)
    (meta.root_dir / "Library/PreferenceBundles").mkdir(parents=True, exist_ok=True)


libprefs_compatibility_version = "2.2.0"
libprefs_current_version = control.version.partition("-")[0]


# Module info
modules = [
    Module(
        ["prefs.xm"],
        "libprefs",
        "library",
        linker_flags=[
            "-compatibility_version",
            libprefs_compatibility_version,
            "-current_version",
            libprefs_current_version.partition("~")[0].partition("-")[0],
        ],
        use_arc=False,
        frameworks=["UIKit"],
        private_frameworks=["Preferences"],
        libraries=["substrate"],
        after_stage=copy_libprefs_headers,
        c_flags=global_c_flags,
    ),
    Module(
        ["Tweak.xm"],
        "PreferenceLoader",
        "tweak",
        filter={"bundles": ["com.apple.Preferences"]},
        use_arc=False,
        frameworks=["UIKit"],
        private_frameworks=["Preferences"],
        libraries=["prefs"],
        after_stage=create_preference_folders,
        c_flags=global_c_flags,
    ),
]
