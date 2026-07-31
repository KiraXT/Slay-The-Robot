#!/usr/bin/env python3
"""Repository-owned chroma-key processing for the card-art pipeline."""

from __future__ import annotations

import re

from PIL import Image, ImageFilter


Color = tuple[int, int, int]
KEY_DOMINANCE_THRESHOLD = 16.0
ALPHA_NOISE_FLOOR = 8


def _parse_key_color(raw: str) -> Color:
    match = re.fullmatch(r"#?([0-9a-fA-F]{6})", raw.strip())
    if not match:
        raise ValueError("key color must be a hex RGB value like #00ff00")
    value = match.group(1)
    return tuple(int(value[index:index + 2], 16) for index in (0, 2, 4))


def _channel_distance(a: Color, b: Color) -> int:
    return max(abs(a[index] - b[index]) for index in range(3))


def _clamp_channel(value: float) -> int:
    return max(0, min(255, int(round(value))))


def _smoothstep(value: float) -> float:
    value = max(0.0, min(1.0, value))
    return value * value * (3.0 - 2.0 * value)


def _soft_alpha(
    distance: int,
    transparent_threshold: float,
    opaque_threshold: float,
) -> int:
    if distance <= transparent_threshold:
        return 0
    if distance >= opaque_threshold:
        return 255
    ratio = (distance - transparent_threshold) / (
        opaque_threshold - transparent_threshold
    )
    return _clamp_channel(255.0 * _smoothstep(ratio))


def _spill_channels(key: Color) -> list[int]:
    key_max = max(key)
    if key_max < 128:
        return []
    return [
        index
        for index, value in enumerate(key)
        if value >= key_max - 16 and value >= 128
    ]


def _dominance_alpha(rgb: Color, key: Color) -> int:
    spill_channels = _spill_channels(key)
    if not spill_channels:
        return 255

    channels = [float(value) for value in rgb]
    non_spill = [index for index in range(3) if index not in spill_channels]
    key_strength = (
        min(channels[index] for index in spill_channels)
        if len(spill_channels) > 1
        else channels[spill_channels[0]]
    )
    non_key_strength = max(
        (channels[index] for index in non_spill),
        default=0.0,
    )
    dominance = key_strength - non_key_strength
    if dominance <= 0:
        return 255

    denominator = max(1.0, float(max(key)) - non_key_strength)
    alpha = 1.0 - min(1.0, dominance / denominator)
    return _clamp_channel(alpha * 255.0)


def _key_channel_dominance(rgb: Color, key: Color) -> float:
    spill_channels = _spill_channels(key)
    if not spill_channels:
        return 0.0

    channels = [float(value) for value in rgb]
    non_spill = [index for index in range(3) if index not in spill_channels]
    key_strength = (
        min(channels[index] for index in spill_channels)
        if len(spill_channels) > 1
        else channels[spill_channels[0]]
    )
    non_key_strength = max(
        (channels[index] for index in non_spill),
        default=0.0,
    )
    return key_strength - non_key_strength


def _looks_key_colored(rgb: Color, key: Color, distance: int) -> bool:
    if distance <= 32:
        return True
    if not _spill_channels(key):
        return True
    return _key_channel_dominance(rgb, key) >= KEY_DOMINANCE_THRESHOLD


def _cleanup_spill(rgb: Color, key: Color, alpha: int) -> Color:
    if alpha >= 252:
        return rgb

    spill_channels = _spill_channels(key)
    if not spill_channels:
        return rgb

    channels = [float(value) for value in rgb]
    non_spill = [index for index in range(3) if index not in spill_channels]
    if non_spill:
        cap = max(0.0, max(channels[index] for index in non_spill) - 1.0)
        for index in spill_channels:
            channels[index] = min(channels[index], cap)
    return tuple(_clamp_channel(value) for value in channels)


def _apply_alpha(
    image: Image.Image,
    *,
    key: Color,
    transparent_threshold: float,
    opaque_threshold: float,
    despill: bool,
) -> None:
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, source_alpha = pixels[x, y]
            rgb = (red, green, blue)
            distance = _channel_distance(rgb, key)
            key_like = _looks_key_colored(rgb, key, distance)
            output_alpha = (
                min(
                    _soft_alpha(
                        distance,
                        transparent_threshold,
                        opaque_threshold,
                    ),
                    _dominance_alpha(rgb, key),
                )
                if key_like
                else 255
            )
            output_alpha = int(round(output_alpha * (source_alpha / 255.0)))
            if 0 < output_alpha <= ALPHA_NOISE_FLOOR:
                output_alpha = 0
            if output_alpha == 0:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            if despill and key_like:
                red, green, blue = _cleanup_spill(rgb, key, output_alpha)
            pixels[x, y] = (red, green, blue, output_alpha)


def remove_chroma_key(
    image: Image.Image,
    key_color: str,
    *,
    transparent_threshold: float = 24.0,
    opaque_threshold: float = 90.0,
    edge_contract: int = 1,
    edge_feather: float = 0.7,
    despill: bool = True,
) -> Image.Image:
    """Return an RGBA image processed with the pipeline's fixed soft matte."""
    if not 0 <= transparent_threshold <= 255:
        raise ValueError("transparent threshold must be between 0 and 255")
    if not 0 <= opaque_threshold <= 255:
        raise ValueError("opaque threshold must be between 0 and 255")
    if transparent_threshold >= opaque_threshold:
        raise ValueError("transparent threshold must be lower than opaque threshold")
    if not 0 <= edge_contract <= 16:
        raise ValueError("edge contract must be between 0 and 16")
    if not 0 <= edge_feather <= 64:
        raise ValueError("edge feather must be between 0 and 64")

    rgba = image.convert("RGBA")
    _apply_alpha(
        rgba,
        key=_parse_key_color(key_color),
        transparent_threshold=transparent_threshold,
        opaque_threshold=opaque_threshold,
        despill=despill,
    )
    alpha = rgba.getchannel("A")
    for _ in range(edge_contract):
        alpha = alpha.filter(ImageFilter.MinFilter(3))
    if edge_feather:
        alpha = alpha.filter(ImageFilter.GaussianBlur(radius=edge_feather))
    rgba.putalpha(alpha)
    return rgba
