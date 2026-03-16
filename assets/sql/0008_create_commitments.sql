CREATE TABLE IF NOT EXISTS commitments (
    id TEXT PRIMARY KEY,
    amount REAL NOT NULL,
    fee REAL,
    remainder REAL,
    status TEXT NOT NULL,
    issued_at TEXT NOT NULL,
    category_id TEXT NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
    vault_id TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE,
    party_id TEXT NOT NULL REFERENCES parties (id) ON DELETE CASCADE,
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    addition_id TEXT REFERENCES entries (id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    settled_at TEXT,
    deleted_at TEXT
);

CREATE TABLE IF NOT EXISTS commitment_payments (
    commitment_id TEXT NOT NULL REFERENCES commitments (id) ON DELETE CASCADE,
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    addition_id TEXT REFERENCES entries (id) ON DELETE CASCADE,
    amount REAL NOT NULL,
    fee REAL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    issued_at TEXT NOT NULL,
    PRIMARY KEY (commitment_id, entry_id)
);
