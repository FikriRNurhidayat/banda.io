CREATE TABLE IF NOT EXISTS loans (
    id TEXT PRIMARY KEY,
    amount REAL NOT NULL,
    fee REAL,
    remainder REAL,
    kind TEXT NOT NULL,
    status TEXT NOT NULL,
    issued_at TEXT NOT NULL,
    vault_id TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE,
    party_id TEXT NOT NULL REFERENCES parties (id) ON DELETE CASCADE,
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    addition_id TEXT REFERENCES entries (id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    settled_at TEXT,
    deleted_at TEXT
);

CREATE TABLE IF NOT EXISTS loan_payments (
    loan_id TEXT NOT NULL REFERENCES loans (id) ON DELETE CASCADE,
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    addition_id TEXT REFERENCES entries (id) ON DELETE CASCADE,
    amount REAL NOT NULL,
    fee REAL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    issued_at TEXT NOT NULL,
    PRIMARY KEY (loan_id, entry_id)
);
