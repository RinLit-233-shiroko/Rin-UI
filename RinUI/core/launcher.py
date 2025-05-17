import os
import sys

from PySide6.QtCore import QCoreApplication, QObject
from PySide6.QtWidgets import QApplication, QWidget, QPushButton, QVBoxLayout
from PySide6.QtQml import QQmlApplicationEngine
from .theme import ThemeManager
from .config import BackdropEffect, is_windows, Theme


def resource_path(relative_path: str) -> str:
    """兼容 PyInstaller 打包和开发环境的路径"""
    if hasattr(sys, '_MEIPASS'):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.abspath(relative_path)


class TestWindow(QWidget):
    def __init__(self, theme_manager: ThemeManager):
        super().__init__()
        layout = QVBoxLayout()
        self.setLayout(layout)
        self.setWindowTitle("Test Window")
        btn = QPushButton(theme_manager.current_theme)
        btn.clicked.connect(
            lambda: theme_manager.toggle_theme("Light" if theme_manager.current_theme == "Dark" else "Dark")
        )
        self.layout().addWidget(btn)
        self.resize(400, 300)


class RinUIWindow(QObject):
    # _instance = None
    #
    # def __new__(cls, *args, **kwargs):  # 单例模式管理
    #     if cls._instance is None:
    #         cls._instance = super().__new__(cls)
    #     return cls._instance

    def __init__(self, qml_path: str):
        """
        创建基于 RinUI 的 QML 应用程序。
        :param qml_path: str, QML 文件路径
        """
        super().__init__()
        if hasattr(self, "_initialized") and self._initialized:
            return
        self._initialized = True
        print("✨ RinUIWindow Initializing")

        self.engine = QQmlApplicationEngine()
        self.theme_manager = ThemeManager()
        self.qml_path = qml_path
        self.autoSetWindowsEffect = True

        self._setup_application()
        self.print_startup_info()

        # 退出清理
        app_instance = QCoreApplication.instance()
        if app_instance:
            app_instance.aboutToQuit.connect(self.theme_manager.clean_up)

    def _setup_application(self) -> None:
        """Setup"""
        # RInUI 模块
        rinui_path = os.path.abspath(os.path.dirname(__file__))  # RinUI/core 目录
        rinui_import_path = resource_path(os.path.join(rinui_path, "../../"))  # 使用 resource_path 处理路径
        print(f"UI Module Path: {rinui_import_path}")

        if os.path.exists(rinui_import_path):
            self.engine.addImportPath(rinui_import_path)
        else:
            raise FileNotFoundError(f"Cannot find RinUI module: {rinui_import_path}")

        # 主题管理器
        self.engine.rootContext().setContextProperty("ThemeManager", self.theme_manager)
        try:
            self.engine.load(self.qml_path)
        except Exception as e:
            print(f"Cannot Load QML file: {e}")

        if not self.engine.rootObjects():
            raise RuntimeError(f"Error loading QML file: {self.qml_path}")

        # 窗口设置
        self.root_window = self.engine.rootObjects()[0]

        self.theme_manager.set_window(self.root_window)
        self._apply_windows_effects() if self.autoSetWindowsEffect else None

    def _apply_windows_effects(self) -> None:
        """
        Apply Windows effects to the window.
        :return:
        """
        if sys.platform == "win32":
            self.theme_manager.apply_backdrop_effect(self.theme_manager.get_backdrop_effect())
            self.theme_manager.apply_window_effects()

    # func名称遵循 Qt 命名规范
    def setBackdropEffect(self, effect: BackdropEffect) -> None:
        """
        Sets the backdrop effect for the window. (Only available on Windows)
        :param effect: BackdropEffect, type of backdrop effect（Acrylic, Mica, Tabbed, None_）
        :return:
        """
        if not is_windows() and effect != BackdropEffect.None_:
            raise OSError("Only can set backdrop effect on Windows platform.")
        self.theme_manager.apply_backdrop_effect(effect.value)

    def setTheme(self, theme: Theme) -> None:
        """
        Sets the theme for the window.
        :param theme: Theme, type of theme（Auto, Dark, Light）
        :return:
        """
        self.theme_manager.toggle_theme(theme.value)

    def __getattr__(self, name: str) -> object:
        """获取 QML 窗口属性"""
        try:
            root = object.__getattribute__(self, "root_window")
            return getattr(root, name)
        except AttributeError:
            raise AttributeError(f"\"RinUIWindow\" object has no attribute '{name}'\ntry to use 'RinUI.core' module to get QML window attribute.")

    def print_startup_info(self) -> None:
        border = "=" * 40
        print(f"\n{border}")
        print("✨ RinUIWindow Loaded Successfully!")
        print(f"QML File Path: {self.qml_path}")
        print(f"Current Theme: {self.theme_manager.current_theme}")
        print(f"Backdrop Effect: {self.theme_manager.get_backdrop_effect()}")
        print(f"OS: {sys.platform}")
        print(border + "\n")


if __name__ == "__main__":
    # 新用法，应该更规范了捏
    app = QApplication(sys.argv)
    example = RinUIWindow("../../examples/gallery.qml")
    sys.exit(app.exec())
