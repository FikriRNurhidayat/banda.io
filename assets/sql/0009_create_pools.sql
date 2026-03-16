CREATE TABLE IF NOT EXISTS pools (
    id TEXT PRIMARY KEY,
    note TEXT,
    goal REAL NOT NULL,
    balance REAL NOT NULL,
    status TEXT NOT NULL,
    vault_id TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    released_at TEXT,
    deleted_at TEXT
);

CREATE TABLE IF NOT EXISTS pool_transactions (
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    pool_id TEXT NOT NULL REFERENCES pools (id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    PRIMARY KEY (entry_id, pool_id)
);

CREATE TABLE IF NOT EXISTS pool_labels (
    label_id TEXT NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
    pool_id TEXT NOT NULL REFERENCES pools (id) ON DELETE CASCADE,
    PRIMARY KEY (label_id, pool_id)
);
