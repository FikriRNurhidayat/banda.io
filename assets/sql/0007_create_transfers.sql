CREATE TABLE IF NOT EXISTS transfers (
    id TEXT PRIMARY KEY,
    note TEXT,
    amount REAL NOT NULL,
    fee REAL,
    issued_at TEXT NOT NULL,
    credit_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    credit_account_id TEXT NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
    debit_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    debit_account_id TEXT NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
    exchange_id TEXT REFERENCES entries (id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT
);
