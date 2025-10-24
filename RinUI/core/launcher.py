import sys
from pathlib import Path
from typing import Union

from PySide6.QtCore import QCoreApplication, QObject, QUrl
from PySide6.QtGui import QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow
from PySide6.QtWidgets import QApplication

from .config import RINUI_PATH, BackdropEffect, Theme, is_windows
from .theme import ThemeManager


class RinUIWindow:
    def __init__(self, qml_path: Union[str, Path] = None):
        """
        Create an application window with RinUI.
        If qml_path is provided, it will automatically load the specified QML file.
        :param qml_path: str or Path, QML file path (eg = "path/to/main.qml")
        """
        super().__init__()
        self.windows = None
        if hasattr(self, "_initialized") and self._initialized:
            return

        self.root_window = None
        self.engine = QQmlApplicationEngine()
        self.theme_manager = ThemeManager()
        self.win_event_filter = None
        self.win_event_manager = None
        self.qml_path = qml_path
        self._initialized = True

        print("✨ RinUIWindow Initializing")

        # 退出清理
        app_instance = QCoreApplication.instance()
        if not app_instance:
            msg = "QApplication must be created before RinUIWindow."
            raise RuntimeError(msg)

        app_instance.aboutToQuit.connect(self.theme_manager.clean_up)

        if qml_path is not None:
            self.load(qml_path)

    def load(self, qml_path: Union[str, Path] = None) -> None:
        """
        Load the QML file and set up the application window.
        :param qml_path:
        :return:
        """
        # RInUI 模块
        print(f"UI Module Path: {RINUI_PATH}")

        if qml_path is None:
            msg = "QML path must be provided to load the window."
            raise ValueError(msg)
        self.qml_path = Path(qml_path)

        if self.qml_path.exists():
            self.engine.addImportPath(RINUI_PATH)
        else:
            msg = f"Cannot find RinUI module: {RINUI_PATH}"
            raise FileNotFoundError(msg)

        # 主题管理器
        self.engine.rootContext().setContextProperty("ThemeManager", self.theme_manager)
        try:
            self.engine.load(self.qml_path)
        except Exception as e:
            print(f"Cannot Load QML file: {e}")

        if not self.engine.rootObjects():
            msg = f"Error loading QML file: {self.qml_path}"
            raise RuntimeError(msg)

        # 窗口设置
        self.root_window = self.engine.rootObjects()[0]
        all_windows = [self.root_window] + self.root_window.findChildren(QQuickWindow)
        self.windows = [w for w in all_windows if w.property("isRinUIWindow")]

        for window in self.windows:
            self.theme_manager.set_window(window)

        # 窗口句柄管理
        self._window_handle_setup()

        self._print_startup_info()

    def _window_handle_setup(self) -> None:
        """
        set up the window handle. (Only available on Windows platform)
        :return:
        """
        if not is_windows():
            return

        from .window import WinEventFilter, WinEventManager

        self.win_event_filter = WinEventFilter(self.windows)
        self.win_event_manager = WinEventManager()

        app_instance = QApplication.instance()
        app_instance.installNativeEventFilter(self.win_event_filter)
        self.engine.rootContext().setContextProperty(
            "WinEventManager", self.win_event_manager
        )
        self._apply_windows_effects()

    def setIcon(self, path: Union[str, Path] = None) -> None:
        """
        Sets the icon for the application.
        :param path: str or Path, icon file path (eg = "path/to/icon.png")
        :return:
        """
        app_instance = QApplication.instance()
        path = Path(path).as_posix()
        if app_instance:
            app_instance.setWindowIcon(QIcon(path))  # 设置应用程序图标
            self.root_window.setProperty("icon", QUrl.fromLocalFile(path))
        else:
            msg = "Cannot set icon before QApplication is created."
            raise RuntimeError(msg)

    def _apply_windows_effects(self) -> None:
        """
        Apply Windows effects to the window.
        :return:
        """
        if is_windows():
            self.theme_manager.apply_backdrop_effect(
                self.theme_manager.get_backdrop_effect()
            )
            self.theme_manager.apply_window_effects()

    # func名称遵循 Qt 命名规范
    def setBackdropEffect(self, effect: BackdropEffect) -> None:
        """
        Sets the backdrop effect for the window. (Only available on Windows)
        :param effect: BackdropEffect, type of backdrop effect（Acrylic, Mica, Tabbed, None_）
        :return:
        """
        if not is_windows() and effect != BackdropEffect.None_:
            msg = "Only can set backdrop effect on Windows platform."
            raise OSError(msg)
        self.theme_manager.apply_backdrop_effect(effect.value)

    def setTheme(self, theme: Theme) -> None:
        """
        Sets the theme for the window.
        :param theme: Theme, type of theme（Auto, Dark, Light）
        :return:
        """
        self.theme_manager.toggle_theme(theme.value)

    def __getattr__(self, name) -> QObject:
        """获取 QML 窗口属性"""
        try:
            root = object.__getattribute__(self, "root_window")
            return getattr(root, name)
        except AttributeError as err:
            msg = f"\"RinUIWindow\" object has no attribute '{name}', you need to load() qml at first."
            raise AttributeError(msg) from err

    def _print_startup_info(self) -> None:
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
