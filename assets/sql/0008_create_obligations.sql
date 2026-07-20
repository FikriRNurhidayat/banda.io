CREATE TABLE IF NOT EXISTS obligations (
    id TEXT PRIMARY KEY,
    amount REAL NOT NULL,
    remainder REAL,
    status TEXT NOT NULL,
    issued_at TEXT NOT NULL,
    category_id TEXT NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
    party_id TEXT NOT NULL REFERENCES parties (id) ON DELETE CASCADE,
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    journal_id TEXT NOT NULL REFERENCES journals (id) ON DELETE CASCADE,
    fee_id TEXT REFERENCES entries (id) ON DELETE CASCADE,
    fee_amount REAL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    settled_at TEXT,
    deleted_at TEXT
);

CREATE TABLE IF NOT EXISTS obligation_payments (
    obligation_id TEXT NOT NULL REFERENCES obligations (id) ON DELETE CASCADE,
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    amount REAL NOT NULL,
    fee_id TEXT REFERENCES entries (id) ON DELETE CASCADE,
    fee_amount REAL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    issued_at TEXT NOT NULL,
    PRIMARY KEY (obligation_id, entry_id)
);

CREATE TABLE IF NOT EXISTS obligation_labels (
    label_id TEXT NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
    obligation_id TEXT NOT NULL REFERENCES obligations (id) ON DELETE CASCADE,
    PRIMARY KEY (label_id, obligation_id)
);
