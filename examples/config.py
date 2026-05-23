import sys
from pathlib import Path

from PySide6.QtCore import QLocale

PROJECT_ROOT = Path(__file__).parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from RinUI import ConfigManager  # noqa: E402

PATH = Path(__file__).parent.absolute()
DFT_CONFIG = {
    "language": QLocale.system().name(),
    "favorites": [],
    "recentlyViewed": [],
}


cfg = ConfigManager(str(PATH), "config.json")
cfg.load_config(DFT_CONFIG)
