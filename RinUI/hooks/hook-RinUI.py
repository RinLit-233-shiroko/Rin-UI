from PyInstaller.utils.hooks import collect_data_files

datas = collect_data_files("RinUI", include_py_files=False)
