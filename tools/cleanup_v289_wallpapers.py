"""Remove retired Fanatika v2.8.8 wallpaper assets after applying the v2.8.9 patch.

Run from anywhere: python3 tools/cleanup_v289_wallpapers.py
Only the five named files are removed, never Arc Favorites or user data.
"""
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
RETIRED = (
    "07_Bansko_Pirin.jpg",
    "08_Pirin_River.jpg",
    "09_Mountain_River.jpg",
    "10_Bansko_Winter.jpg",
    "11_Pirin_Alpine_Lake.jpg",
)


def main():
    wallpapers = PROJECT / "assets" / "mountains"
    if not wallpapers.is_dir():
        raise SystemExit("Wallpaper directory not found. Run from the Fanatika launcher project.")
    for filename in RETIRED:
        target = wallpapers / filename
        if target.is_symlink():
            raise SystemExit(f"Refusing to follow unexpected symlink: {target}")
        if target.is_file():
            target.unlink()
            print(f"Removed obsolete wallpaper: {target.relative_to(PROJECT)}")
    print("Fanatika v2.8.9 wallpaper migration complete.")


if __name__ == "__main__":
    main()
