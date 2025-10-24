import sys

from PySide6.QtWidgets import QApplication

from RinUI import RinUIWindow, Theme

if __name__ == "__main__":
    app = QApplication(sys.argv)

    window2 = RinUIWindow("test3.qml")
    window2.setTheme(Theme.Auto)

    sys.exit(app.exec())
