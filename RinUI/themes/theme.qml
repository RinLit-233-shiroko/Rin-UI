pragma Singleton
import QtQuick 2.15

Item {
    id: themeManager

    property var currentTheme: null
    readonly property var mode: ({
        Light: "Light",
        Dark: "Dark",
        Auto: "Auto"
    })
    readonly property var light: Qt.createQmlObject("import '../themes'; Light {}", themeManager)
    readonly property var dark: Qt.createQmlObject("import '../themes'; Dark {}", themeManager)

    readonly property var effect: ({
        Mica: "mica",
        Acrylic: "acrylic",
        Tabbed: "tabbed",
        None: "none"
    })

    // 初始化时设置默认主题
    Component.onCompleted: {
        if (typeof ThemeManager === "undefined") {
            currentTheme = Qt.createQmlObject("import '../themes'; Light {}", themeManager)
        } else {
            Utils.primaryColor = getThemeColor()
            setTheme(ThemeManager.get_theme_name())
        }
    }

    function _isThemeMgrInitialized() {
        return typeof ThemeManager!== "undefined"
    }

    function isDark() {
        return currentTheme.isDark
    }

    function setBackdropEffect(effect) {
        if (!_isThemeMgrInitialized()) {
            console.error("ThemeManager is not defined.")
            return -1
        }
        ThemeManager.apply_backdrop_effect(effect)
    }

    function getBackdropEffect() {
        if (!_isThemeMgrInitialized()) {
            console.error("ThemeManager is not defined.")
            return -1
        }
        return ThemeManager.get_backdrop_effect()
    }

    function setThemeColor(color) {
        if (!_isThemeMgrInitialized()) {
            console.error("ThemeManager is not defined.")
            return
        }

        var hex = null

        if (typeof color === "string") {
            hex = color
        }

        else if (typeof color === "object" && color.r !== undefined) {
            hex = color.toString()
        }
        else {
            console.error("Invalid color format:", color)
            return
        }

        Utils.primaryColor = hex
        ThemeManager.set_theme_color(hex)
    }

    function getThemeColor() {
        if (!_isThemeMgrInitialized())
            return "transparent"

        let hex = ThemeManager.get_theme_color()

        if (typeof hex !== "string" || hex.length < 6)
            return "transparent"

        let color = Qt.color(hex)
        if (color === undefined)
            return "transparent"

        return color
    }

    function getTheme() {
        if (!_isThemeMgrInitialized()) {
            console.error("ThemeManager is not defined.")
            return -1
        }
        return ThemeManager.get_theme_name()
    }

    function toggleMode() {
        if (!_isThemeMgrInitialized()) {
            console.error("ThemeManager is not defined.")
            return -1
        }
        let theme_mode;
        if (!currentTheme.isDark) {
            theme_mode = mode.Dark
        } else {
            theme_mode = mode.Light
        }
        setTheme(theme_mode)
    }

    // 切换主题
    function setTheme(theme_mode) {
        if (!_isThemeMgrInitialized()) {
            console.error("ThemeManager is not defined.")
            currentTheme = Qt.createQmlObject("import '../themes'; Light {}", themeManager)
            return
        }
        if (theme_mode !== mode.Dark && theme_mode !== mode.Light && theme_mode !== mode.Auto) {
            console.error("Invalid theme mode.")
            return
        }
        ThemeManager.toggle_theme(theme_mode)

        // 获取实际的主题名称
        var themeName = ThemeManager.get_theme_name()
        if (themeName === mode.Auto) {
            themeName = ThemeManager.get_theme()
        }
        load_qml(themeName)
    }

    function load_qml(themeName) {
        if (themeName) {
            let themeObject
            if (themeName === "Light") {
                themeObject = light
            } else if (themeName === "Dark") {
                themeObject = dark
            } else {
                console.error("Invalid theme name:", themeName)
                return
            }
            if (themeObject) {
                currentTheme = themeObject
                // console.log("Switched to", mode, "mode")
            } else {
                console.error("Failed to create theme object for mode:", themeName)
            }
        } else {
            console.error("Invalid theme mode:", themeName)
        }
    }

    // 监听系统主题变化
    Connections {
        target: ThemeManager
        function onThemeChanged(theme) {
            load_qml(theme)
        }
        function onBackdropChanged(effect) {
            Utils.backdropEnabled = effect !== "none";
        }
    }
}
