<div align="center">
<img src="docs/img/logo.png" alt="RinUI Logo" width="18%">
<h1>RinUI</h1>
<p>A Fluent Design-like UI library for Qt Quick (QML)</p>

**English** | [中文](./docs/README_zhCN.MD)

</div>

> [!TIP]
> This project is still in development and not ready for production use!
>
> Of course, you are welcome to contribute to this project.

## 📄 Introduction

RinUI is a UI library similar to Fluent Design for Qt Quick (QML), RinUI will provide high-quality components and practical functions.
With simple configuration, you can quickly develop elegant UI interfaces in the Fluent style.

### Features
* Elegant Fluent Design controls (WIP)
* Dark and light mode, automatic switching
* Compatible with original QML control names
* i18n Internationalization
* Multi-programming language support (WIP)
* Theme system (WIP)
* Development documentation, [preview](https://ui.rinlit.cn/) now. (WIP)

### Screenshots
![Screenshot 1](/docs/img/shot_1.png)

<details style="text-align: center">
<summary>More screenshots...</summary>

![img.png](/docs/img/img.png)
![img_1.png](/docs/img/img_1.png)
![img_2.png](/docs/img/img_2.png)
![img_3.png](/docs/img/img_3.png)
</details>

> The image in the banner comes from Pixiv, PID: [125975786](https://www.pixiv.net/artworks/125975786)

## 🪄 Usage

You can install RinUI via pip:
```bash
pip install RinUI
```

Import RinUI in your QML file:
```qmllang
import RinUI
```
Then you can run the QML file in your project.
```python
import sys
from RinUI import *
from PySide6.QtWidgets import QApplication

if __name__ == '__main__':
    app = QApplication(sys.argv)
    your_app = RinUIWindow("/path/to/your/file.qml")
    sys.exit(app.exec_())
```

You also can view the demo in the source code, like this:
```bash
cd examples
python gallery.py
```

You also can move the RinUI folder to anywhere in your project's directory.

> [!NOTE]
> The documentation is still in progress!!
> You can view the source code to learn more about the components and themes at the moment.

Now you can learn more about RinUI components and themes in [the online documentation](https://ui.rinlit.cn/).

## 🙌 Acknowledgements
### Resources
- [PySide6 & Qt Quick](https://www.qt.io/)
- [Fluent Design System](https://fluent2.microsoft.design/)
- [Fluent UI System Icons](https://github.com/microsoft/fluentui-system-icons/)
- [WinUI 3 Gallery](https://github.com/microsoft/WinUI-Gallery)

### Contributors
Contributions are welcome! Please read the [contribution guidelines](./CONTRIBUTING.md) before submitting a pull request.

Thanks to the great people who contributed to this project.
[![Contributors](http://contrib.nn.ci/api?repo=rinlit-233-shiroko/Rin-UI)](https://github.com/RinLit-233-shiroko/Rin-UI/graphs/contributors)

## 📜 License
This project is licensed under the **MIT** License, you can learn more about it in the [license file](./LICENSE).

Copyright © 2025 RinLit

##

This is an experimental project by Rin as a newcomer. Welcome to suggest and contribute to this project. ❤️
