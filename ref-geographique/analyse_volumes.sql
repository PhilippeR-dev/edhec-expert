select count(1) from PLACES;
-- 3 858 264
select count(1) from PLACES_DENORM;
-- 15 787 373

select count(1) from PLACES_POSTCODES;
-- 11 710 231

with sel as (
    SELECT PL.*
    FROM "REF_DEV"."REF_GEOGRAPHIQUE"."PLACES" PL
       INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL ON (PL.ISO = DL.ISO)
       INNER JOIN "REF_DEV"."REF_GEOGRAPHIQUE"."PLACES_POSTCODES" PL_PC ON (PL.ID = PL_PC.PLACE_ID AND PL.ISO = PL_PC.ISO)
        INNER JOIN "REF_DEV"."REF_GEOGRAPHIQUE"."POSTCODES" PC ON (PC.ID = PL_PC.POSTCODE_ID AND PC.ISO = PL_PC.ISO)
)
select count(1)
from sel;
-- 11 710 231 > les codes postals font grossir les lignes en sortie (table PLACES_POSTCODES)


select * from PLACES_POSTCODES;

select ISO, count(1) 
from PLACES_POSTCODES
--where iso = 'FR'
group by ISO
order by 2 desc;
-- 1 - AR > 2 183 860
-- 24 - FR > 49 078
