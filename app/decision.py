from __future__ import annotations

import functools
from pathlib import Path
from typing import Any, Dict, List, Optional

import yaml

from .models import InteractionContext, StyleDecision


DEFAULT_CONFIG_PATH = Path(__file__).resolve().parent.parent / "configs" / "style_rules.yaml"


def _load_config(path: Optional[Path] = None) -> Dict[str, Any]:
    cfg_path = path or DEFAULT_CONFIG_PATH
    if not cfg_path.exists():
        raise FileNotFoundError(f"Style rules config not found at {cfg_path}")
    with cfg_path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


@functools.lru_cache()
def get_config() -> Dict[str, Any]:
    """Load and cache the YAML config."""
    return _load_config()


def decide_style(context: InteractionContext, config: Optional[Dict[str, Any]] = None) -> StyleDecision:
    """Return a style decision based on the given context and rules config.

    Rules are evaluated in order; the first rule whose non-null conditions all match the
    provided context is selected.
    """
    rules: List[Dict[str, Any]] = (config or get_config()).get("strategies", [])

    ctx_dict = context.model_dump(exclude_none=True)

    for idx, rule in enumerate(rules):
        conds: Dict[str, str] = rule.get("conditions", {}) or {}
        # Check if all specified condition keys match the context values
        if all(ctx_dict.get(key) == value for key, value in conds.items()):
            style = rule.get("style", "hybrid")
            return StyleDecision(style=style, matched_rule_index=idx)

    # Fallback if no rule matched (shouldn't happen if config has default)
    return StyleDecision(style="hybrid", matched_rule_index=-1)