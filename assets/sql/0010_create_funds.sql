CREATE TABLE IF NOT EXISTS funds (
    id TEXT PRIMARY KEY,
    note TEXT,
    amount REAL NOT NULL,
    balance REAL NOT NULL,
    status TEXT NOT NULL,
    category_id TEXT NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
    journal_id TEXT NOT NULL REFERENCES journals (id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    released_at TEXT
);

CREATE TABLE IF NOT EXISTS fund_entries (
    fund_id TEXT NOT NULL REFERENCES funds (id) ON DELETE CASCADE,
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    note TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    PRIMARY KEY (entry_id, fund_id)
);

CREATE TABLE IF NOT EXISTS fund_labels (
    label_id TEXT NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
    fund_id TEXT NOT NULL REFERENCES funds (id) ON DELETE CASCADE,
    PRIMARY KEY (label_id, fund_id)
);
