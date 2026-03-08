import sys
from ctypes import c_void_p
from pathlib import Path
from typing import Union

from PySide6.QtCore import QCoreApplication, QObject, QTimer, QUrl
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
        self._mac_objc = None
        self._mac_appkit = None
        # Fine-tune native macOS traffic-light position.
        self._mac_traffic_lights_offset_x = 10
        self._mac_traffic_lights_offset_down = 10
        self._mac_traffic_lights_retry_interval_ms = 50
        self._mac_traffic_lights_max_retries = 8
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
        self._setup_macos_native_window()

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

    def _setup_macos_native_window(self) -> None:
        """Apply macOS native titlebar tweaks for custom title content."""
        if sys.platform != "darwin":
            return

        try:
            import AppKit
            import objc
        except Exception as err:
            print(f"Cannot enable native macOS titlebar integration: {err}")
            self._disable_native_mac_frame()
            return

        self._mac_appkit = AppKit
        self._mac_objc = objc

        for window in self.windows:
            if not window.property("useNativeMacFrame"):
                continue

            self._apply_macos_window_style(window)
            window.visibleChanged.connect(
                lambda visible, w=window: self._on_macos_window_visible_changed(
                    w, visible
                )
            )

    def _on_macos_window_visible_changed(self, window: QQuickWindow, visible: bool) -> None:
        if visible and window.property("useNativeMacFrame"):
            window.setProperty("_rinuiMacTrafficLightsShiftApplied", False)
            window.setProperty("_rinuiMacTrafficLightsShiftRetryCount", 0)
            self._apply_macos_window_style(window)

    def _disable_native_mac_frame(self) -> None:
        for window in self.windows:
            if window.property("useNativeMacFrame"):
                window.setProperty("useNativeMacFrame", False)

    def _apply_macos_window_style(self, window: QQuickWindow) -> None:
        if not self._mac_objc or not self._mac_appkit:
            return

        try:
            ns_view = self._mac_objc.objc_object(c_void_p=int(window.winId()))
            ns_window = ns_view.window() if ns_view else None
            if not ns_window:
                return

            # Hide the system title visuals and keep traffic lights in place.
            ns_window.setTitleVisibility_(self._mac_appkit.NSWindowTitleHidden)
            ns_window.setTitlebarAppearsTransparent_(True)
            ns_window.setMovableByWindowBackground_(False)
            style_mask = int(ns_window.styleMask()) | int(
                self._mac_appkit.NSWindowStyleMaskFullSizeContentView
            )
            ns_window.setStyleMask_(style_mask)
            self._schedule_macos_traffic_light_shift(window, retry_count=0)
        except Exception as err:
            print(f"Failed to apply macOS native titlebar style: {err}")
            window.setProperty("useNativeMacFrame", False)

    def _schedule_macos_traffic_light_shift(
        self, window: QQuickWindow, retry_count: int
    ) -> None:
        if window.property("_rinuiMacTrafficLightsShiftApplied"):
            return

        moved = self._shift_macos_traffic_lights_once(window)
        if moved:
            window.setProperty("_rinuiMacTrafficLightsShiftApplied", True)
            window.setProperty("_rinuiMacTrafficLightsShiftRetryCount", retry_count)
            return

        if retry_count >= self._mac_traffic_lights_max_retries:
            return

        next_retry = retry_count + 1
        window.setProperty("_rinuiMacTrafficLightsShiftRetryCount", next_retry)
        QTimer.singleShot(
            self._mac_traffic_lights_retry_interval_ms,
            lambda w=window, c=next_retry: self._schedule_macos_traffic_light_shift(
                w, c
            ),
        )

    def _shift_macos_traffic_lights_once(self, window: QQuickWindow) -> bool:
        if not self._mac_objc or not self._mac_appkit:
            return False

        try:
            ns_view = self._mac_objc.objc_object(c_void_p=int(window.winId()))
            ns_window = ns_view.window() if ns_view else None
            if not ns_window:
                return False

            close_button = ns_window.standardWindowButton_(
                self._mac_appkit.NSWindowCloseButton
            )
            minimize_button = ns_window.standardWindowButton_(
                self._mac_appkit.NSWindowMiniaturizeButton
            )
            zoom_button = ns_window.standardWindowButton_(
                self._mac_appkit.NSWindowZoomButton
            )
            buttons = [btn for btn in (close_button, minimize_button, zoom_button) if btn]
            if not buttons:
                return False

            # Move the shared container first to preserve native spacing.
            button_host = close_button.superview() if close_button else buttons[0].superview()
            if button_host:
                host_frame = button_host.frame()
                button_host.setFrameOrigin_(
                    (
                        host_frame.origin.x + self._mac_traffic_lights_offset_x,
                        host_frame.origin.y - self._mac_traffic_lights_offset_down,
                    )
                )
                return True

            for button in buttons:
                frame = button.frame()
                button.setFrameOrigin_(
                    (
                        frame.origin.x + self._mac_traffic_lights_offset_x,
                        frame.origin.y - self._mac_traffic_lights_offset_down,
                    )
                )
            return True
        except Exception as err:
            print(f"Failed to shift macOS traffic lights: {err}")
            return False

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
