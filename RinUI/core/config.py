import os
import json
import platform
from enum import Enum


def is_win11() -> bool:
    if is_windows():
        if platform.release() >= '10' and int(platform.version().split('.')[2]) >= 22000:
            return True
    return False


def is_win10() -> bool:
    if is_windows():
        if platform.release() >= '10' and int(platform.version().split('.')[2]) >= 19000:
            return True
    return False


def is_windows() -> bool:
    return platform.system() == 'Windows'


BASE_DIR = os.path.abspath(os.getcwd())
PATH = os.path.join(BASE_DIR, "RinUI_Config/config") # 将RinUI更改成RinUI_Config，避免IDE判断错误
DEFAULT_CONFIG = {
    "language": "zh_CN",
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


class ConfigCenter:
    def __init__(self, path: str, filename: str):
        self.path = path
        self.filename = filename
        self.config = {}
        self.full_path = os.path.join(self.path, self.filename)

    def load_config(self, default_config) -> None:
        if default_config is None:
            print('Warning: "default_config" is None, use empty config instead.')
            default_config = {}
        # 如果文件存在，加载配置
        if os.path.exists(self.full_path):
            with open(self.full_path, 'r', encoding='utf-8') as f:
                self.config = json.load(f)
        else:
            self.config = default_config  # 如果文件不存在，使用默认配置
            self.save_config()

    def update_config(self) -> None:  # 更新配置
        try:
            with open(self.full_path, 'r', encoding='utf-8') as f:
                self.config = json.load(f)
        except Exception as e:
            print(f'Error: {e}')
            self.config = {}

    def upload_config(self, key=str or list, value=None):
        if type(key) is str:
            self.config[key] = value
        elif type(key) is list:
            for k in key:
                self.config[k] = value
        else:
            raise TypeError('key must be str or list')
        self.save_config()

    def save_config(self):
        try:
            # 确保配置文件目录存在
            if not os.path.exists(self.path):
                os.makedirs(self.path)
            with open(self.full_path, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, ensure_ascii=False, indent=4)
        except Exception as e:
            print(f'Error: {e}')

    def __getitem__(self, key: str):
        return self.config.get(key)

    def __setitem__(self, key: str, value: str):
        self.config[key] = value
        self.save_config()

    def __repr__(self):
        return json.dumps(self.config, ensure_ascii=False, indent=4)
