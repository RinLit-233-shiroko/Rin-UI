import os
import sys

from PySide6.QtCore import Slot, QObject, QLocale, QTranslator
from PySide6.QtGui import QGuiApplication
from PySide6.QtWidgets import QApplication
from datetime import datetime

import RinUI
from RinUI import RinUIWindow, RinUITranslator, __version__
from config import cfg


class Gallery(RinUIWindow):
    def __init__(self):
        super().__init__("gallery.qml")
        self.setIcon("assets/gallery.png")
        self.backend = Backend()
        self.backend.setBackendParent(self)
        self.setProperty("title", f"RinUI Gallery {datetime.now().year}")  # 前后端交互示例

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
        lang_path = f"languages/{lang}.qm"

        if not os.path.exists(lang_path):
            print(f"Language file {lang_path} not found. Fallback to default (en_US)")
            lang = "en_US"

        cfg["language"] = lang
        cfg.save_config()
        ui_translator = RinUITranslator(QLocale(lang))
        translator = QTranslator()
        translator.load(lang_path)
        QApplication.instance().removeTranslator(ui_translator)
        QApplication.instance().removeTranslator(translator)
        QApplication.instance().installTranslator(ui_translator)
        QApplication.instance().installTranslator(translator)
        self.parent.engine.retranslate()


if __name__ == '__main__':
    print(RinUI.__file__)
    app = QApplication(sys.argv)

    # i18n
    lang = cfg["language"]
    ui_translator = RinUITranslator(QLocale(lang))
    app.installTranslator(ui_translator)
    translator = QTranslator()
    translator.load(f"languages/{lang}.qm")  # 放在同目录或者使用绝对路径
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
