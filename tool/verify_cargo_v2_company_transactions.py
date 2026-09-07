#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMPANY = ROOT / "Assets/_Project/Scripts/Logic/SCR_CompanyProgressStore.cs"
ECONOMY = ROOT / "Assets/_Project/Scripts/Logic/SCR_MissionRewardStore.cs"


def fail(message: str) -> None:
    raise SystemExit(f"CARGO V2 COMPANY TRANSACTION FAIL: {message}")


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def require_tokens(label: str, content: str, tokens: tuple[str, ...]) -> None:
    for token in tokens:
        if token not in content:
            fail(f"{label} missing transaction contract token: {token}")


@dataclass
class EconomyModel:
    coins: int
    receipts: dict[str, int] = field(default_factory=dict)

    def ensure_spend(self, amount: int, operation_id: str) -> tuple[bool, bool]:
        if amount <= 0 or not operation_id:
            return False, False
        if operation_id in self.receipts:
            return self.receipts[operation_id] == amount, self.receipts[operation_id] == amount
        if self.coins < amount:
            return True, False
        self.coins -= amount
        self.receipts[operation_id] = amount
        return True, True


@dataclass
class CompanyModel:
    owned: set[str] = field(default_factory=lambda: {"atlas_s"})
    selected: str = "atlas_s"
    engine_level: int = 0
    pending: dict[str, object] | None = None


def resolve_purchase(economy: EconomyModel, company: CompanyModel) -> bool:
    pending = company.pending
    if pending is None:
        return True
    ok, committed = economy.ensure_spend(int(pending["cost"]), str(pending["id"]))
    if not ok:
        return False
    if not committed:
        company.pending = None
        return True
    truck_id = str(pending["truck"])
    company.owned.add(truck_id)
    company.selected = truck_id
    company.pending = None
    return True


def resolve_upgrade(economy: EconomyModel, company: CompanyModel) -> bool:
    pending = company.pending
    if pending is None:
        return True
    ok, committed = economy.ensure_spend(int(pending["cost"]), str(pending["id"]))
    if not ok:
        return False
    if not committed:
        company.pending = None
        return True
    from_level = int(pending["from"])
    to_level = int(pending["to"])
    if company.engine_level == from_level:
        company.engine_level = to_level
    elif company.engine_level != to_level:
        return False
    company.pending = None
    return True


def exercise_crash_model() -> None:
    # Crash after journal persistence, before payment: recovery charges once and applies purchase.
    economy = EconomyModel(5000)
    company = CompanyModel(pending={"id": "purchase-a", "truck": "titan_x", "cost": 1200})
    if not resolve_purchase(economy, company):
        fail("purchase recovery after journal-only crash did not resolve")
    if economy.coins != 3800 or "titan_x" not in company.owned or company.selected != "titan_x":
        fail("purchase recovery after journal-only crash produced the wrong state")

    # Re-entry after successful recovery is a no-op.
    if not resolve_purchase(economy, company) or economy.coins != 3800:
        fail("re-entering completed purchase recovery changed the economy")

    # Crash after payment receipt, before company save: receipt suppresses duplicate debit.
    economy = EconomyModel(5000)
    company = CompanyModel(pending={"id": "purchase-b", "truck": "titan_x", "cost": 1200})
    ok, committed = economy.ensure_spend(1200, "purchase-b")
    if not ok or not committed or economy.coins != 3800:
        fail("purchase payment fixture failed")
    if not resolve_purchase(economy, company):
        fail("purchase recovery after payment crash did not resolve")
    if economy.coins != 3800 or "titan_x" not in company.owned:
        fail("purchase recovery after payment crash double-charged or lost ownership")

    # Crash after company save, before journal cleanup: both state changes stay idempotent.
    economy = EconomyModel(5000)
    ok, committed = economy.ensure_spend(1200, "purchase-c")
    if not ok or not committed:
        fail("purchase post-save fixture payment failed")
    company = CompanyModel(
        owned={"atlas_s", "titan_x"},
        selected="titan_x",
        pending={"id": "purchase-c", "truck": "titan_x", "cost": 1200},
    )
    if not resolve_purchase(economy, company) or economy.coins != 3800:
        fail("purchase post-company-save recovery was not idempotent")

    # Upgrade crash after payment must advance exactly one level without a second charge.
    economy = EconomyModel(3000)
    company = CompanyModel(pending={"id": "upgrade-a", "truck": "atlas_s", "cost": 350, "from": 0, "to": 1})
    ok, committed = economy.ensure_spend(350, "upgrade-a")
    if not ok or not committed:
        fail("upgrade payment fixture failed")
    if not resolve_upgrade(economy, company):
        fail("upgrade recovery after payment crash did not resolve")
    if economy.coins != 2650 or company.engine_level != 1:
        fail("upgrade recovery double-charged or advanced the wrong level")

    # Crash after upgrade save but before journal cleanup stays at exactly one level/charge.
    company.pending = {"id": "upgrade-a", "truck": "atlas_s", "cost": 350, "from": 0, "to": 1}
    if not resolve_upgrade(economy, company):
        fail("upgrade post-save recovery did not resolve")
    if economy.coins != 2650 or company.engine_level != 1:
        fail("upgrade post-save recovery was not idempotent")

    # If payment was never committed and funds are no longer available, cancel without mutation.
    economy = EconomyModel(100)
    company = CompanyModel(pending={"id": "purchase-d", "truck": "titan_x", "cost": 1200})
    if not resolve_purchase(economy, company):
        fail("insufficient-funds recovery did not resolve safely")
    if economy.coins != 100 or "titan_x" in company.owned or company.pending is not None:
        fail("insufficient-funds recovery mutated company/economy state")

    # Reusing one operation id for a different amount must fail closed.
    economy = EconomyModel(5000)
    ok, committed = economy.ensure_spend(1200, "reuse-a")
    if not ok or not committed:
        fail("receipt reuse fixture failed")
    ok, committed = economy.ensure_spend(1300, "reuse-a")
    if ok or committed or economy.coins != 3800:
        fail("mismatched receipt reuse did not fail closed")


