import os
import sys
from pathlib import Path
from typing import Union

from PySide6.QtCore import (
    QCoreApplication,
    QObject,
    QStandardPaths,
    QTimer,
    QUrl,
    Slot,
)
from PySide6.QtGui import QColor, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow
from PySide6.QtWidgets import QApplication

from .config import RINUI_PATH, BackdropEffect, Theme, init_config, is_windows
from .logger import logger
from .theme import ThemeManager


_shared_engine = None
_theme_cleanup_connected = False
_dll_directory_handles = []


def _register_windows_qt_dll_directory() -> None:
    """Make PySide6's Qt DLLs discoverable for QML plugins on Windows."""
    if not sys.platform.startswith("win") or not hasattr(os, "add_dll_directory"):
        return
    try:
        import PySide6

        pyside_dir = Path(PySide6.__file__).resolve().parent
        _dll_directory_handles.append(os.add_dll_directory(str(pyside_dir)))
    except OSError:
        pass


_register_windows_qt_dll_directory()


def _write_qml_log(message: str) -> None:
    """Persist QML diagnostics because packaged windowed apps have no console."""
    try:
        base = QStandardPaths.writableLocation(QStandardPaths.AppLocalDataLocation)
        log_dir = Path(base or Path.home() / ".RinUI") / "logs"
        log_dir.mkdir(parents=True, exist_ok=True)
        with (log_dir / "qml-runtime.log").open("a", encoding="utf-8") as log_file:
            log_file.write(f"{message}\n")
    except Exception:
        pass


def _write_qml_failure(qml_path: Path, warnings: list, message: str) -> None:
    """Write details only when QML loading actually fails."""
    _write_qml_log(f"[load] qml={qml_path} rinui={RINUI_PATH}")
    for warning in warnings:
        _write_qml_log(f"[qml-warning] {warning}")
    _write_qml_log(f"[load-failed] {message}")


def _get_shared_engine() -> QQmlApplicationEngine:
    global _shared_engine
    if _shared_engine is None:
        _shared_engine = QQmlApplicationEngine()
    return _shared_engine


