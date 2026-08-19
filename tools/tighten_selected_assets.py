from pathlib import Path

from PIL import Image


ROOT = Path("assets/images")
TARGETS = [
    "artist/nav_back_light.png",
    "collection/list_artist.png",
    "collection/list_favorite.png",
    "collection/list_options.png",
    "collection/list_saved.png",
    "common/options_muted.png",
    "player/player_back.png",
    "shell/nav_back_dark.png",
    "shell/nav_back_light.png",
    "shell/options_icon.png",
]


for relative in TARGETS:
    path = ROOT / relative
    with Image.open(path) as source:
        image = source.convert("RGBA")
        bbox = image.getchannel("A").getbbox()
        if not bbox:
            continue
        left, top, right, bottom = bbox
        cropped = image.crop((max(0, left - 2), max(0, top - 2), min(image.width, right + 2), min(image.height, bottom + 2)))
        scale = min((image.width - 4) / cropped.width, (image.height - 4) / cropped.height)
        size = (round(cropped.width * scale), round(cropped.height * scale))
        resized = cropped.resize(size, Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
        canvas.alpha_composite(resized, ((image.width - size[0]) // 2, (image.height - size[1]) // 2))
        canvas.save(path, "PNG", optimize=True)
        print(relative, image.size, "->", size)
