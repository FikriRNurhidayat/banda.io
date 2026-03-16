CREATE TABLE IF NOT EXISTS invoices (
    id TEXT PRIMARY KEY,
    number TEXT NOT NULL,
    note TEXT NOT NULL,
    amount REAL NOT NULL,
    status TEXT NOT NULL,
    entry_id TEXT NOT NULL REFERENCES entries (id),
    category_id TEXT NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
    vault_id TEXT NOT NULL REFERENCES vaults (id) ON DELETE CASCADE,
    issued_at TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    UNIQUE (number, deleted_at)
);

CREATE TABLE IF NOT EXISTS invoice_payments (
    entry_id TEXT NOT NULL REFERENCES entries (id) ON DELETE CASCADE,
    invoice_id TEXT NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
    fee REAL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    PRIMARY KEY (entry_id, invoice_id)
);

CREATE TABLE IF NOT EXISTS invoice_labels (
    label_id TEXT NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
    invoice_id TEXT NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
    PRIMARY KEY (label_id, invoice_id)
);
