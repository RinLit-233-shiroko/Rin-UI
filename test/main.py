# import sys
#
# from PySide6.QtCore import Qt
# from PySide6.QtWidgets import QApplication, QWidget
#
#
# app = QApplication(sys.argv)
#
#
# class MainPresenter:
#     def __init__(self, view):
#         self._view = view
#         self.init()
#
#     def init(self):
#         self._view.setWindowFlags(Qt.WindowType.Window | Qt.WindowType.NoTitleBarBackgroundHint)
#         self._view.setStyleSheet("background-color: rgba(0, 0, 0, 0);")
#         self._view.resize(800, 600)
#         self._view.show()
#
#
# class MainView(QWidget):
#     def __init__(self):
#         super().__init__()
#         self._presenter = MainPresenter(self)
#
#
# view = MainView()
# view.show()
# sys.exit(app.exec())


import sys

from PySide6.QtCore import Qt, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


app = QGuiApplication(sys.argv)

engine = QQmlApplicationEngine()
engine.load(QUrl("main.qml"))

if not engine.rootObjects():
    sys.exit(-1)

sys.exit(app.exec())