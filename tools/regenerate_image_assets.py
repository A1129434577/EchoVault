#!/usr/bin/env python3
import base64
import concurrent.futures
import json
import os
import subprocess
import tempfile
import time
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
IMAGE_ROOT = ROOT / "assets/images"
STAGING = Path("/tmp/echovault_image_regeneration")
API_URL = "https://api.euzhi.com/v1/images/generations"
EXCLUDED = {"feedback/rating_panel.png"}
WORKERS = 3

SUBJECTS = {
    "artist/artist_backdrop.png": "a subtle cool gray-blue translucent artist page header backdrop",
    "artist/nav_back_light.png": "a minimal white left chevron navigation icon",
    "artist/profile_avatar.png": "a clean generic circular user avatar silhouette in very pale blue-gray",
    "brand/app_logo.png": "the EchoVault app emblem: stylized coral and teal headphones surrounding vertical equalizer bars on a dark rounded-square field",
    "charts/charts_daily.png": "a close-up white electric guitar under cyan-blue concert lighting",
    "charts/charts_general.png": "a vinyl record playing on a turntable under deep cool blue lighting",
    "charts/charts_weekly.png": "a close-up piano keyboard under warm cinematic amber light",
    "collection/add_playlist_action.png": "a gray circular user silhouette with a small plus sign, representing add playlist",
    "collection/favorite.png": "a thin medium-gray outline heart",
    "collection/favorite_accent.png": "a thin vivid blue outline heart",
    "collection/favorite_active.png": "a filled coral-pink heart",
    "collection/favorite_light.png": "a thin white outline heart",
    "collection/favorite_prompt_active.png": "a filled coral-pink heart",
    "collection/list_add.png": "a minimal black plus symbol",
    "collection/list_artist.png": "a white user silhouette on a rounded purple-blue gradient square",
    "collection/list_delete.png": "a minimal black outline trash can",
    "collection/list_favorite.png": "a white heart on a rounded bright-blue gradient square",
    "collection/list_options.png": "three small horizontal gray dots",
    "collection/list_rename.png": "a black outline rounded square with a diagonal pencil",
    "collection/list_saved.png": "a white downward save arrow on a rounded cyan-teal gradient square",
    "collection/playlist_create.png": "a large black plus symbol centered on a pale blue rounded square",
    "collection/playlist_icon.png": "three short gray horizontal playlist lines with a small musical note",
    "collection/playlist_play.png": "a small white right-pointing play triangle",
    "collection/playlist_shuffle.png": "two crossing vivid-blue shuffle arrows",
    "collection/save_accent.png": "a vivid-blue download arrow entering a curved tray",
    "collection/save_control.png": "a medium-gray download arrow entering a curved tray",
    "collection/save_guide_backdrop.png": "a compact pale gray-blue rounded instructional callout panel with a small blue corner marker",
    "collection/save_guide_line.png": "a thin vertical gray guide line with a vivid-blue dot at the top",
    "collection/save_help.png": "a black download arrow entering a curved tray",
    "collection/save_prompt_active.png": "a vivid-blue check mark resting in a curved tray",
    "collection/saved_state.png": "a vivid-blue check mark resting in a curved tray",
    "common/dismiss.png": "a minimal black X close icon",
    "common/loader.png": "a twelve-segment circular black loading spinner",
    "common/options.png": "three tiny light-gray horizontal dots",
    "common/options_muted.png": "three tiny medium-gray horizontal dots",
    "common/settings.png": "a black outline gear with a small central circle",
    "common/user_icon.png": "a minimal black outline user bust icon",
    "feedback/rating_hand.png": "a soft 3D peach hand giving a thumbs-up with a pale blue cuff",
    "feedback/rating_star.png": "a rounded five-point star with a thin warm yellow outline and pale cream fill",
    "feedback/star_active.png": "a filled rounded five-point golden-yellow star",
    "media/album_placeholder.png": "a white musical note on a rounded sky-blue gradient square",
    "media/audio_note.png": "a soft glowing vivid-blue eighth note on a very pale blue rounded square",
    "media/audio_track.png": "a solid vivid-blue eighth note on a very pale blue rounded square",
    "media/overlay_play.png": "a dark charcoal right-pointing play triangle",
    "player/mini_next.png": "a black next-track icon: right-pointing triangle touching a vertical bar",
    "player/mini_next_disabled.png": "a muted light-gray next-track icon: right-pointing triangle touching a vertical bar",
    "player/mini_pause.png": "two black vertical rounded pause bars",
    "player/mini_play.png": "a solid black right-pointing play triangle",
    "player/pause_control.png": "two white rounded pause bars centered in a vivid-blue circle",
    "player/play_control.png": "a white right-pointing play triangle centered in a vivid-blue circle",
    "player/player_back.png": "a minimal medium-gray downward chevron",
    "player/player_backdrop.png": "a narrow translucent white rounded player panel",
    "player/repeat.png": "two black horizontal looping arrows forming a repeat symbol",
    "player/repeat_one.png": "two black horizontal looping arrows with a small numeral 1 in the center",
    "player/shuffle_active.png": "two crossing black shuffle arrows with a subtle vivid-blue accent",
    "player/shuffle_control.png": "two crossing black shuffle arrows",
    "player/skip_back.png": "a black previous-track icon: vertical bar and left-pointing triangle",
    "player/skip_back_disabled.png": "a muted light-gray previous-track icon: vertical bar and left-pointing triangle",
    "player/skip_forward.png": "a black next-track icon: right-pointing triangle and vertical bar",
    "player/skip_forward_disabled.png": "a muted light-gray next-track icon: right-pointing triangle and vertical bar",
    "prompts/favorite_prompt.png": "a thin black outline heart",
    "prompts/play_next_prompt.png": "a black outline play-next symbol with overlapping rounded shapes",
    "prompts/playlist_add_prompt.png": "a black outline circular music-note icon with a small plus sign",
    "prompts/queue_add_prompt.png": "three black horizontal queue lines with a small play triangle",
    "prompts/save_prompt.png": "a black download arrow entering a curved tray",
    "search/history_delete.png": "a light-gray outline trash can",
    "search/history_search.png": "a light-gray magnifying glass with a tiny clock face inside",
    "search/search_backdrop.png": "a wide very-light-gray rounded search field background",
    "search/search_clear.png": "a small dark-gray X centered in a pale gray circle",
    "search/search_row.png": "a medium-gray magnifying glass",
    "shell/app_backdrop.png": "a tall translucent white application surface with a faint icy-blue glow near the top",
    "shell/nav_back_dark.png": "a minimal black left chevron navigation icon",
    "shell/nav_back_light.png": "a minimal white left chevron navigation icon",
    "shell/options_icon.png": "a minimal medium-gray right chevron navigation icon",
    "shell/tab_collection.png": "a medium-gray outline rounded-square collection tab icon with a small heart",
    "shell/tab_collection_active.png": "a black outline rounded-square collection tab icon with a white heart and vivid-blue bottom highlight",
    "shell/tab_home.png": "a medium-gray outline home icon with a rounded roof and base",
    "shell/tab_home_active.png": "a black outline home icon with a vivid-blue filled lower section",
    "shell/tab_search.png": "a medium-gray magnifying glass with a subtle segmented circular detail",
    "shell/tab_search_active.png": "a black magnifying glass with a vivid-blue segmented circular detail",
    "status/completion_mark.png": "a black outline circle containing a clean check mark",
    "status/dialog_dismiss.png": "a minimal black X close icon",
    "status/empty_state_box.png": "a soft 3D open empty box in white and vivid blue with small floating blue flaps",
    "status/status_error.png": "a black X centered in a white circle",
    "status/status_success.png": "a black check mark centered in a white circle",
    "status/status_warning.png": "a black exclamation mark centered in a white circle",
    "update/update_backdrop.png": "a tall translucent white update panel with a soft pale-blue glow at the top",
    "update/update_badge.png": "a polished 3D golden notification bell tilted slightly, with two small orange ringing marks",
    "update/update_dismiss.png": "a pale-gray X close icon centered in a faint circular outline",
    "update/update_heading.png": "the exact two-line heading 'New' above 'Version' in bold italic black letters with a short vivid-blue underline accent",
}


