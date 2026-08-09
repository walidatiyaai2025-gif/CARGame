#!/usr/bin/env python3
from __future__ import annotations

import unittest

from verify_privacy_disclosures import DisclosureError, validate_models


def inventory_fixture() -> dict[str, object]:
    return {
        "schemaVersion": 1,
        "processors": [
            {"id": "local-device", "network": False},
            {"id": "google-mobile-ads", "network": True},
        ],
        "dataFlows": [
            {"id": "game-progress", "processor": "local-device", "network": False},
            {
                "id": "persistence-integrity",
                "processor": "local-device",
                "network": False,
            },
            {
                "id": "storage-recovery-backup",
                "processor": "local-device",
                "network": False,
            },
            {"id": "app-settings", "processor": "local-device", "network": False},
            {
                "id": "diagnostic-logs",
                "processor": "local-device",
                "network": False,
            },
            {
                "id": "ad-sdk-processing",
                "processor": "google-mobile-ads",
                "network": True,
            },
        ],
        "explicitlyAbsent": [
            "account registration",
            "email address collection",
            "first-party analytics SDK",
        ],
        "knownGaps": [],
    }


def disclosure_fixture() -> dict[str, object]:
    local_ids = [
        "game-progress",
        "persistence-integrity",
        "storage-recovery-backup",
        "app-settings",
        "diagnostic-logs",
    ]
    mappings = [
        {
            "flowId": flow_id,
            "processor": "local-device",
            "collectedOffDevice": False,
            "sharedWithThirdParties": False,
            "dataTypes": [],
        }
        for flow_id in local_ids
    ]
    mappings.append(
        {
            "flowId": "ad-sdk-processing",
            "processor": "google-mobile-ads",
            "collectedOffDevice": True,
            "sharedWithThirdParties": True,
            "dataTypes": [
                {
                    "type": data_type,
                    "purposes": [
                        "advertising_or_marketing",
                        "analytics",
                        "fraud_prevention_security_compliance",
                    ],
                }
                for data_type in (
                    "approximate_location",
                    "app_interactions",
                    "diagnostics",
                    "device_or_other_ids",
                )
            ],
        }
    )
    return {
        "schemaVersion": 1,
        "sourceInventory": "docs/privacy/data_inventory.json",
        "policyDocument": "docs/PRIVACY_POLICY.md",
        "publication": {
            "state": "draft",
            "privacyPolicyUrl": None,
            "publisherContact": None,
            "targetAudienceConfirmed": False,
            "playConsoleSubmitted": False,
            "productionAdMobConfigurationReviewed": False,
        },
        "playDataSafety": {
            "collectsUserData": True,
            "sharesUserData": True,
            "accountCreationAvailable": False,
            "deletionRequestMechanismAvailable": True,
            "encryptedInTransit": {
                "recommendedAnswer": True,
                "requiresProductionConfirmation": True,
            },
        },
        "flowMappings": mappings,
        "explicitlyAbsent": [
            "account registration",
            "email address collection",
            "first-party analytics SDK",
        ],
    }


def policy_fixture() -> str:
    return """# CARGame Privacy Policy
Publication status: DRAFT — NOT YET PUBLISHED
## Data stored on your device
Local only.
## Advertising and Google Mobile Ads
Google UMP controls eligibility and canRequestAds gates requests.
The SDK may process IP address, app interactions, diagnostic information,
and device and account identifiers.
## Data we do not collect in first-party code
No accounts.
## Retention and deletion
Settings > Privacy provides a JSON export and confirmed local deletion/reset.
## Children and target audience
Target audience confirmation is pending.
## Contact
PUBLISHER CONTACT EMAIL REQUIRED BEFORE PUBLICATION
"""


