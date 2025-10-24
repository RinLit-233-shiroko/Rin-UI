import sys
from datetime import datetime
from pathlib import Path

from config import cfg
from PySide6.QtCore import QLocale, QObject, Qt, QTranslator, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtWidgets import QApplication

import RinUI
from RinUI import RinUITranslator, RinUIWindow, __version__

SCRIPT_DIR = Path(__file__).parent.absolute()
PROJECT_ROOT = SCRIPT_DIR.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))


class Gallery(RinUIWindow):
    def __init__(self):
        qml_file = SCRIPT_DIR / "gallery.qml"
        super().__init__(str(qml_file))
        icon_path = SCRIPT_DIR / "assets" / "gallery.png"
        self.setIcon(str(icon_path))

        self.backend = Backend()
        self.backend.setBackendParent(self)
        self.setProperty(
            "title", f"RinUI Gallery {datetime.now().year}"
        )  # 前后端交互示例

        self.engine.rootContext().setContextProperty("Backend", self.backend)  # 注入


class Backend(QObject):
    def setBackendParent(self, parent):
        self.parent = parent

    @Slot(result=str)
    def getVersion(self):
        return __version__

    @Slot(str)
    def copyToClipboard(self, text):
        clipboard = QGuiApplication.clipboard()
        clipboard.setText(text)
        print(f"Copied: {text}")

    @Slot(result=str)
    def getLanguage(self):
        return cfg["language"]

    @Slot(result=str)
    def getSystemLanguage(self):
        return QLocale.system().name()

    @Slot(str)
    def setLanguage(self, lang: str):  # sample: zh_CN; en_US
        global ui_translator, translator
        lang_path = SCRIPT_DIR / "languages" / f"{lang}.qm"

        if not lang_path.exists():
            print(f"Language file {lang_path} not found. Fallback to default (en_US)")
            lang = "en_US"
            lang_path = SCRIPT_DIR / "languages" / f"{lang}.qm"

        cfg["language"] = lang
        cfg.save_config()
        ui_translator = RinUITranslator(QLocale(lang))
        translator = QTranslator()
        translator.load(str(lang_path))
        QApplication.instance().removeTranslator(ui_translator)
        QApplication.instance().removeTranslator(translator)
        QApplication.instance().installTranslator(ui_translator)
        QApplication.instance().installTranslator(translator)
        self.parent.engine.retranslate()


if __name__ == "__main__":
    print(RinUI.__file__)
    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )
    app = QApplication(sys.argv)

    # i18n
    lang = cfg["language"]
    ui_translator = RinUITranslator(QLocale(lang))
    app.installTranslator(ui_translator)
    translator = QTranslator()
    lang_file = SCRIPT_DIR / "languages" / f"{lang}.qm"
    if lang_file.exists() and translator.load(str(lang_file)):
        app.installTranslator(translator)

    gallery = Gallery()

    app.aboutToQuit.connect(cfg.save_config)
    app.exec()
    # app = QGuiApplication([])

    # 创建 QML 引擎
    # engine = QQmlApplicationEngine()
    # # engine.addImportPath(str(Path(__file__).parent.parent / "RinUI"))
    # print(engine.importPathList())
    #
    # # 加载 QML 文件
    # engine.load("gallery.qml")
    #
    #
    # # 启动应用
    # app.exec()
    # create_qml_app("gallery.qml")
