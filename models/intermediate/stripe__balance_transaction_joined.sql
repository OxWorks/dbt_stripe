with balance_transaction as (

    select *
    from {{ ref('stg_stripe__balance_transaction') }}
  
), charge as (

    select *
    from {{ ref('stg_stripe__charge')}}

), payment_intent as (

    select *
    from {{ ref('stg_stripe__payment_intent')}}

), card as (

    select *
    from {{ ref('stg_stripe__card')}}

), payout as (

    select *
    from {{ ref('stg_stripe__payout')}}


), customer as (

    select *
    from {{ ref('stg_stripe__customer')}}

{% if var('using_payment_method', True) %}

), payment_method as (

    select *
    from {{ ref('stg_stripe__payment_method')}}

), payment_method_card as (

    select *
    from {{ ref('stg_stripe__payment_method_card')}}

), refund as (

    select *
    from {{ ref('stg_stripe__refund')}}

)

select 
  balance_transaction.balance_transaction_id,
  balance_transaction.created_at,
  balance_transaction.available_on,
  balance_transaction.currency,
  balance_transaction.amount,
  balance_transaction.fee,
  balance_transaction.net,
  balance_transaction.type,
  case
    when balance_transaction.type in ('charge', 'payment') then 'charge'
    when balance_transaction.type in ('refund', 'payment_refund') then 'refund'
    when balance_transaction.type in ('payout_cancel', 'payout_failure') then 'payout_reversal'
    when balance_transaction.type in ('transfer', 'recipient_transfer') then 'transfer'
    when balance_transaction.type in ('transfer_cancel', 'transfer_failure', 'recipient_transfer_cancel', 'recipient_transfer_failure') then 'transfer_reversal'
    else balance_transaction.type
  end as reporting_category,
  balance_transaction.source,
  balance_transaction.description,
  case when balance_transaction.type = 'charge' then charge.amount end as customer_facing_amount, 
  case when balance_transaction.type = 'charge' then charge.currency end as customer_facing_currency,
  {{ dbt_utils.dateadd('day', 1, 'balance_transaction.available_on') }} as effective_at,
  coalesce(charge.customer_id, refund_charge.customer_id) as customer_id,
  charge.receipt_email,
  customer.description as customer_description,
  payment_method.type as payment_method_type,
  payment_method_card.brand as payment_method_brand,
  payment_method_card.funding as payment_method_funding,
  charge.charge_id,
  charge.payment_intent_id,
  charge.created_at as charge_created_at,
  card.brand as card_brand,
  card.funding as card_funding,
  card.country as card_country,
  payout.payout_id,
  payout.arrival_date as payout_expeted_arrival_date,
  payout.status as payout_status,
  payout.type as payout_type,
  payout.description as payout_description,
  refund.reason as refund_reason
from balance_transaction
left join charge on charge.balance_transaction_id = balance_transaction.balance_transaction_id
left join customer on charge.customer_id = customer.customer_id
left join payment_intent on charge.payment_intent_id = payment_intent.payment_intent_id
left join payment_method on payment_intent.payment_method_id = payment_method.payment_method_id
left join payment_method_card on payment_method_card.payment_method_id = payment_method.payment_method_id
left join card on charge.card_id = card.card_id
left join payout on payout.balance_transaction_id = balance_transaction.balance_transaction_id
left join refund on refund.balance_transaction_id = balance_transaction.balance_transaction_id
left join charge as refund_charge on refund.charge_id = refund_charge.charge_id
order by created_at desc

{% else %}

)

select 
  balance_transaction.balance_transaction_id,
  balance_transaction.created_at,
  balance_transaction.available_on,
  balance_transaction.currency,
  balance_transaction.amount,
  balance_transaction.fee,
  balance_transaction.net,
  balance_transaction.type,
  case
    when balance_transaction.type in ('charge', 'payment') then 'charge'
    when balance_transaction.type in ('refund', 'payment_refund') then 'refund'
    when balance_transaction.type in ('payout_cancel', 'payout_failure')	then 'payout_reversal'
    when balance_transaction.type in ('transfer', 'recipient_transfer') then	'transfer'
    when balance_transaction.type in ('transfer_cancel', 'transfer_failure', 'recipient_transfer_cancel', 'recipient_transfer_failure') then 'transfer_reversal'
    else balance_transaction.type
  end as reporting_category,
  balance_transaction.source,
  balance_transaction.description,
  case when balance_transaction.type = 'charge' then charge.amount end as customer_facing_amount,
  case when balance_transaction.type = 'charge' then charge.currency end as customer_facing_currency,
  {{ dbt_utils.dateadd('day', 1, 'balance_transaction.available_on') }} as effective_at,
  coalesce(charge.customer_id, refund_charge.customer_id) as customer_id,
  charge.receipt_email,
  customer.description as customer_description,
  charge.charge_id,
  charge.payment_intent_id,
  charge.created_at as charge_created_at,
  card.brand as card_brand,
  card.funding as card_funding,
  card.country as card_country,
  payout.payout_id,
  payout.arrival_date as payout_expeted_arrival_date,
  payout.status as payout_status,
  payout.type as payout_type,
  payout.description as payout_description,
  refund.reason as refund_reason
from balance_transaction
left join charge on charge.balance_transaction_id = balance_transaction.balance_transaction_id
left join customer on charge.customer_id = customer.customer_id
left join payment_intent on charge.payment_intent_id = payment_intent.payment_intent_id
left join card on charge.card_id = card.card_id
left join payout on payout.balance_transaction_id = balance_transaction.balance_transaction_id
left join refund on refund.balance_transaction_id = balance_transaction.balance_transaction_id
left join charge as refund_charge on refund.charge_id = refund_charge.charge_id
order by created_at desc

{% endif %}
