CREATE TABLE IF NOT EXISTS schedules (
    id TEXT PRIMARY KEY,
    note TEXT,
    amount REAL NOT NULL,
    fee_id TEXT REFERENCES entries (id),
    fee_amount REAL,
    cycle TEXT NOT NULL,
    iteration INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL,
    entry_id TEXT NOT NULL REFERENCES entries (id),
    category_id TEXT NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
    vault_id TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE,
    due_at TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS schedule_labels (
    label_id TEXT NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
    schedule_id TEXT NOT NULL REFERENCES schedules (id) ON DELETE CASCADE,
    PRIMARY KEY (label_id, schedule_id)
);
