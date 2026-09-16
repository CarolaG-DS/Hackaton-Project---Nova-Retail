select
    target_month,
    region,
    product_category,
    count(*) as row_count
from {{ ref('fct_finance_targets') }}
group by
    target_month,
    region,
    product_category
having count(*) > 1