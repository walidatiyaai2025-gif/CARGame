#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "test/features/home/home_environment_responsive_test.dart": (
        "Size(360, 640)",
        "Size(412, 915)",
        "Size(1024, 1366)",
        "Locale('ar')",
        "AppLocalizations.localizationsDelegates",
        "TextDirection.rtl",
    ),
    "test/features/levels/level_select_responsive_test.dart": (
        "Size(360, 640)",
        "Size(412, 915)",
        "Size(1024, 1366)",
        "Locale('ar')",
        "TextDirection.rtl",
    ),
    "test/features/levels/city_briefing_responsive_test.dart": (
        "Size(360, 640)",
        "Size(412, 915)",
        "Size(1024, 1366)",
        "Locale('ar')",
        "TextDirection.rtl",
    ),
    "test/features/game/game_screen_responsive_test.dart": (
        "Size(360, 640)",
        "Size(412, 915)",
        "Size(1024, 1366)",
        "Locale('ar')",
        "AppLocalizations.localizationsDelegates",
        "TextDirection.rtl",
    ),
    "test/features/game/game_result_responsive_test.dart": (
        "Size(360, 640)",
        "Size(412, 915)",
        "Size(1024, 1366)",
        "Locale('ar')",
        "AppLocalizations.localizationsDelegates",
        "GameplayResultDebrief",
        "إعادة المحاولة",
        "TextDirection.rtl",
    ),
    "test/features/shop/shop_responsive_test.dart": (
        "Size(360, 640)",
        "Size(412, 915)",
        "Size(1024, 1366)",
        "Locale('ar')",
        "AppLocalizations.localizationsDelegates",
        "TextDirection.rtl",
    ),
}


def fail(errors: list[str]) -> None:
    print("TEST-003 core screen widget matrix FAILED:")
    for error in errors:
        print(f" - {error}")
    raise SystemExit(1)


def main() -> None:
    errors: list[str] = []

    for relative_path, anchors in REQUIRED.items():
        path = ROOT / relative_path
        if not path.is_file():
            errors.append(f"missing required widget test: {relative_path}")
            continue

        text = path.read_text(encoding="utf-8")
        if "tester.takeException()" not in text:
            errors.append(f"{relative_path} must assert uncaught widget exceptions")

        for anchor in anchors:
            if anchor not in text:
                errors.append(f"{relative_path} is missing matrix anchor: {anchor}")

    catalog = (ROOT / "docs/FEATURE_CATALOG.md").read_text(encoding="utf-8")
    if "| TEST-003 | Core screen widget tests | P1 |" not in catalog:
        errors.append("FEATURE_CATALOG lost TEST-003")

    if errors:
        fail(errors)

    print(
        "TEST-003 core screen widget matrix: OK "
        f"({len(REQUIRED)} screen families, compact/reference/tablet + EN/AR anchors)"
    )


if __name__ == "__main__":
    main()
