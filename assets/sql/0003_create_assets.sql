CREATE TABLE IF NOT EXISTS assets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    total REAL NOT NULL DEFAULT 0,
    decimals INTEGER NOT NULL DEFAULT 2,
    liquidity TEXT NOT NULL DEFAULT 'liquid',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE(code)
);
