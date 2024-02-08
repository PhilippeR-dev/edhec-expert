with sample as (
    SELECT 'Test'
    UNION
    SELECT 'TeSt'
    UNION
    SELECT 'TesT'
    UNION
    SELECT 'TEsT'
)
select *
from sample; 