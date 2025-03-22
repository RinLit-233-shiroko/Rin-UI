import sys
from PySide6.QtWidgets import QApplication, QWidget, QPushButton, QVBoxLayout
from PySide6.QtQml import QQmlApplicationEngine
from .theme import ThemeManager


class TestWindow(QWidget):
    def __init__(self, theme_manager):
        super().__init__()
        layout = QVBoxLayout()
        self.setLayout(layout)
        self.setWindowTitle("Test Window")
        btn = QPushButton("Hello World")
        btn.clicked.connect(
            lambda: theme_manager.toggle_theme("Light" if theme_manager.current_theme == "Dark" else "Dark")
        )
        self.layout().addWidget(btn)
        self.resize(400, 300)


def create_qml_app(qml_path: str = "main.qml"):
    """
    创建基于 RinUI 的 QML 应用程序。
    :param qml_path: str, QML 文件路径
    """
    app = QApplication([])
    engine = QQmlApplicationEngine()

    # 设置主题管理器
    theme_manager = ThemeManager()
    engine.rootContext().setContextProperty("ThemeManager", theme_manager)
    app.aboutToQuit.connect(theme_manager.clean_up)  # 退出时清理主题管理器

    engine.load(qml_path)
    if not engine.rootObjects():
        sys.exit(-1)

    root_window = engine.rootObjects()[0]

    # 启用 DWM 效果（仅限 Windows）
    if sys.platform == "win32":
        theme_manager.set_window(root_window)
        theme_manager.apply_backdrop_effect(theme_manager.get_backdrop_effect())
        theme_manager.apply_window_effects()

        # test_window = TestWindow(theme_manager)
        #
        # test_window.show()

    app.exec()  # 启动应用程序


if __name__ == "__main__":
    create_qml_app("../../examples/gallery.qml")
