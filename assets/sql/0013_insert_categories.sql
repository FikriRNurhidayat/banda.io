INSERT INTO categories
(
    id,
    name,
    readonly,
    created_at,
    updated_at,
    deleted_at
)
VALUES
(
    '003fdfec-87ae-40be-a9fe-63cca0626da8',
    'Transfer',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    'bf3cdec6-e424-40eb-8540-80e5229911fa',
    'Pool',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    '774bafab-8b48-490a-a9dc-115ac1557391',
    'Commitment',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    '8497d4d3-377d-405e-84ea-52c96e36548e',
    'Adjustment',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
) ON CONFLICT (name, deleted_at) DO NOTHING;
