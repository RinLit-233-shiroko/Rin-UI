import logging
from pathlib import Path
from typing import Optional, Union


LOGGER_NAME = "RinUI"

logger = logging.getLogger(LOGGER_NAME)
logger.addHandler(logging.NullHandler())


def get_logger(name: Optional[str] = None) -> logging.Logger:
    """Return a namespaced RinUI logger."""
    if name:
        return logging.getLogger(f"{LOGGER_NAME}.{name}")
    return logger


def configure_logging(
    level: Union[int, str] = "INFO",
    log_file: Optional[Union[str, Path]] = None,
) -> logging.Logger:
    """Enable RinUI logging explicitly.

    By default the library is silent. Applications opt in by calling this
    function, or by configuring Python's root logger themselves.
    """
    logger.setLevel(level)
    logger.propagate = False
    if any(getattr(handler, "_rinui_handler", False) for handler in logger.handlers):
        return logger

    if log_file is not None:
        handler: logging.Handler = logging.FileHandler(
            str(log_file), encoding="utf-8"
        )
    else:
        handler = logging.StreamHandler()

    handler.setFormatter(
        logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s")
    )
    handler._rinui_handler = True
    logger.addHandler(handler)
    return logger
