with source as (

    select * from {{ source('bank_raw', 'raw_customers') }}

),

deduped as (

    select
        *,
        row_number() over (
            partition by customer_id
            order by extract_ts desc
        ) as rn
    from source

),

cleaned as (

    select
        trim(customer_id)                       as customer_id,
        initcap(trim(full_name))                as full_name,
        lower(trim(email))                      as email,
        nullif(trim(phone), '')                 as phone,
        nullif(initcap(trim(city)), '')         as city,
        upper(trim(segment))                    as segment,
        coalesce(
            try_to_date(join_date, 'YYYY-MM-DD'),
            try_to_date(join_date, 'DD/MM/YYYY')
        )                                       as join_date,
        extract_ts
    from deduped
    where rn = 1

)

select
    *,
    (email like '%_@_%._%') as is_valid_email
from cleaned