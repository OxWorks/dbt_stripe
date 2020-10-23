with charge as (

    select *
    from {{ ref('stg_stripe__charge')}}

)

select 
  created_at,
  customer_id,
  amount
from charge
where not is_captured