def image_metadata(path: Path) -> tuple[tuple[int, int], bool]:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        alpha = rgba.getchannel("A")
        return image.size, alpha.getextrema()[0] < 255


def prompt_for(relative: str, size: tuple[int, int], transparent: bool) -> str:
    subject = SUBJECTS[relative]
    background = (
        "Keep the background fully transparent with clean antialiased edges."
        if transparent
        else "Preserve the asset as an opaque image with the described backdrop filling the canvas."
    )
    icon = max(size) <= 256
    style = (
        "Crisp production-ready mobile UI icon, exact geometry, consistent stroke weight, pixel-clean silhouette, restrained polish."
        if icon
        else "Polished premium mobile-app visual, refined lighting, material detail, smooth gradients, and clean edges."
    )
    layer_constraint = ""
    if "backdrop" in Path(relative).stem:
        layer_constraint = (
            "This asset is strictly an empty background layer. Render only the panel shape, tint, transparency, glow, or gradient described above. "
            "Absolutely no foreground icon, symbol, illustration, controls, labels, letters, words, numbers, logos, badges, or placeholder content. "
        )
    return (
        "Use case: stylized-concept. Asset type: EchoVault mobile application image resource. "
        f"Primary request: redraw and enhance {subject}. "
        f"Original target aspect ratio is {size[0]}:{size[1]}. {style} {background} "
        "Preserve the core subject, familiar symbol, orientation, composition, color role, visual hierarchy, and state meaning. "
        f"Change only rendering quality and texture refinement. {layer_constraint}Center the design with balanced padding suitable for the target aspect ratio. "
        "No extra objects, no decorative background, no border, no watermark, and no text unless exact text is explicitly specified above."
    )


