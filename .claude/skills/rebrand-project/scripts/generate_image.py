"""
Generate a new image using Gemini API with an optional reference image.

Usage:
  # With reference image (product photos, hero shots, lifestyle):
  python generate_image.py --reference img.png --prompt "Product photo, white background" --output out.png

  # Without reference (avatars, backgrounds, icons):
  python generate_image.py --prompt "Professional headshot portrait" --output out.png

  # With specific dimensions (resizes output to exact WxH):
  python generate_image.py --reference img.png --prompt "..." --output out.png --width 800 --height 600
"""

import argparse
import os
import sys
from pathlib import Path

from google import genai
from google.genai import types
from PIL import Image


MODEL = "gemini-3.1-flash-image-preview"


def get_aspect_ratio(width: int, height: int) -> str:
    """Pick the closest supported aspect ratio for the given dimensions."""
    ratio = width / height
    options = [
        (1.0, "1:1"),
        (4 / 5, "4:5"),
        (5 / 4, "5:4"),
        (3 / 4, "3:4"),
        (4 / 3, "4:3"),
        (9 / 16, "9:16"),
        (16 / 9, "16:9"),
    ]
    best = min(options, key=lambda x: abs(x[0] - ratio))
    return best[1]


def generate(
    prompt: str,
    output_path: Path,
    reference_path: Path | None = None,
    width: int | None = None,
    height: int | None = None,
) -> None:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise EnvironmentError("GEMINI_API_KEY environment variable not set")

    if reference_path and not reference_path.exists():
        raise FileNotFoundError(f"Reference image not found: {reference_path}")

    # Build contents
    contents: list = []
    if reference_path:
        ref_image = Image.open(reference_path)
        contents.append(ref_image)
        full_prompt = (
            "Use the attached reference image as the base product reference. "
            "Preserve the product's core identity, shape, materials, colors, "
            "branding cues, and overall visual recognizability.\n\n"
            f"{prompt}"
        )
    else:
        full_prompt = prompt
    contents.append(full_prompt)

    # Determine aspect ratio
    aspect = "1:1"
    if width and height:
        aspect = get_aspect_ratio(width, height)

    client = genai.Client(api_key=api_key)
    response = client.models.generate_content(
        model=MODEL,
        contents=contents,
        config=types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"],
            image_config=types.ImageConfig(
                aspect_ratio=aspect,
                image_size="2K",
            ),
        ),
    )

    saved = False
    for part in response.parts:
        if part.text:
            print(part.text)
        elif part.inline_data:
            image = part.as_image()
            output_path.parent.mkdir(parents=True, exist_ok=True)
            image.save(output_path)
            saved = True
            print(f"OK: {output_path}")

    if not saved:
        raise RuntimeError("No image was returned by the model.")

    # Resize to exact dimensions if specified
    if saved and width and height:
        img = Image.open(output_path)
        img = img.resize((width, height), Image.LANCZOS)
        img.save(output_path)
        print(f"Resized to {width}x{height}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate image via Gemini API")
    parser.add_argument("--reference", type=str, help="Path to reference image")
    parser.add_argument("--prompt", type=str, required=True, help="Generation prompt")
    parser.add_argument("--output", type=str, required=True, help="Output image path")
    parser.add_argument("--width", type=int, help="Target width in pixels")
    parser.add_argument("--height", type=int, help="Target height in pixels")
    args = parser.parse_args()

    generate(
        prompt=args.prompt,
        output_path=Path(args.output),
        reference_path=Path(args.reference) if args.reference else None,
        width=args.width,
        height=args.height,
    )


if __name__ == "__main__":
    main()
