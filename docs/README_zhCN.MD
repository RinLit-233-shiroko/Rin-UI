<div align="center">
<img src="../docs/img/logo.png" alt="RinUI Logo" width="18%">
<h1>RinUI</h1>
<p>一个类 Fluent Design 的 Qt Quick (QML) UI 库</p>

**中文** | [English](../README.MD)

</div>

> [!TIP]
> 该项目仍在开发中，尚未准备好用于生产环境！
> 
> 当然，欢迎你为这个项目做出贡献。

## 📄 介绍

RinUI 是一个类 Fluent Design 的 Qt Quick (QML) UI 库，RinUI 将提供高品质的组件和实用功能，
仅需简单配置，即可快速开发出优雅的 Fluent 风格的 UI 界面。

### 特性
* 优雅的 Fluent Design 控件（WIP）
* 深浅色模式以及自动切换主题
* 兼容原版 QML 控件名
* 多语言支持（WIP）
* 完善的主题系统（WIP）
* 在线开发文档，[在此](https://ui.rinlit.cn/zh)预览（WIP）

### 截图展示
![Screenshot 1](/docs/img/shot_1.png)

<details style="text-align: center">
<summary>更多截图...</summary>

![img.png](/docs/img/img.png)
![img_1.png](/docs/img/img_1.png)
![img_2.png](/docs/img/img_2.png)
![img_3.png](/docs/img/img_3.png)
</details>

## 🪄 使用方法

你可以通过 pip 安装 RinUI：
```bash
pip install RinUI

# ↓ Test PyPI
pip install PySide6 darkdetect  # 在 TestPypi 中这两个包没有 Release，当 RinUI 发布到 PyPi 时，即可省略此步骤。
pip install -i https://test.pypi.org/simple/ RinUI --no-deps
```
在你的 QML 文件中导入 RinUI：

```qmllang
import "./RinUI"
```

你还可以在源码中查看示例，如下所示：

```bash
cd examples
python gallery.py
```

你也可以将 RinUI 文件夹移动到你的项目目录中的任意位置。

> [!NOTE] 
> 文档仍在编写中!! 
> 目前，你可以查看源码来了解组件和主题的详细信息。
> RinUI 的大多数组件都是对 Qml 的原生控件的封装，所以仅需简单配置即可让您的原生 Qml 项目迁移。

现在您可以在 [RinUI 开发文档](https://ui.rinlit.cn/zh) 中了解 RinUI 组件和主题的详细信息。

## 🙌 致谢
### 资源
- [PySide6 & Qt Quick](https://www.qt.io/)
- [Fluent Design System](https://fluent2.microsoft.design/)
- [Fluent UI System Icons](https://github.com/microsoft/fluentui-system-icons/)
### 贡献者
欢迎贡献！在提交拉取请求之前，请阅读[贡献指南](./CONTRIBUTING.md)。 

感谢为本项目做出贡献的优秀开发者们。
[![Contributors](http://contrib.nn.ci/api?repo=rinlit-233-shiroko/Rin-UI)](https://github.com/RinLit-233-shiroko/Rin-UI/graphs/contributors)

## 📜 许可证
本项目采用 MIT 许可证，你可以在 许可证文件 中了解更多信息。
版权所有 © 2025 RinLit

##
这是 Rin 作为新人开发的实验性项目，欢迎提出建议并贡献代码 ❤️