def resize_to_target(source: Path, destination: Path, size: tuple[int, int]) -> None:
    with Image.open(source) as image:
        image = image.convert("RGBA")
        target_ratio = size[0] / size[1]
        source_ratio = image.width / image.height
        if source_ratio > target_ratio:
            crop_width = round(image.height * target_ratio)
            left = (image.width - crop_width) // 2
            image = image.crop((left, 0, left + crop_width, image.height))
        elif source_ratio < target_ratio:
            crop_height = round(image.width / target_ratio)
            top = (image.height - crop_height) // 2
            image = image.crop((0, top, image.width, top + crop_height))
        image = image.resize(size, Image.Resampling.LANCZOS)
        destination.parent.mkdir(parents=True, exist_ok=True)
        image.save(destination, format="PNG", optimize=True)


def generate(relative: str) -> str:
    source = IMAGE_ROOT / relative
    destination = STAGING / relative
    if destination.exists():
        try:
            with Image.open(destination) as existing:
                if existing.size == image_metadata(source)[0]:
                    return f"cached {relative}"
        except Exception:
            destination.unlink(missing_ok=True)

    size, transparent = image_metadata(source)
    payload = {
        "model": "gpt-image-2",
        "prompt": prompt_for(relative, size, transparent),
        "size": "1024x1024",
        "quality": "medium",
        "n": 1,
    }
    destination.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(1, 4):
        with tempfile.TemporaryDirectory(prefix="echovault-image-") as temp_dir:
            response_path = Path(temp_dir) / "response.json"
            generated_path = Path(temp_dir) / "generated.png"
            command = [
                "curl",
                "--silent",
                "--show-error",
                "--fail-with-body",
                API_URL,
                "-H",
                f"Authorization: Bearer {os.environ['OPENAI_API_KEY']}",
                "-H",
                "Content-Type: application/json",
                "-d",
                json.dumps(payload, ensure_ascii=True),
                "-o",
                str(response_path),
            ]
            result = subprocess.run(command, capture_output=True, text=True)
            if result.returncode == 0:
                try:
                    response = json.loads(response_path.read_text())
                    generated_path.write_bytes(base64.b64decode(response["data"][0]["b64_json"]))
                    resize_to_target(generated_path, destination, size)
                    return f"generated {relative}"
                except Exception as error:
                    last_error = f"invalid response: {error}"
            else:
                body = response_path.read_text(errors="replace") if response_path.exists() else ""
                last_error = f"curl {result.returncode}: {result.stderr.strip()} {body[:300]}"
        time.sleep(attempt * 5)
    raise RuntimeError(f"{relative}: {last_error}")


def validate_and_install(files: list[str]) -> None:
    failures = []
    for relative in files:
        original_size, original_transparent = image_metadata(IMAGE_ROOT / relative)
        candidate = STAGING / relative
        if not candidate.exists():
            failures.append(f"missing {relative}")
            continue
        candidate_size, candidate_transparent = image_metadata(candidate)
        if candidate_size != original_size:
            failures.append(f"size mismatch {relative}: {candidate_size} != {original_size}")
        if original_transparent and not candidate_transparent:
            failures.append(f"alpha missing {relative}")
    if failures:
        raise RuntimeError("Validation failed:\n" + "\n".join(failures))
    for relative in files:
        destination = IMAGE_ROOT / relative
        destination.write_bytes((STAGING / relative).read_bytes())


def main() -> None:
    if not os.environ.get("OPENAI_API_KEY"):
        raise SystemExit("OPENAI_API_KEY is not set")
    files = sorted(str(path.relative_to(IMAGE_ROOT)) for path in IMAGE_ROOT.rglob("*.png"))
    files = [relative for relative in files if relative not in EXCLUDED]
    missing_prompts = sorted(set(files) - set(SUBJECTS))
    if missing_prompts:
        raise SystemExit("Missing subject descriptions: " + ", ".join(missing_prompts))
    STAGING.mkdir(parents=True, exist_ok=True)
    errors = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as executor:
        futures = {executor.submit(generate, relative): relative for relative in files}
        completed = 0
        for future in concurrent.futures.as_completed(futures):
            completed += 1
            relative = futures[future]
            try:
                print(f"[{completed}/{len(files)}] {future.result()}", flush=True)
            except Exception as error:
                errors.append(str(error))
                print(f"[{completed}/{len(files)}] FAILED {relative}: {error}", flush=True)
    if errors:
        raise SystemExit("Generation failed; originals were not changed:\n" + "\n".join(errors))
    validate_and_install(files)
    print(f"Installed {len(files)} validated assets", flush=True)


if __name__ == "__main__":
    main()
