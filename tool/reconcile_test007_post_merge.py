#!/usr/bin/env python3
from pathlib import Path

MERGE_SHA = "b7f858f9cac6c1a8c5b0d1f9058be599f9ce792c"
FINAL_RUN = "31380502193"
FINAL_ARTIFACT = "9059883319"
FINAL_ARTIFACT_SIZE = "80,633,608"
FINAL_ARTIFACT_SHA = "76756ff72098c353f676ffd18008e253a2c1532da88208d8f3730b19b92c3e70"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one match, found {count}")
    return text.replace(old, new, 1)


def update_status() -> None:
    path = Path("docs/STATUS.md")
    text = path.read_text(encoding="utf-8")
    replacements = [
        (
            "| Primary feature | `TEST-007` Integration and end-to-end critical path — VERIFIED on Issue #181 / PR #184 pending merge. |",
            "| Primary feature | None — `TEST-007` Integration and end-to-end critical path is VERIFIED and merged; run the dependency-ready scan before starting the next single primary workstream. |",
            "STATUS primary feature",
        ),
        (
            "| Completed checkpoint | `TEST-007` critical path — 50/50 release checkpoints VERIFIED by Flutter CI #810 / run `31379676066` on implementation head `4882ac1b9449fb399ea3456ce89fa460dcfbcb98`; debug artifact #9059551183 passed artifact-security and upload. |",
            f"| Completed checkpoint | `TEST-007` critical path — 50/50 release checkpoints VERIFIED; final-head Flutter CI #816 / run `{FINAL_RUN}` passed all gates on `874fe658456723c5f0455e6c1935bd5b9dada8b5`, and PR #184 squash-merged as `{MERGE_SHA}`. |",
            "STATUS completed checkpoint",
        ),
        (
            "| Status | TEST-007 is VERIFIED at implementation head: the 50-checkpoint deterministic offline contract covers first run, guarded navigation, completion/reward idempotency, shop recovery, restart/restore, EN/AR RTL, responsive surfaces, and CI drift protection; PR #184 remains to be merged. |",
            "| Status | TEST-007 is VERIFIED and on `main`: the deterministic 50-checkpoint offline contract covers first run, guarded navigation, completion/reward idempotency, shop recovery, restart/restore, EN/AR RTL, responsive surfaces, and CI drift protection. |",
            "STATUS status",
        ),
        (
            "| Next recommended feature | Merge verified PR #184, then run the catalog dependency-ready scan and select exactly one next workstream. |",
            "| Next recommended feature | Run the catalog dependency-ready scan and select exactly one next workstream; preserve the verified TEST-007 gate in normal Flutter CI. |",
            "STATUS next feature",
        ),
        (
            "- Repository-owned TEST-007 acceptance is VERIFIED; PR #184 remains the only merge step before this checkpoint lands on `main`.",
            f"- Repository-owned TEST-007 acceptance is VERIFIED. Final-head Flutter CI #816 / run `{FINAL_RUN}` passed all 43 workflow steps, including Debug APK build, artifact security, and upload; artifact #{FINAL_ARTIFACT} is {FINAL_ARTIFACT_SIZE} bytes with SHA-256 `{FINAL_ARTIFACT_SHA}`. PR #184 squash-merged to `main` as `{MERGE_SHA}`, and Issue #181 closed completed.",
            "STATUS TEST-007 final evidence",
        ),
    ]
    for old, new, label in replacements:
        text = replace_once(text, old, new, label)
    path.write_text(text, encoding="utf-8")


def update_catalog() -> None:
    path = Path("docs/FEATURE_CATALOG.md")
    text = path.read_text(encoding="utf-8")
    old = "| TEST-007 | Integration and end-to-end critical path | P0 | VERIFIED | TEST-001, TEST-003 | Issue #181 / PR #184 add an executable 50-checkpoint release contract for first-run state, Home -> World Map -> Mission Briefing -> Gameplay, completion/result, reward idempotency, shop transaction recovery, restart/restore, EN/AR RTL, representative viewports, offline determinism, and CI drift protection. Flutter CI #810 / run `31379676066` passed the TEST-007 validator, six validator regressions, formatting, Analyze, focused TEST-007, full Flutter suite, Debug APK, artifact security, and upload on implementation head `4882ac1b9449fb399ea3456ce89fa460dcfbcb98`; artifact #9059551183 is 80,633,604 bytes with SHA-256 `283bf954510ac7eec6cb78e36f58995157379b3afe923b2af524003d3a4b415b`. |"
    new = f"| TEST-007 | Integration and end-to-end critical path | P0 | VERIFIED | TEST-001, TEST-003 | Issue #181 / PR #184 establish the executable 50-checkpoint release contract for first-run state, Home -> World Map -> Mission Briefing -> Gameplay, completion/result, reward idempotency, shop transaction recovery, restart/restore, EN/AR RTL, representative viewports, offline determinism, and CI drift protection. Implementation CI #810 / run `31379676066` passed the focused contract and full suite; final-head Flutter CI #816 / run `{FINAL_RUN}` passed all 43 steps on `874fe658456723c5f0455e6c1935bd5b9dada8b5`, including Debug APK build, artifact security, and upload. Final PR artifact #{FINAL_ARTIFACT} is {FINAL_ARTIFACT_SIZE} bytes with SHA-256 `{FINAL_ARTIFACT_SHA}`. PR #184 squash-merged as `{MERGE_SHA}` and Issue #181 closed completed. |"
    text = replace_once(text, old, new, "TEST-007 catalog row")
    path.write_text(text, encoding="utf-8")


def update_work_doc() -> None:
    path = Path("docs/work/TEST-007.md")
    text = path.read_text(encoding="utf-8")
    old = "- The tracking-only reconciliation that follows the implementation head changes no production behavior; final-head Flutter CI is required before PR #184 is marked ready and merged."
    new = f"- Final-head Flutter CI #816 / run `{FINAL_RUN}` passed all 43 workflow steps on `874fe658456723c5f0455e6c1935bd5b9dada8b5`, including the TEST-007 validator/regressions, formatting, Analyze, focused TEST-007, full Flutter suite, Debug APK, packaged-artifact security, and upload. Final PR artifact #{FINAL_ARTIFACT} is {FINAL_ARTIFACT_SIZE} bytes with SHA-256 `{FINAL_ARTIFACT_SHA}`. PR #184 squash-merged to `main` as `{MERGE_SHA}` and Issue #181 closed completed."
    text = replace_once(text, old, new, "TEST-007 work final evidence")
    path.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    update_status()
    update_catalog()
    update_work_doc()
    print("TEST-007 post-merge tracking reconciled.")