class RinUIWindow:
    def __init__(
        self,
        qml_path: Union[str, Path] = None,
        shared_engine: bool = True,
    ):
        """
        Create an application window with RinUI.
        If qml_path is provided, it will automatically load the specified QML file.
        :param qml_path: str or Path, QML file path (eg = "path/to/main.qml")
        :param shared_engine: bool, reuse the shared QML engine when creating RinUI windows
        """
        super().__init__()
        self.windows = None
        if hasattr(self, "_initialized") and self._initialized:
            return

        # 确保 QApplication 已创建（QStandardPaths 等依赖 QCoreApplication）
        app_instance = QCoreApplication.instance()
        if not app_instance:
            msg = "QApplication must be created before RinUIWindow."
            raise RuntimeError(msg)

        # 初始化配置（仅载入一次），必须在 ThemeManager 之前
        init_config()

        self.root_window = None
        self._released = False
        self._qml_warnings = []
        self.shared_engine = shared_engine
        self.engine = _get_shared_engine() if shared_engine else QQmlApplicationEngine()
        self.engine.warnings.connect(self._on_qml_warnings)
        self.theme_manager = ThemeManager()
        self.win_event_filter = None
        self.win_event_manager = None
        if is_windows():
            from .window import WinEventManager

            self.win_event_manager = WinEventManager()
            self.engine.rootContext().setContextProperty(
                "WinEventManager", self.win_event_manager
            )
        self._mac_objc = None
        self._mac_appkit = None
        # Fine-tune native macOS traffic-light position.
        self._mac_traffic_lights_offset_x = 10
        self._mac_traffic_lights_offset_down = 10
        self._mac_traffic_lights_retry_interval_ms = 50
        self._mac_traffic_lights_max_retries = 8
        self.qml_path = qml_path
        self._loaded_root_count = len(self.engine.rootObjects())
        self._initialized = True

        logger.debug("RinUIWindow initializing")

        # ThemeManager is a process-wide singleton. Connect its shutdown hook once,
        # rather than once for every window instance.
        global _theme_cleanup_connected
        if not _theme_cleanup_connected:
            app_instance.aboutToQuit.connect(self.theme_manager.clean_up)
            _theme_cleanup_connected = True

        if qml_path is not None:
            self.load(qml_path)

    def load(self, qml_path: Union[str, Path] = None) -> None:
        """
        Load the QML file and set up the application window.
        :param qml_path:
        :return:
        """
        logger.debug("RinUI module path: %s", RINUI_PATH)

        if self._released:
            raise RuntimeError("Cannot load QML after RinUIWindow.release().")

        if qml_path is None:
            msg = "QML path must be provided to load the window."
            raise ValueError(msg)
        self.qml_path = Path(qml_path)

        if self.qml_path.exists():
            if self.shared_engine:
                import_paths = self.engine.importPathList()
                if str(RINUI_PATH) not in import_paths:
                    self.engine.addImportPath(RINUI_PATH)
            else:
                self.engine.addImportPath(RINUI_PATH)
        else:
            msg = f"Cannot find RinUI module: {RINUI_PATH}"
            raise FileNotFoundError(msg)

        # Existing RinUI users may configure context properties on the engine
        # root context before calling load(), so keep the engine.load contract.
        self.engine.rootContext().setContextProperty("ThemeManager", self.theme_manager)
        try:
            self.engine.load(self.qml_path)
        except Exception as e:
            logger.exception("Cannot load QML file: %s", e)

        root_objects = self.engine.rootObjects()
        if len(root_objects) <= self._loaded_root_count:
            msg = f"Error loading QML file: {self.qml_path}"
            _write_qml_failure(self.qml_path, self._qml_warnings, msg)
            raise RuntimeError(msg)

        # 窗口设置
        self.root_window = root_objects[-1]
        self._loaded_root_count = len(root_objects)
        self._released = False

        all_windows = [self.root_window] + self.root_window.findChildren(QQuickWindow)
        self.windows = [w for w in all_windows if w.property("isRinUIWindow")]

        for window in self.windows:
            self.theme_manager.set_window(window)

        # 窗口句柄管理
        self._window_handle_setup()
        self._setup_macos_native_window()

        self._print_startup_info()

    @Slot(list)
    def _on_qml_warnings(self, warnings: list) -> None:
        for warning in warnings:
            logger.warning("QML: %s", warning)
            self._qml_warnings.append(str(warning))
            if os.environ.get("RINUI_QML_LOG"):
                _write_qml_log(f"[qml-warning] {warning}")

    def _window_handle_setup(self) -> None:
        """
        set up the window handle. (Only available on Windows platform)
        :return:
        """
        if not is_windows():
            return

        # [RinUI FIX] 诊断开关: 设为 1 时完全不装原生事件过滤器、也不改写窗口样式,
        # 窗口退回普通的、带系统边框的 Windows 窗口(自定义标题栏仍然画在客户区里)。
        # 用途是把"框架对窗口做的原生 hack"和其它因素分开对照, 出问题时也能一键排掉。
        if os.environ.get("RINUI_DISABLE_NATIVE_FILTER", "").strip().lower() in (
            "1",
            "true",
            "yes",
            "on",
        ):
            logger.info("[RinUI] RINUI_DISABLE_NATIVE_FILTER=1, 跳过原生窗口处理")
            return

        from .window import WinEventFilter, WinEventManager

        self.win_event_filter = WinEventFilter(self.windows, self._apply_windows_effects)
        if self.win_event_manager is None:
            self.win_event_manager = WinEventManager()
        self.win_event_manager.set_windows(self.windows, self._apply_windows_effects)

        app_instance = QApplication.instance()
        app_instance.installNativeEventFilter(self.win_event_filter)
        self.win_event_filter.initialize_windows()
        for window in self.windows:
            self.win_event_manager.syncWindowFrame(window)
        self.win_event_manager.flush_pending_frame_sync_windows()
        self._apply_windows_effects()
        self._install_transparent_render_clear()

    def _install_transparent_render_clear(self) -> None:
        if not is_windows():
            return

        transparent = QColor(0, 0, 0, 0)
        for window in self.windows:
            if not window.property("backdropEnabled"):
                continue

            window.setColor(transparent)
            if window.property("_rinuiTransparentRenderClearInstalled"):
                continue

            def enforce_transparent_clear(w=window):
                if not w or not w.property("backdropEnabled"):
                    return
                w.setColor(transparent)

            window.beforeFrameBegin.connect(enforce_transparent_clear)
            window.beforeRendering.connect(enforce_transparent_clear)
            window.beforeRenderPassRecording.connect(enforce_transparent_clear)
            window.setProperty("_rinuiTransparentRenderClearInstalled", True)

    def _setup_macos_native_window(self) -> None:
        """Apply macOS native titlebar tweaks for custom title content."""
        if sys.platform != "darwin":
            return

        try:
            import AppKit
            import objc
        except Exception as err:
            logger.warning("Cannot enable native macOS titlebar integration: %s", err)
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
            logger.warning("Failed to apply macOS native titlebar style: %s", err)
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
            logger.warning("Failed to shift macOS traffic lights: %s", err)
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

    def release(self) -> None:
        """Release this window's QML object tree and native event resources.

        ``QQuickWindow.close()`` only hides a window; it does not destroy its
        QML object tree. Applications that create transient windows should call
        this method when the window will not be reused. The shared engine and
        its compiled QML component cache intentionally remain alive.
        """
        if self._released:
            return
        self._released = True

        try:
            self.engine.warnings.disconnect(self._on_qml_warnings)
        except (RuntimeError, TypeError):
            pass

        app_instance = QCoreApplication.instance()
        if app_instance is not None and self.win_event_filter is not None:
            try:
                app_instance.removeNativeEventFilter(self.win_event_filter)
            except (RuntimeError, TypeError):
                pass
        self.win_event_filter = None

        if self.win_event_manager is not None:
            self.win_event_manager.set_windows([])
            self.win_event_manager.pending_frame_sync_windows = []

        for window in self.windows or []:
            try:
                self.theme_manager.remove_window(window)
            except (RuntimeError, TypeError):
                pass
        self.windows = []

        root = self.root_window
        self.root_window = None

        if root is not None:
            try:
                root.hide()
                root.releaseResources()
                root.deleteLater()
            except RuntimeError:
                pass
        # Component caches may only be trimmed after the object tree is gone.
        # Do not trim the shared engine here: other windows may still use it.
        if not self.shared_engine:
            QTimer.singleShot(0, self._cleanup_private_engine)

    def _cleanup_private_engine(self) -> None:
        if self.shared_engine or self.engine is None:
            return
        try:
            self.engine.clearComponentCache()
            self.engine.collectGarbage()
            self.engine.deleteLater()
        except RuntimeError:
            pass

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
        logger.debug(
            "RinUIWindow loaded: qml=%s theme=%s backdrop=%s os=%s",
            self.qml_path,
            self.theme_manager.current_theme,
            self.theme_manager.get_backdrop_effect(),
            sys.platform,
        )


if __name__ == "__main__":
    # 新用法，应该更规范了捏
    app = QApplication(sys.argv)
    example = RinUIWindow("../../examples/gallery.qml")
    sys.exit(app.exec())
