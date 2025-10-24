import json
import platform
import sys
from enum import Enum
from pathlib import Path


def is_win11():
    return bool(
        is_windows()
        and (
            platform.release() >= "10"
            and int(platform.version().split(".")[2]) >= 22000
        )
    )


def is_win10():
    return bool(
        is_windows()
        and (
            platform.release() >= "10"
            and int(platform.version().split(".")[2]) >= 10240
        )
    )


def is_windows():
    return platform.system() == "Windows"


def resource_path(relative_path):
    """兼容 PyInstaller 打包和开发环境的路径"""
    if hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS) / relative_path
    return Path(relative_path).resolve()


rinui_core_path = Path(__file__).resolve().parent  # RinUI/core 目录

BASE_DIR = Path.cwd().resolve()
PATH = BASE_DIR / "RinUI" / "config"
RINUI_PATH = resource_path(
    rinui_core_path.parent.parent
)  # 使用 resource_path 处理路径，等同 ../../

DEFAULT_CONFIG = {
    "theme": {
        "current_theme": "Auto",
    },
    "win10_feat": {
        "backdrop_light": 0xA6FFFFFF,
        "backdrop_dark": 0xA6000000,
    },
    "theme_color": "#605ed2",
    "backdrop_effect": "mica" if is_win11() else "acrylic" if is_win10() else "none",
}


class Theme(Enum):
    Auto = "Auto"
    Dark = "Dark"
    Light = "Light"


class BackdropEffect(Enum):
    None_ = "none"
    Acrylic = "acrylic"
    Mica = "mica"
    Tabbed = "tabbed"


class ConfigManager:
    def __init__(self, path, filename):
        """
        Json Config Manager
        :param path: json config file path
        :param filename: json config file name (eg: rin_ui.json)
        """
        self.path = Path(path)
        self.filename = filename
        self.config = {}
        self.full_path = self.path / self.filename

    def load_config(self, default_config):
        if default_config is None:
            print('Warning: "default_config" is None, use empty config instead.')
            default_config = {}
        # 如果文件存在，加载配置
        if self.full_path.exists():
            with self.full_path.open(encoding="utf-8") as f:
                self.config = json.load(f)
        else:
            self.config = default_config  # 如果文件不存在，使用默认配置
            self.save_config()

    def update_config(self):  # 更新配置
        try:
            with self.full_path.open(encoding="utf-8") as f:
                self.config = json.load(f)
        except Exception as e:
            print(f"Error: {e}")
            self.config = {}

    def upload_config(self, key=str or list, value=None):
        if type(key) is str:
            self.config[key] = value
        elif type(key) is list:
            for k in key:
                self.config[k] = value
        else:
            msg = "Key must be str or list"
            raise TypeError(msg) from None
        self.save_config()

    def save_config(self):
        try:
            # 确保配置文件目录存在
            if not self.path.exists():
                self.path.mkdir(parents=True)
            with self.full_path.open("w", encoding="utf-8") as f:
                json.dump(self.config, f, ensure_ascii=False, indent=4)
        except Exception as e:
            print(f"Error: {e}")

    def __getitem__(self, key):
        return self.config.get(key)

    def __setitem__(self, key, value):
        self.config[key] = value
        self.save_config()

    def __repr__(self):
        return json.dumps(self.config, ensure_ascii=False, indent=4)


RinConfig = ConfigManager(path=PATH, filename="rin_ui.json")
RinConfig.load_config(DEFAULT_CONFIG)  # 加载配置
