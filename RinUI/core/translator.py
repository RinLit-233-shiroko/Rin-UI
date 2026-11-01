from pathlib import Path

from PySide6.QtCore import QLocale, QTranslator

from .config import RINUI_PATH
from .logger import logger


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
        logger.debug("Current locale: %s", locale.name())
        path = Path(RINUI_PATH) / "RinUI" / "languages" / f"{locale.name()}.qm"
        if not path.exists():
            logger.warning(
                'Language file "%s" not found; falling back to en_US.', path
            )
            path = Path(RINUI_PATH) / "RinUI" / "languages" / "en_US.qm"
            QLocale().setDefault(QLocale("en_US"))

        QLocale().setDefault(locale)
        return super().load(str(path))
