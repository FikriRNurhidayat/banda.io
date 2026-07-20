CREATE TABLE IF NOT EXISTS entries (
    id TEXT PRIMARY KEY,
    note TEXT,
    amount REAL NOT NULL,
    status TEXT NOT NULL,
    readonly BOOLEAN DEFAULT FALSE,
    category_id TEXT NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
    journal_id TEXT NOT NULL REFERENCES journals (id) ON DELETE CASCADE,
    controller_id TEXT,
    controller_type TEXT,
    issued_at TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS entry_labels (
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    label_id TEXT NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
    PRIMARY KEY (entry_id, label_id)
);

CREATE TABLE IF NOT EXISTS entry_annotations (
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (entry_id, name)
);

CREATE INDEX IF NOT EXISTS idx_entries_controller ON entries (
    controller_type, controller_id
);
