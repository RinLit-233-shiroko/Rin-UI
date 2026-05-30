from pathlib import Path

from PySide6.QtCore import QLocale, QTranslator

from .config import RINUI_PATH


class RinUITranslator(QTranslator):
    """
    RinUI i18n translator.
    :param locale: QLocale, optional, default is system locale
    """

    def __init__(
        self, locale: QLocale = QLocale.system().name(), parent=None
    ):  # follow system
        super().__init__(parent)
        self.load(locale or QLocale())

    def load(self, locale: QLocale) -> bool:
        """
        Load translation file for the given locale.
        :param locale: QLocale, the locale to load (eg = QLocale(QLocale.Chinese, QLocale.China), QLocale("zh_CN"))
        :return: bool
        """
        print(f"🌏 Current locale: {locale.name()}")
        path = Path(RINUI_PATH) / "RinUI" / "languages" / f"{locale.name()}.qm"
        if path.exists():
            QLocale().setDefault(locale)
            return super().load(str(path))
        lang = locale.name().split("_")[0]
        lang_path = Path(RINUI_PATH) / "RinUI" / "languages" / f"{lang}.qm"
        if lang_path.exists():
            QLocale().setDefault(locale)
            return super().load(str(lang_path))
        fallback_path = Path(RINUI_PATH) / "RinUI" / "languages" / "en_US.qm"
        print(f'Language file "{locale.name()}" not found. Falling back to en_US')
        QLocale().setDefault(QLocale("en_US"))
        return super().load(str(fallback_path))
