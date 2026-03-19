INSERT INTO labels
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
    'd84cbeeb-a35c-47fb-983b-42c5a8c7e8f6',
    'Fee',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    '93242916-4ffb-4757-8f81-abc62fe26d90',
    'Tax',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    'b6afdfc5-13bd-4f7c-a524-132a0a5be8ba',
    'Deposit',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    'c75e678b-1263-41ac-89df-2e0c713b0d7f',
    'Withdraw',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    '20a2f0c0-a596-48cc-9b4b-45d4192917d2',
    'Disbursement',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    'f9a41b42-e34e-42c7-bea8-ae8347edbfea',
    'Payment',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    'd44d6370-ad29-4a51-8a13-952d21b8960b',
    'Commitment',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    '7fbd39dd-db12-40b0-8bbc-6230f228e22b',
    'Released',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    '4126eab5-de36-44d4-a337-cee09deed327',
    'Retracted',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    '55ba2543-c46c-40d3-a86e-0cc13d7c17d4',
    'Credit',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
),
(
    'd3a7de05-8f92-46f0-9410-932053a3fe59',
    'Debit',
    1,
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now'),
    NULL
) ON CONFLICT (name, deleted_at) DO NOTHING;
