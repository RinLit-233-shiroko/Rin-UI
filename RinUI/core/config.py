import json
import platform
import sys
from enum import Enum
from pathlib import Path

from PySide6.QtCore import QStandardPaths

from .logger import logger


def is_win11():
    return bool(
        is_windows()
        and (
            platform.release() >= "10"
            and int(platform.version().split(".")[2]) >= 22000
        )
    )


def is_win11_22h2():
    """Win11 22H2 (Build 22621) 及以上——支持 DWMWA_SYSTEMBACKDROP_TYPE 现代 API"""
    return bool(
        is_windows()
        and (
            platform.release() >= "10"
            and int(platform.version().split(".")[2]) >= 22621
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

RINUI_PATH = resource_path(
    rinui_core_path.parent.parent
)  # 使用 resource_path 处理路径，等同 ../../

# 用户可写数据目录（配置/缓存等），延迟到 init_config() 通过 QStandardPaths 解析，
# 兼容 WindowsAppx，不再写入程序根目录 (cwd)
PATH: Path = None

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
    def __init__(self, path=None, filename="rin_ui.json"):
        """
        Json Config Manager
        :param path: json config file path，可为 None（延迟到 init_config() 设置）
        :param filename: json config file name (eg: rin_ui.json)
        """
        self.path = Path(path) if path is not None else None
        self.filename = filename
        self.config = {}
        self.full_path = self.path / self.filename if self.path is not None else None

    def load_config(self, default_config):
        if default_config is None:
            logger.warning('"default_config" is None; using an empty config.')
            default_config = {}
        if self.full_path is None:
            logger.warning("Config path is not initialized; using defaults.")
            self.config = default_config
            return
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
            logger.exception("Failed to update config: %s", e)
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
            logger.exception("Failed to save config: %s", e)

    def __getitem__(self, key):
        return self.config.get(key)

    def __setitem__(self, key, value):
        self.config[key] = value
        self.save_config()

    def __repr__(self):
        return json.dumps(self.config, ensure_ascii=False, indent=4)


RinConfig = ConfigManager()  # 路径延迟到 init_config() 设置，避免在 cwd 落盘
_config_initialized = False


def _resolve_config_dir() -> Path:
    """
    解析配置目录：优先使用 QStandardPaths.AppLocalDataLocation，
    不可用时回退到用户主目录下的 .RinUI，绝不写入程序根目录 (cwd)。
    """
    base = QStandardPaths.writableLocation(QStandardPaths.AppLocalDataLocation)
    if not base:
        base = str(Path.home() / ".RinUI")
    return Path(base) / "RinUI" / "config"


def init_config() -> ConfigManager:
    """
    初始化 RinUI 配置：解析可写目录并载入配置文件。
    仅初始化一次，防止多个 RinUIWindow 重复载入相同配置文件。
    应在 QApplication 创建后、首次使用 RinConfig 前调用
    （RinUIWindow 初始化时会自动调用）。
    """
    global PATH, _config_initialized
    if _config_initialized:
        return RinConfig
    config_dir = _resolve_config_dir()
    PATH = config_dir
    RinConfig.path = config_dir
    RinConfig.full_path = config_dir / RinConfig.filename
    RinConfig.load_config(DEFAULT_CONFIG)
    _config_initialized = True
    logger.debug("RinUI config directory: %s", config_dir)
    return RinConfig
