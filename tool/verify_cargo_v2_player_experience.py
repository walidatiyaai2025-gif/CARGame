#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    target = ROOT / path
    if not target.is_file():
        raise AssertionError(f"missing required file: {path}")
    return target.read_text(encoding="utf-8")


def require(text: str, token: str, label: str) -> None:
    if token not in text:
        raise AssertionError(f"{label}: missing {token!r}")


def reject(text: str, token: str, label: str) -> None:
    if token in text:
        raise AssertionError(f"{label}: forbidden {token!r}")


def main() -> int:
    settings = read("Assets/_Project/Data/CargoV2PlayerSettings.cs")
    localization = read("Assets/_Project/Data/SCR_LocalizationManager.cs")
    terms = read("Assets/_Project/Data/CargoV2LocalizationTerms.cs")
    layout = read("Assets/_Project/UI/CargoV2UiLayout.cs")
    feedback = read("Assets/_Project/UI/SCR_PlayerFeedback.cs")
    experience = read("Assets/_Project/UI/SCR_PlayerExperienceRuntime.cs")
    mission = read("Assets/_Project/UI/SCR_MissionRuntimeDirector.cs")
    driving = read("Assets/_Project/UI/SCR_MissionRuntimeDirector.Driving.cs")
    hud = read("Assets/_Project/UI/SCR_MissionRuntimeDirector.Hud.cs")
    hq = read("Assets/_Project/UI/SCR_LogisticsBusinessRuntime.cs")
    touch = read("Assets/_Project/UI/SCR_WorldMapTouchInputBridge.cs")
    build = read("Assets/_Project/UI/Editor/SCR_CargoV2Build.cs")
    regression = read("Assets/_Project/QA/Editor/SCR_CargoV2PlayerExperienceRegression.cs")

    for token in (
        'cargo_v2_player_settings_v1',
        'cargo_v2_player_settings_corrupt_v1',
        'schemaVersion',
        'TryNormalize',
        'Quarantine(raw)',
        'ReducedMotion',
        'LargeText',
    ):
        require(settings, token, "settings")
    for forbidden in (
        'cargo_v2.progress.v1',
        'cargo_v2_mission_economy_v1',
        'cargo_v2_company_profile_v1',
        'cargo_v2_active_delivery_v1',
    ):
        reject(settings, forbidden, "settings isolation")

    for token in (
        'CargoV2PlayerSettings.Load()',
        'CargoV2PlayerSettings.TryUpdate(language:',
        'LocalizeDigits',
        "'٠'",
        'TextAnchor.MiddleRight',
    ):
        require(localization + experience + hud + hq, token, "localization")

    canonical_terms = (
        "Cairo Logistics Hub", "Giza Distribution Yard", "Nasr City Freight Hub",
        "New Cairo Logistics Park", "Cairo Airport Cargo", "Helwan Industrial Depot",
        "6th October Warehouse", "Obour Food Terminal", "Ain Sokhna Connector",
        "Alexandria Inland Link", "Cairo International Depot", "Dubai Logistics Hub",
        "Jebel Ali Container Yard", "Dubai South Logistics District", "Al Quoz Freight Terminal",
        "DXB Cargo Village", "Ras Al Khor Depot", "Dubai Industrial City",
        "Port Rashid Connector", "Dubai Investment Park", "JAFZA Heavy Cargo Gate",
        "Gulf International Depot", "General Freight", "Fresh Produce", "Electronics",
        "Industrial Machinery", "Medical Supplies", "Blue Container",
    )
    for token in canonical_terms:
        require(terms, token, "canonical Arabic route terms")

    for token in (
        'Screen.safeArea', 'ToGuiRect', 'MinimumTouchPixels = 84f',
        'BottomLeftTouch', 'BottomRightTouch', 'TopRightTouch', 'ClampToSafe',
    ):
        require(layout, token, "safe-area layout")

    for token in (
        'AudioClip.Create', 'CARGO_V2_Engine_Original', 'settings.MasterVolume',
        'settings.SfxVolume', 'settings.EngineVolume', 'settings.Haptics',
        'OnApplicationPause', 'OnApplicationFocus', 'Handheld.Vibrate()',
    ):
        require(feedback, token, "feedback")
    reject(feedback, 'Resources.Load<AudioClip>', "feedback licensing boundary")

    for token in (
        'OpenSettings()', 'OpenHelp()', 'TryHandleBack()', 'IsPointOverOverlay',
        'CargoV2UiLayout.SafeGuiRect', 'CargoV2PlayerSettings.TryUpdate',
    ):
        require(experience, token, "settings/help runtime")

    for token in (
        'Physics.SphereCastAll', 'QueryTriggerInteraction.Ignore',
        'playerSettings.ReducedMotion', 'ReturnToWorldMapFromResult()',
        'SCR_PlayerFeedback.StopEngine()',
    ):
        require(mission, token, "mission comfort/back")

    for token in (
        'Cue.Pickup', 'Cue.Checkpoint', 'Cue.Delivery', 'Cue.Impact',
        'ReturnToWorldMapFromResult', 'hud.truckDisabled',
    ):
        require(driving, token, "mission feedback")

    for forbidden in ('3D assets:', 'Keyboard: W/S', 'safe generated fallback active'):
        reject(hud, forbidden, "player HUD debug cleanup")
    for token in (
        'CargoV2UiLayout.SafeGuiRect', 'BottomLeftTouch', 'BottomRightTouch',
        'TopRightTouch', 'OpenSettings()', 'OpenHelp()', 'OnApplicationPause',
    ):
        require(hud, token, "responsive mission HUD")

    for token in (
        'public static bool IsPointOverUi', 'GetExpandedRect', 'GetCollapsedRect',
        'CargoV2UiLayout.SafeGuiRect', 'CargoV2LocalizationTerms.Term',
    ):
        require(hq, token, "HQ safe-area/input")
    for token in ('SCR_PlayerExperienceRuntime.IsPointOverOverlay', 'SCR_LogisticsBusinessRuntime.IsPointOverUi'):
        require(touch, token, "WorldMap touch exclusion")

    for token in (
        'SCR_CargoV2PlayerExperienceRegression.ValidateOrThrow()',
        'typeof(SCR_PlayerExperienceRuntime)', 'typeof(SCR_PlayerFeedback)',
    ):
        require(build, token, "Unity validation wiring")
    for token in (
        'PLAYER_EXPERIENCE_MUST_NOT_TOUCH_PROGRESS',
        'PLAYER_EXPERIENCE_MUST_NOT_TOUCH_ECONOMY',
        'wide-notch', '720p', 'ultrawide', 'high-density-cutout',
        'MinimumTouchPixels', 'CorruptBackupKey',
    ):
        require(regression, token, "EditMode player-experience regression")

    print("CARGO V2 player experience source guard: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"CARGO V2 player experience source guard: FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
