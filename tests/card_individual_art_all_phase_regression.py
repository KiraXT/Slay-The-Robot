#!/usr/bin/env python3
"""Regression coverage for the all-phase manifest invariants."""

import copy
import importlib.util
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tests" / "card_individual_art_regression.py"


def load_module():
    spec = importlib.util.spec_from_file_location(
        "card_individual_art_regression_under_test", MODULE_PATH
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> None:
    module = load_module()
    altered_manifest = copy.deepcopy(module.load_manifest())
    replaced_card = altered_manifest["phases"]["pilot"][0]
    altered_manifest["phases"]["pilot"][0] = "card_debug_log"

    module.load_manifest = lambda: altered_manifest
    module.validate_cards = lambda card_ids: (_ for _ in ()).throw(
        AssertionError("validate_cards must not run for an invalid manifest")
    )

    try:
        module.validate_all()
    except AssertionError as error:
        assert "excluded development cards" in str(error), str(error)
    else:
        raise AssertionError(
            f"validate_all accepted an altered manifest replacing {replaced_card}"
        )

    print("ALL_TESTS_PASSED")


if __name__ == "__main__":
    main()
