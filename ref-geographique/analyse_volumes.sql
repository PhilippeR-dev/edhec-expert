select count(1) from PLACES;
-- 3 858 264

select count(1)
from REF_DEV.REF_GEOGRAPHIQUE.PLACES PL
     inner join REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL on DL.ISO = PL.ISO
;
-- 3 858 264

select count(1) from PLACES_DENORM;
-- 15 787 373

select count(1) from PLACES_POSTCODES;
-- 11 710 231

select * from PLACES_POSTCODES;

select * from POSTCODES;

select count(1) from POSTCODES;
-- 8 662 268

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


SELECT count(1) FROM REF_DEV.PUBLIC.PLACES_POSTCODES_SEARCH;
-- 15 492 637


select * from REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES
order by iso;


select * from REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES
where iso = 'GB';


select count(1) from REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES;
-- 247


select tb.COUNTRY_CODE, tb.PLACE_ID, tb.LOCALITY, count(1)
from REF_DEV.PUBLIC.COUNTRY_PLACE_POSTCODES_SEARCH tb
group by tb.COUNTRY_CODE, tb.PLACE_ID, tb.LOCALITY 
order by 4 desc
; 