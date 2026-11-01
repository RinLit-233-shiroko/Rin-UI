import sys
from pathlib import Path

from PySide6.QtCore import QLocale, QStandardPaths

PROJECT_ROOT = Path(__file__).parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from RinUI import ConfigManager  # noqa: E402
from RinUI import get_logger  # noqa: E402


logger = get_logger("GalleryConfig")

DFT_CONFIG = {
    "language": QLocale.system().name(),
    "favorites": [],
    "recentlyViewed": [],
}

# 应用自有配置（区别于 RinUI 库的 RinConfig），路径延迟到 init_app_config() 解析，
# 通过 QStandardPaths.AppLocalDataLocation 落盘，兼容 WindowsAppx
cfg = ConfigManager(filename="config.json")
_app_config_initialized = False


def _resolve_app_config_dir() -> Path:
    """解析应用配置目录，优先 QStandardPaths.AppLocalDataLocation，回退到 ~/.RinUI-Gallery。"""
    base = QStandardPaths.writableLocation(QStandardPaths.AppLocalDataLocation)
    if not base:
        base = str(Path.home() / ".RinUI-Gallery")
    return Path(base) / "config"


def init_app_config() -> ConfigManager:
    """
    初始化应用配置（仅一次）。应在 QApplication 创建并设置
    organizationName/applicationName 之后调用，以便路径包含应用名。
    """
    global _app_config_initialized
    if _app_config_initialized:
        return cfg
    config_dir = _resolve_app_config_dir()
    cfg.path = config_dir
    cfg.full_path = config_dir / cfg.filename
    cfg.load_config(DFT_CONFIG)
    _app_config_initialized = True
    logger.debug("Gallery config directory: %s", config_dir)
    return cfg
