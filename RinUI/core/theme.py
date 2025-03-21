import ctypes
import time

from PySide6.QtCore import QObject, Signal, Slot, QTimer, QThread
from .config import DEFAULT_CONFIG, ConfigCenter, PATH
import sys
import darkdetect  # 用于检测系统主题


def check_darkdetect_support():  # 支持 darkdetect
    return sys.platform == "win32" and sys.getwindowsversion().major >= 10


ACCENT_STATES = {
    "acrylic": 3,
    "mica": 2,
    "tabbed": 4,
    "none": 0
}


class ThemeListener(QThread):
    """
    监听系统颜色模式
    """
    themeChanged = Signal(str)

    def run(self):
        last_theme = darkdetect.theme()
        while True:
            current_theme = darkdetect.theme()
            if current_theme != last_theme:
                last_theme = current_theme
                self.themeChanged.emit(current_theme)
                print(f"主题切换：{current_theme}")
            time.sleep(1)  # 每秒检测一次，避免 CPU 占用过高

    def stop(self):
        self.terminate()


class ThemeManager(QObject):
    themeChanged = Signal(str)
    backdropChanged = Signal(str)

    # DWM 常量
    DWMWA_USE_IMMERSIVE_DARK_MODE = 20
    DWMWA_WINDOW_CORNER_PREFERENCE = 33
    DWMWA_NCRENDERING_POLICY = 2
    DWMNCRENDERINGPOLICY_ENABLED = 2
    DWMWA_SYSTEMBACKDROP_TYPE = 38

    # 圆角
    DWMWCP_DEFAULT = 0
    DWMWCP_DONOTROUND = 1  # 无圆角
    DWMWCP_ROUND = 2
    DWMWCP_ROUNDSMALL = 3  # 小圆角

    def clean_up(self):
        """
        清理资源并停止主题监听。
        """
        if self.listener is not None:
            self.config.save_config()
            print("Save config.")
            self.listener.stop()
            self.listener.wait()  # 等待线程结束
            print("Theme listener stopped.")

    def __init__(self):
        super().__init__()
        self.theme_dict = {
            "Light": 0,
            "Dark": 1
        }

        self.listener = None  # 监听线程
        self.current_theme = None
        self.follow_system_color_mode = False
        self.is_darkdetect_supported = check_darkdetect_support()

        self.config = ConfigCenter(PATH, "rin_ui.json")  # 配置中心
        self.config.load_config(DEFAULT_CONFIG)  # 加载配置

        try:
            self.current_theme = self.config["theme"]["current_theme"]
            self.follow_system_color_mode = self.config["theme"]["follow_system"]
        except Exception as e:
            print(f"Failed to load config because of {e}, using default config")

        self.hwnd = None  # 窗口句柄

        self.start_listener()

    def start_listener(self):
        if not self.is_darkdetect_supported:
            print("darkdetect not supported on this platform")
            return
        self.listener = ThemeListener()
        self.listener.themeChanged.connect(self.toggle_theme)
        self.listener.start()

    def set_window(self, window):  # 绑定窗口句柄
        self.hwnd = int(window.winId())
        print(f"Window handle set: {self.hwnd}")

    @Slot(str)
    def apply_backdrop_effect(self, effect_type):
        """
        应用背景效果
        :param effect_type: str, 背景效果类型（acrylic, mica, tabbed, none）
        """
        self._update_window_theme()
        if sys.platform != "win32" or not self.hwnd:
            return -2  # 非 windows或未绑定窗口
        self.backdropChanged.emit(effect_type)

        accent_state = ACCENT_STATES.get(effect_type, 0)

        ctypes.windll.dwmapi.DwmSetWindowAttribute(
            self.hwnd,
            self.DWMWA_SYSTEMBACKDROP_TYPE,
            ctypes.byref(ctypes.c_int(accent_state)),
            ctypes.sizeof(ctypes.c_int)
        )

        self.config["backdrop_effect"] = effect_type
        print(f"Applied \"{effect_type.strip().capitalize()}\" effect")

    def apply_window_effects(self):  # 启用圆角阴影
        if sys.platform != "win32" or not self.hwnd:
            return

        dwm = ctypes.windll.dwmapi

        # 启用非客户端渲染策略（让窗口边框具备阴影）
        ncrp = ctypes.c_int(self.DWMNCRENDERINGPOLICY_ENABLED)
        dwm.DwmSetWindowAttribute(
            self.hwnd,
            self.DWMWA_NCRENDERING_POLICY,
            ctypes.byref(ncrp),
            ctypes.sizeof(ncrp)
        )

        # 启用圆角效果
        corner_preference = ctypes.c_int(self.DWMWCP_ROUND)
        dwm.DwmSetWindowAttribute(
            self.hwnd,
            self.DWMWA_WINDOW_CORNER_PREFERENCE,
            ctypes.byref(corner_preference),
            ctypes.sizeof(corner_preference)
        )
        print("Enabled Rounded and Shadows")

    def _update_window_theme(self):  # 更新窗口的颜色模式
        if sys.platform != "win32" or not self.hwnd:
            return

        dark_mode = ctypes.c_int(self.theme_dict[self.current_theme])
        ctypes.windll.dwmapi.DwmSetWindowAttribute(
            self.hwnd,
            self.DWMWA_USE_IMMERSIVE_DARK_MODE,
            ctypes.byref(dark_mode),
            ctypes.sizeof(dark_mode)
        )
        print(f"Updated window theme to {self.current_theme}")

    @Slot(str)
    def toggle_theme(self, theme: str):  # 切换主题
        if self.current_theme != theme:
            print(f"Switching to '{theme}' theme")
            self.current_theme = theme
            self.config["theme"]["current_theme"] = theme
            self._update_window_theme()
            self.themeChanged.emit(theme)

    @Slot(result=str)
    def get_theme(self):
        if self.follow_system_color_mode:
            self.current_theme = "Dark" if darkdetect.isDark() else "Light"
        return self.current_theme

    @Slot(result=str)
    def get_theme_name(self):
        """获取当前主题名称"""
        return self.current_theme

    @Slot(str)
    def receive(self, message):
        print(message)

    @Slot(result=str)
    def get_backdrop_effect(self):
        """获取当前背景效果"""
        return self.config["backdrop_effect"]
        # if sys.platform != "win32" or not self.hwnd:
        #     return "none"
        #
        # effect_type = ctypes.c_int()
        # result = ctypes.windll.dwmapi.DwmGetWindowAttribute(
        #     self.hwnd,
        #     self.DWMWA_SYSTEMBACKDROP_TYPE,
        #     ctypes.byref(effect_type),
        #     ctypes.sizeof(effect_type)
        # )
        #
        # if result != 0:  # 获取失败时返回 "none"
        #     return "none"
        #
        # return ACCENT_STATES.get(effect_type.value, "none")

    @Slot(result=str)
    def get_theme_color(self):
        """获取当前主题颜色"""
        return self.config["theme_color"]

    @Slot(result=str)
    def set_theme_color(self, color):
        """设置当前主题颜色"""
        self.config["theme_color"] = color
        self.config.save_config()