class PrivacyDisclosureContractTests(unittest.TestCase):
    def test_valid_draft_passes(self) -> None:
        validate_models(inventory_fixture(), disclosure_fixture(), policy_fixture())

    def test_missing_flow_is_rejected(self) -> None:
        disclosure = disclosure_fixture()
        disclosure["flowMappings"].pop(0)
        with self.assertRaisesRegex(DisclosureError, "missing inventory flows"):
            validate_models(inventory_fixture(), disclosure, policy_fixture())

    def test_stale_flow_is_rejected(self) -> None:
        disclosure = disclosure_fixture()
        disclosure["flowMappings"].append(
            {
                "flowId": "stale-flow",
                "processor": "local-device",
                "collectedOffDevice": False,
                "sharedWithThirdParties": False,
                "dataTypes": [],
            }
        )
        with self.assertRaisesRegex(DisclosureError, "stale flows"):
            validate_models(inventory_fixture(), disclosure, policy_fixture())

    def test_local_flow_cannot_be_declared_off_device(self) -> None:
        disclosure = disclosure_fixture()
        disclosure["flowMappings"][0]["collectedOffDevice"] = True
        with self.assertRaisesRegex(DisclosureError, "local-only"):
            validate_models(inventory_fixture(), disclosure, policy_fixture())

    def test_ad_processor_mismatch_is_rejected(self) -> None:
        disclosure = disclosure_fixture()
        disclosure["flowMappings"][-1]["processor"] = "local-device"
        with self.assertRaisesRegex(DisclosureError, "processor does not match"):
            validate_models(inventory_fixture(), disclosure, policy_fixture())

    def test_missing_gma_data_type_is_rejected(self) -> None:
        disclosure = disclosure_fixture()
        disclosure["flowMappings"][-1]["dataTypes"].pop()
        with self.assertRaisesRegex(DisclosureError, "data types must be exactly"):
            validate_models(inventory_fixture(), disclosure, policy_fixture())

    def test_missing_gma_purpose_is_rejected(self) -> None:
        disclosure = disclosure_fixture()
        disclosure["flowMappings"][-1]["dataTypes"][0]["purposes"].remove(
            "analytics"
        )
        with self.assertRaisesRegex(
            DisclosureError, "missing required Google Mobile Ads purposes"
        ):
            validate_models(inventory_fixture(), disclosure, policy_fixture())

    def test_explicit_absence_drift_is_rejected(self) -> None:
        disclosure = disclosure_fixture()
        disclosure["explicitlyAbsent"].pop()
        with self.assertRaisesRegex(DisclosureError, "explicitlyAbsent"):
            validate_models(inventory_fixture(), disclosure, policy_fixture())

    def test_local_deletion_mechanism_cannot_regress(self) -> None:
        disclosure = disclosure_fixture()
        disclosure["playDataSafety"]["deletionRequestMechanismAvailable"] = False
        with self.assertRaisesRegex(DisclosureError, "must remain available"):
            validate_models(inventory_fixture(), disclosure, policy_fixture())

    def test_completed_priv003_gap_cannot_return(self) -> None:
        inventory = inventory_fixture()
        inventory["knownGaps"].append(
            {"id": "in-app-data-controls", "owner": "PRIV-003"}
        )
        with self.assertRaisesRegex(DisclosureError, "must not remain"):
            validate_models(inventory, disclosure_fixture(), policy_fixture())

    def test_policy_must_describe_local_controls(self) -> None:
        policy = policy_fixture().replace("Settings > Privacy", "Settings")
        with self.assertRaisesRegex(DisclosureError, "Settings > Privacy"):
            validate_models(inventory_fixture(), disclosure_fixture(), policy)

    def test_draft_cannot_claim_play_console_submission(self) -> None:
        disclosure = disclosure_fixture()
        disclosure["publication"]["playConsoleSubmitted"] = True
        with self.assertRaisesRegex(DisclosureError, "must not claim Play Console"):
            validate_models(inventory_fixture(), disclosure, policy_fixture())

    def test_published_requires_https_url(self) -> None:
        disclosure = disclosure_fixture()
        publication = disclosure["publication"]
        publication.update(
            {
                "state": "published",
                "privacyPolicyUrl": "http://example.test/privacy",
                "publisherContact": "privacy@example.test",
                "targetAudienceConfirmed": True,
                "playConsoleSubmitted": True,
                "productionAdMobConfigurationReviewed": True,
            }
        )
        policy = policy_fixture().replace(
            "Publication status: DRAFT — NOT YET PUBLISHED",
            "Publication status: PUBLISHED",
        ).replace(
            "PUBLISHER CONTACT EMAIL REQUIRED BEFORE PUBLICATION",
            "privacy@example.test",
        )
        with self.assertRaisesRegex(DisclosureError, "stable HTTPS URL"):
            validate_models(inventory_fixture(), disclosure, policy)

    def test_published_cannot_retain_contact_placeholder(self) -> None:
        disclosure = disclosure_fixture()
        publication = disclosure["publication"]
        publication.update(
            {
                "state": "published",
                "privacyPolicyUrl": "https://example.test/privacy",
                "publisherContact": "privacy@example.test",
                "targetAudienceConfirmed": True,
                "playConsoleSubmitted": True,
                "productionAdMobConfigurationReviewed": True,
            }
        )
        policy = policy_fixture().replace(
            "Publication status: DRAFT — NOT YET PUBLISHED",
            "Publication status: PUBLISHED",
        )
        with self.assertRaisesRegex(DisclosureError, "contact placeholder"):
            validate_models(inventory_fixture(), disclosure, policy)

    def test_policy_section_drift_is_rejected(self) -> None:
        policy = policy_fixture().replace(
            "## Advertising and Google Mobile Ads", "## Advertising"
        )
        with self.assertRaisesRegex(DisclosureError, "privacy policy is missing"):
            validate_models(inventory_fixture(), disclosure_fixture(), policy)


if __name__ == "__main__":
    unittest.main(verbosity=2)
