cd ..
.venv\Scripts\pyinstaller.exe ^
  --icon=examples/assets/icons/app/gallery.ico ^
  --noconsole ^
  --contents-directory="." ^
  --add-data="RinUI;RinUI" ^
  --add-data="examples/assets;assets" ^
  --add-data="examples/components;components" ^
  --add-data="examples/languages;languages" ^
  --add-data="examples/pages;pages" ^
  --add-data="examples/gallery.qml;." ^
  --paths=. ^
  examples/gallery.py
