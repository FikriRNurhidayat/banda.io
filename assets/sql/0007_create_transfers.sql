CREATE TABLE IF NOT EXISTS transfers (
    id TEXT PRIMARY KEY,
    note TEXT,
    credit_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    credit_journal_id TEXT NOT NULL REFERENCES journals (id) ON DELETE CASCADE,
    credit_amount REAL NOT NULL,
    debit_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    debit_journal_id TEXT NOT NULL REFERENCES journals (id) ON DELETE CASCADE,
    debit_amount REAL NOT NULL,
    fee_id TEXT REFERENCES entries (id) ON DELETE CASCADE,
    fee_amount REAL,
    issued_at TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
