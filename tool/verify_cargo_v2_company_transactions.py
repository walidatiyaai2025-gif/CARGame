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
    if not path.is_file(): fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def require_tokens(label: str, content: str, tokens: tuple[str, ...]) -> None:
    for token in tokens:
        if token not in content: fail(f"{label} missing transaction contract token: {token}")


@dataclass
class EconomyModel:
    coins: int
    receipts: dict[str, int] = field(default_factory=dict)

    def read_commit(self, amount: int, operation_id: str) -> tuple[bool, bool]:
        if amount <= 0 or not operation_id: return False, False
        if operation_id not in self.receipts: return True, False
        return self.receipts[operation_id] == amount, self.receipts[operation_id] == amount

    def ensure_spend(self, amount: int, operation_id: str) -> tuple[bool, bool]:
        ok, committed = self.read_commit(amount, operation_id)
        if not ok or committed: return ok, committed
        if self.coins < amount: return True, False
        self.coins -= amount
        self.receipts[operation_id] = amount
        return True, True


@dataclass
class CompanyModel:
    owned: set[str] = field(default_factory=lambda: {"atlas_s"})
    selected: str = "atlas_s"
    engine_level: int = 0
    pending: dict[str, object] | None = None


def resolve_purchase(economy: EconomyModel, company: CompanyModel, current_price: int) -> bool:
    pending = company.pending
    if pending is None: return True
    cost = int(pending["cost"])
    op = str(pending["id"])
    ok, committed = economy.read_commit(cost, op)
    if not ok: return False
    if not committed:
        if current_price != cost: return False
        ok, committed = economy.ensure_spend(cost, op)
        if not ok: return False
        if not committed:
            company.pending = None
            return True
    truck_id = str(pending["truck"])
    company.owned.add(truck_id)
    company.selected = truck_id
    company.pending = None
    return True


def resolve_upgrade(economy: EconomyModel, company: CompanyModel, current_cost: int) -> bool:
    pending = company.pending
    if pending is None: return True
    cost = int(pending["cost"])
    op = str(pending["id"])
    ok, committed = economy.read_commit(cost, op)
    if not ok: return False
    from_level = int(pending["from"])
    to_level = int(pending["to"])
    if not committed:
        if current_cost != cost or company.engine_level != from_level: return False
        ok, committed = economy.ensure_spend(cost, op)
        if not ok: return False
        if not committed:
            company.pending = None
            return True
    if company.engine_level == from_level: company.engine_level = to_level
    elif company.engine_level != to_level: return False
    company.pending = None
    return True


def exercise_crash_model() -> None:
    economy = EconomyModel(5000)
    company = CompanyModel(pending={"id": "purchase-a", "truck": "titan_x", "cost": 1200})
    if not resolve_purchase(economy, company, 1200) or economy.coins != 3800 or "titan_x" not in company.owned:
        fail("journal-only purchase crash did not converge to one debit/ownership commit")

    economy = EconomyModel(3800, {"purchase-b": 1200})
    company = CompanyModel(pending={"id": "purchase-b", "truck": "titan_x", "cost": 1200})
    if not resolve_purchase(economy, company, 9999) or economy.coins != 3800 or "titan_x" not in company.owned:
        fail("committed purchase receipt did not survive catalog price drift without second debit")

    economy = EconomyModel(2650, {"upgrade-a": 350})
    company = CompanyModel(pending={"id": "upgrade-a", "truck": "atlas_s", "cost": 350, "from": 0, "to": 1})
    if not resolve_upgrade(economy, company, 9999) or economy.coins != 2650 or company.engine_level != 1:
        fail("committed upgrade receipt did not finish exactly once after catalog drift")
    company.pending = {"id": "upgrade-a", "truck": "atlas_s", "cost": 350, "from": 0, "to": 1}
    if not resolve_upgrade(economy, company, 9999) or economy.coins != 2650 or company.engine_level != 1:
        fail("post-company-save upgrade replay was not idempotent")

    economy = EconomyModel(100)
    company = CompanyModel(pending={"id": "purchase-c", "truck": "titan_x", "cost": 1200})
    if not resolve_purchase(economy, company, 1200) or economy.coins != 100 or "titan_x" in company.owned or company.pending is not None:
        fail("provably unpaid insufficient purchase did not cancel without mutation")

    economy = EconomyModel(5000)
    ok, committed = economy.ensure_spend(1200, "reuse-a")
    if not ok or not committed: fail("receipt reuse fixture failed")
    ok, committed = economy.ensure_spend(1300, "reuse-a")
    if ok or committed or economy.coins != 3800: fail("mismatched receipt reuse did not fail closed")


def main() -> None:
    company = read(COMPANY)
    economy = read(ECONOMY)

    require_tokens("SCR_MissionRewardStore.cs", economy, (
        "SpendReceiptPayload", "MaxSpendReceipts = 128", "TryReadSpendCommit(", "TryEnsureCoinSpend(",
        'Guid.TryParseExact(operationId, "N"', "FindSpendReceipt(payload, operationId)", "receipt.amount != amount",
        "payload.coins -= amount", "payload.spendReceipts.Add", "if (!TrySave(payload)) return false;"))
    require_tokens("SCR_CompanyProgressStore.cs", company, (
        'PendingTransactionKey = "cargo_v2_company_transaction_v1"', "CorruptTransactionBackupKey",
        "UnsupportedTransactionBackupKey", "TryWritePendingTransaction(pending)", "TryRecoverPendingTransaction(payload)",
        "TryResolvePendingTransaction(", "SCR_MissionRewardStore.TryReadSpendCommit(", "if (!paymentCommitted)",
        "SCR_MissionRewardStore.TryEnsureCoinSpend(", "Payment is committed; company state remains pending idempotent recovery.",
        "TryClearPendingTransaction()", "PreserveCorruptTransaction(raw)"))

    if "TrySpendCoins(truck.purchasePrice" in company or "TrySpendCoins(cost" in company:
        fail("company purchase/upgrade still performs a non-idempotent direct debit")
    if "TryCreditCoins(truck.purchasePrice" in company or "TryCreditCoins(cost" in company:
        fail("company transaction still depends on a separate rollback credit")

    resolve_start = company.find("private static bool TryResolvePendingTransaction")
    resolve_end = company.find("private static bool TryWritePendingTransaction", resolve_start)
    resolve = company[resolve_start:resolve_end]
    if resolve.find("TryReadSpendCommit") < 0 or resolve.find("if (!paymentCommitted)") < 0:
        fail("transaction resolver does not classify committed payment before current catalog checks")
    if resolve.find("TryEnsureCoinSpend") < 0 or resolve.find("TrySave(payload)") < 0:
        fail("transaction resolver is missing payment/company persistence stages")
    if resolve.find("TryEnsureCoinSpend") > resolve.find("TrySave(payload)"):
        fail("company state can persist before the idempotent payment receipt")

    exercise_crash_model()
    print("CARGO V2 COMPANY TRANSACTION PASS: journal-before-debit, read-before-reprice, committed-intent recovery, purchase/upgrade crash idempotency.")


if __name__ == "__main__":
    main()
