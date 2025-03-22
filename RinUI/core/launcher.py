import os
import json

PATH = "../RinUI/config"
DEFAULT_CONFIG = {
    "language": "zh_CN",
    "theme": {
        "current_theme": "Light",
        "follow_system": True
    },
    "theme_color": "#605ed2",
    "backdrop_effect": "mica"
}


class ConfigCenter:
    def __init__(self, path, filename):
        self.path = path
        self.filename = filename
        self.config = {}
        self.full_path = os.path.join(self.path, self.filename)

    def load_config(self, default_config):
        if default_config is None:
            print('Warning: \"default_config\" is None, use empty config instead.')
            default_config = {}
        # 如果文件存在，加载配置
        if os.path.exists(self.full_path):
            with open(self.full_path, 'r', encoding='utf-8') as f:
                self.config = json.load(f)
        else:
            self.config = default_config  # 如果文件不存在，使用默认配置
            self.save_config()

    def update_config(self):  # 更新配置
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
            with open(self.full_path, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, ensure_ascii=False, indent=4)
        except FileNotFoundError:
            os.makedirs(self.path)
            self.save_config()
        except Exception as e:
            print(f'Error: {e}')

    def __getitem__(self, key):
        return self.config.get(key)

    def __setitem__(self, key, value):
        self.config[key] = value
        self.save_config()

    def __repr__(self):
        return json.dumps(self.config, ensure_ascii=False, indent=4)
