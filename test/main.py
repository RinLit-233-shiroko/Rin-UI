import sys

from PySide6.QtWidgets import QApplication

from RinUI import RinUIWindow

if __name__ == "__main__":
    app = QApplication(sys.argv)

    window = RinUIWindow("test3.qml")

    app.exec()
