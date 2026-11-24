with source as (

    select * from {{ source('bank_raw', 'raw_accounts') }}

),

deduped as (

    select
        *,
        row_number() over (
            partition by account_id
            order by extract_ts desc
        ) as rn
    from source

),

cleaned as (

    select
        trim(account_id)                            as account_id,
        trim(customer_id)                           as customer_id,
        nullif(upper(trim(account_type)), '')       as account_type,
        upper(trim(account_status))                 as account_status,
        try_to_date(opened_date, 'YYYY-MM-DD')      as opened_date,
        try_to_number(balance, 18, 2)               as balance,
        extract_ts
    from deduped
    where rn = 1

)

select
    *,
    coalesce(balance < 0, false) as is_negative_balance
from cleaned