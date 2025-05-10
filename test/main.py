import sys

from PySide6.QtWidgets import QApplication
from RinUI import RinUIWindow, BackdropEffect

import platform

def get_os_info():
    return platform.system(), platform.release(), platform.version()


if __name__ == '__main__':
    app = QApplication(sys.argv)
    # window2 = RinUIWindow("test2.qml")
    window = RinUIWindow("test1.qml")

    system_info = get_os_info()
    if system_info[0] == "Windows" and system_info[1] == "10":
        window.setBackdropEffect(BackdropEffect.Acrylic)
    elif system_info[0] == "Windows" and system_info[1] == "11":
        window.setBackdropEffect(BackdropEffect.Mica)
    else:
        window.setBackdropEffect(BackdropEffect.None_)


    # print(window, window2)

    sys.exit(app.exec())
