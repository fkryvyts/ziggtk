# ziggtk
Image viewer written in Zig and GTK4

Partial reimplementation of [Gnome Loupe](https://github.com/GNOME/loupe)

## Dependencies:

- [Libgoimagex](https://github.com/fkryvyts/libgoimagex) - required for loading GIFs
- [GTK 4](https://docs.gtk.org/gtk4/)
- [Adwaita](https://gnome.pages.gitlab.gnome.org/libadwaita/)

## Useful commands

Install dev dependencies:
```bash
sudo apt install libgtk-4-dev
sudo apt install libadwaita-1-dev
```

Check libraries required by the binary:
```bash
readelf -d app
```