def main() -> None:
    company = read(COMPANY)
    economy = read(ECONOMY)

    require_tokens(
        "SCR_MissionRewardStore.cs",
        economy,
        (
            "SpendReceiptPayload",
            "MaxSpendReceipts = 128",
            "TryEnsureCoinSpend(",
            "Guid.TryParseExact(operationId, \"N\"",
            "FindSpendReceipt(payload, operationId)",
            "receipt.amount != amount",
            "payload.coins -= amount",
            "payload.spendReceipts.Add",
            "if (!TrySave(payload)) return false;",
        ),
    )
    require_tokens(
        "SCR_CompanyProgressStore.cs",
        company,
        (
            "PendingTransactionKey = \"cargo_v2_company_transaction_v1\"",
            "CorruptTransactionBackupKey",
            "TryWritePendingTransaction(pending)",
            "TryRecoverPendingTransaction(payload)",
            "TryResolvePendingTransaction(",
            "SCR_MissionRewardStore.TryEnsureCoinSpend(",
            "Payment is committed; company state remains pending idempotent recovery.",
            "TryClearPendingTransaction()",
            "BackupCorruptTransaction(json)",
        ),
    )

    if "TrySpendCoins(truck.purchasePrice" in company or "TrySpendCoins(cost" in company:
        fail("company purchase/upgrade still performs a non-idempotent direct debit")
    if "TryCreditCoins(truck.purchasePrice" in company or "TryCreditCoins(cost" in company:
        fail("company transaction still depends on a separate rollback credit")

    buy_start = company.find("public static bool TryBuyTruck")
    buy_end = company.find("public static bool TryUpgradeSelected", buy_start)
    buy = company[buy_start:buy_end]
    if buy.find("TryWritePendingTransaction(pending)") > buy.find("TryResolvePendingTransaction"):
        fail("purchase can resolve before its recovery journal is persisted")

    upgrade_start = company.find("public static bool TryUpgradeSelected")
    upgrade_end = company.find("private static bool TryLoad", upgrade_start)
    upgrade = company[upgrade_start:upgrade_end]
    if upgrade.find("TryWritePendingTransaction(pending)") > upgrade.find("TryResolvePendingTransaction"):
        fail("upgrade can resolve before its recovery journal is persisted")

    resolve_start = company.find("private static bool TryResolvePendingTransaction")
    resolve_end = company.find("private static bool TryWritePendingTransaction", resolve_start)
    resolve = company[resolve_start:resolve_end]
    if resolve.find("TryEnsureCoinSpend") < 0 or resolve.find("TrySave(payload)") < 0:
        fail("transaction resolver is missing payment/company persistence stages")
    if resolve.find("TryEnsureCoinSpend") > resolve.find("TrySave(payload)"):
        fail("company state can persist before the idempotent payment receipt")

    exercise_crash_model()
    print(
        "CARGO V2 COMPANY TRANSACTION PASS: journal-before-debit protocol, idempotent spend receipts, "
        "purchase/upgrade crash-point recovery, no direct rollback-credit dependency."
    )


if __name__ == "__main__":
    main()
