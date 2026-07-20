INSERT INTO categories
(
    id,
    name,
    readonly,
    created_at,
    updated_at
)
VALUES
(
    '003fdfec-87ae-40be-a9fe-63cca0626da8',
    'Transfer',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now')
),
(
    '8497d4d3-377d-405e-84ea-52c96e36548e',
    'Adjustment',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now')
) ON CONFLICT (name) DO NOTHING;
