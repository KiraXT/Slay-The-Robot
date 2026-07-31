#!/usr/bin/env python3
"""Shared manifest contract helpers for card-art tools and validation."""

from __future__ import annotations

import re


EXPECTED_COLOR_IDS = frozenset(
    {
        "color_red",
        "color_blue",
        "color_green",
        "color_orange",
        "color_white",
        "color_purple",
    }
)
HEX_COLOR_PATTERN = re.compile(r"#[0-9a-f]{6}")
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")


def manifest_card_ids(manifest: dict) -> list[str]:
    return [
        card_id
        for phase_ids in manifest["phases"].values()
        for card_id in phase_ids
    ]


def validate_key_color_contract(
    manifest: dict,
    canonical_card_ids: list[str],
) -> tuple[dict[str, str], dict[str, str]]:
    contract = manifest.get("key_colors")
    assert isinstance(contract, dict), "manifest key_colors must be an object"
    defaults = contract.get("defaults")
    overrides = contract.get("overrides")
    assert isinstance(defaults, dict), "key-color defaults must be an object"
    assert isinstance(overrides, dict), "key-color overrides must be an object"
    assert set(defaults) == EXPECTED_COLOR_IDS, (
        "key-color defaults must contain exactly the six expected color IDs"
    )
    for color_id, value in (*defaults.items(), *overrides.items()):
        assert isinstance(value, str) and HEX_COLOR_PATTERN.fullmatch(value), (
            f"key color for {color_id} must be valid #rrggbb"
        )
    assert set(overrides) <= set(canonical_card_ids), (
        "key-color override IDs must be canonical card IDs"
    )
    return defaults, overrides


def validate_approved_digest_contract(
    manifest: dict,
    canonical_card_ids: list[str],
) -> dict[str, str]:
    approved = manifest.get("approved_rgba_sha256")
    assert isinstance(approved, dict), (
        "approved_rgba_sha256 must be an object"
    )
    assert set(approved) == set(canonical_card_ids), (
        "approved_rgba_sha256 must contain exactly one digest per canonical card ID"
    )
    for card_id, digest in approved.items():
        assert isinstance(digest, str) and SHA256_PATTERN.fullmatch(digest), (
            f"approved digest for {card_id} must be valid SHA-256 hex"
        )
    assert len(set(approved.values())) == len(approved), (
        "approved RGBA digests must be unique"
    )
    return approved


def key_color_for_card(
    manifest: dict,
    card_id: str,
    color_id: str,
) -> str:
    canonical_card_ids = manifest_card_ids(manifest)
    defaults, overrides = validate_key_color_contract(
        manifest,
        canonical_card_ids,
    )
    assert color_id in defaults, f"unknown card color ID: {color_id}"
    return overrides.get(card_id, defaults[color_id])
