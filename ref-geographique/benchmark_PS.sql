
/*
****
**** PROCEDURE STOCKEE DE REFERENCE
****                    GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_DENORM
****

CREATE OR REPLACE PROCEDURE "GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_DENORM"("COUNTRY" VARCHAR(2), "INPUT_PLACE" VARCHAR(16777216))
RETURNS TABLE ("ID" NUMBER(38,0), "POSTCODE" VARCHAR(16777216), "PLACES" VARCHAR(16777216))
LANGUAGE SQL
EXECUTE AS OWNER
AS '
DECLARE
 
  		res_fr RESULTSET DEFAULT (SELECT PL.PLACES_ID, REPLACE(PL.POSTCODE,'' ''), PL.LOCALITY
						FROM REF_DEV.REF_GEOGRAPHIQUE.PLACES_DENORM PL
						INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL1 ON (PL.ISO = DL1.ISO)
						INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL2 ON (DL2.LANG1 = PL.PLACES_LANGUAGE AND DL2.ISO = PL.ISO)
						WHERE UPPER(PL.LOCALITY) LIKE CONCAT(UPPER(:input_place),''%'') 
						AND (UPPER(PL.ISO)=UPPER(:country) OR UPPER(DL1.SOVEREIGN)=UPPER(:country))
						AND IS_POSTAL=1 
						ORDER BY LENGTH(PL.LOCALITY)
						LIMIT 50);
	
		res_autre RESULTSET DEFAULT (SELECT PL.PLACES_ID, REPLACE(PL.POSTCODE,'' '') , PL.LOCALITY 
						FROM REF_DEV.REF_GEOGRAPHIQUE.PLACES_DENORM PL
						INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL1 ON (PL.ISO = DL1.ISO)
						INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL2 ON (DL2.LANG1 = PL.PLACES_LANGUAGE AND DL2.ISO = PL.ISO)
						WHERE UPPER(PL.LOCALITY) LIKE CONCAT(UPPER(:input_place),''%'') 
						AND ( UPPER(PL.ISO)=UPPER(:country) OR UPPER(DL1.SOVEREIGN)=UPPER(:country))
						AND IS_POSTAL=1 
						ORDER BY LENGTH(PL.LOCALITY)
						LIMIT 50);

BEGIN
	IF (country=''FR'') THEN  
		RETURN TABLE(res_fr);
	ELSE
		RETURN TABLE(res_autre); 
	END IF; 
END;
';
*/

-- REQUETE de REFERENCE
SELECT PL.PLACES_ID, REPLACE(PL.POSTCODE,'' ''), PL.LOCALITY
FROM REF_DEV.REF_GEOGRAPHIQUE.PLACES_DENORM PL
 		 INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL1 ON (PL.ISO = DL1.ISO)
		 INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL2 ON (DL2.LANG1 = PL.PLACES_LANGUAGE AND DL2.ISO = PL.ISO)
WHERE UPPER(PL.LOCALITY) LIKE CONCAT(UPPER('Montau'),'%')
	AND (UPPER(PL.ISO)=UPPER('FR') OR UPPER(DL1.SOVEREIGN)=UPPER('FR'))
	AND IS_POSTAL=1 
ORDER BY LENGTH(PL.LOCALITY)
LIMIT 50;

-- TEST de REFERENCE 
call REF_DEV.PUBLIC.GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_DENORM('US','Chic');
-- entre 500 ms et 1800 ms (première exécution)
-- 1.3s (Chic)



select * from REF_DEV.REF_GEOGRAPHIQUE.PLACES_DENORM;


select * from REF_DEV.REF_GEOGRAPHIQUE.PLACES;


CREATE OR REPLACE TRANSIENT TABLE REF_DEV.PUBLIC.PLACES_POSTCODES_SEARCH AS
SELECT   CASE WHEN DL1.SOVEREIGN IS NULL OR TRIM(DL1.SOVEREIGN)='' THEN UPPER(PL.ISO)
              ELSE UPPER(DL1.SOVEREIGN) 
         END COUNTRY_CODE
        ,PL.PLACES_ID
        ,REPLACE(PL.POSTCODE,' ') AS POSTCODE 
        ,LOCALITY
        --,PL.LOCALITY
        ,PL.PLACES_LANGUAGE, DL1.SOVEREIGN
        ,COUNTRY_CODE||'_'||UPPER(LOCALITY)||'_'||POSTCODE as SEARCH_KEY 
FROM REF_DEV.REF_GEOGRAPHIQUE.PLACES_DENORM PL
     INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL1 ON (PL.ISO = DL1.ISO)
WHERE IS_POSTAL=1
ORDER BY SEARCH_KEY
;

CREATE OR REPLACE TRANSIENT TABLE REF_DEV.PUBLIC.PLACES_POSTCODES_SEARCH AS
SELECT   CASE WHEN DL1.SOVEREIGN IS NULL OR TRIM(DL1.SOVEREIGN)='' THEN UPPER(PL.ISO)
              ELSE UPPER(DL1.SOVEREIGN) 
         END COUNTRY_CODE
        ,PL.PLACES_ID
        ,REPLACE(PL.POSTCODE,' ') AS POSTCODE 
        ,LOCALITY
        ,REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS(LOCALITY) as GENERIC_LOCALITY
        ,PL.PLACES_LANGUAGE, DL1.SOVEREIGN
        ,COUNTRY_CODE||'_'||GENERIC_LOCALITY||'_'||POSTCODE as SEARCH_KEY 
FROM REF_DEV.REF_GEOGRAPHIQUE.PLACES_DENORM PL
     INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL1 ON (PL.ISO = DL1.ISO)
WHERE IS_POSTAL=1
ORDER BY SEARCH_KEY
;

SELECT * FROM REF_DEV.PUBLIC.PLACES_POSTCODES_SEARCH
WHERE COUNTRY_CODE = UPPER('FR')
  AND SEARCH_KEY ILIKE CONCAT('%',CONCAT('Montau','%'))
; 
-- 1000 ms

SELECT * FROM REF_DEV.PUBLIC.PLACES_POSTCODES_SEARCH
WHERE SEARCH_KEY LIKE UPPER('FR')||'_'||'Montau'||'%'
--ORDER BY LENGTH(LOCALITY), POSTCODE
; 
-- 1000 ms

CREATE OR REPLACE PROCEDURE REF_DEV.PUBLIC.GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_SEARCH("COUNTRY" VARCHAR(2), "INPUT_PLACE" VARCHAR(16777216))
RETURNS TABLE ("PLACES_ID" NUMBER(38,0), "POSTCODE" VARCHAR(16777216), "LOCALITY" VARCHAR(16777216))
LANGUAGE SQL
EXECUTE AS OWNER
AS 
DECLARE
    query VARCHAR DEFAULT 'WITH SEL as ( SELECT PLACES_ID, POSTCODE, LOCALITY 
                                         FROM REF_DEV.PUBLIC.PLACES_POSTCODES_SEARCH
                                         WHERE SEARCH_KEY LIKE UPPER('''||:COUNTRY||''')||''_''||UPPER('''||:INPUT_PLACE||''')||''%'' )
                           SELECT * FROM SEL
                           ORDER BY LENGTH(LOCALITY), POSTCODE
                           LIMIT 50';
    res RESULTSET;
BEGIN
    res := (EXECUTE IMMEDIATE :query);             
    RETURN TABLE(res);
END;
;

CREATE OR REPLACE PROCEDURE REF_DEV.PUBLIC.GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_SEARCH("COUNTRY" VARCHAR(2), "INPUT_PLACE" VARCHAR(16777216))
RETURNS TABLE ("PLACES_ID" NUMBER(38,0), "POSTCODE" VARCHAR(16777216), "LOCALITY" VARCHAR(16777216))
LANGUAGE SQL
EXECUTE AS OWNER
AS 
DECLARE
    query VARCHAR DEFAULT 'SELECT PLACES_ID, POSTCODE, LOCALITY 
                           FROM REF_DEV.PUBLIC.PLACES_POSTCODES_SEARCH
                           WHERE SEARCH_KEY LIKE UPPER('''||:COUNTRY||''')||''_''||UPPER('''||:INPUT_PLACE||''')||''%'' 
                           LIMIT 50';
    res RESULTSET;
BEGIN
    res := (EXECUTE IMMEDIATE :query);             
    RETURN TABLE(res);
END;


call REF_DEV.PUBLIC.GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_SEARCH('US','San F');
-- 1300 ms

call REF_DEV.PUBLIC.GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_SEARCH('US','Chic');
-- 856ms



CREATE OR REPLACE PROCEDURE REF_DEV.PUBLIC.GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_SEARCH("COUNTRY" VARCHAR(2), "INPUT_PLACE" VARCHAR(16777216))
RETURNS TABLE ("PLACES_ID" NUMBER(38,0), "POSTCODE" VARCHAR(16777216), "LOCALITY" VARCHAR(16777216))
LANGUAGE SQL
EXECUTE AS OWNER
AS 
DECLARE
    query VARCHAR DEFAULT 'SELECT PLACES_ID, POSTCODE, LOCALITY 
                           FROM REF_DEV.PUBLIC.PLACES_POSTCODES_SEARCH
                           WHERE SEARCH_KEY LIKE UPPER('''||:COUNTRY||''')||''_''||REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS('''||:INPUT_PLACE||''')||''%''
                           ORDER BY LENGTH(LOCALITY), POSTCODE 
                           LIMIT 50';
    res RESULTSET;
BEGIN
    res := (EXECUTE IMMEDIATE :query);             
    RETURN TABLE(res);
END;

call REF_DEV.PUBLIC.GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_SEARCH('US','Chic');
-- 1.8s --> Attention: déterioration de la performance


SELECT   CASE WHEN DL1.SOVEREIGN IS NULL OR TRIM(DL1.SOVEREIGN)='' THEN UPPER(PL.ISO)
              ELSE UPPER(DL1.SOVEREIGN) 
         END COUNTRY_CODE
        ,PL.PLACES_ID
        ,REPLACE(PL.POSTCODE,' ') AS POSTCODE 
        ,PL.LOCALITY
        ,DL1.LANG1, DL1.LANG2 ,DL1.LANG2  
        ,REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS(PL.LOCALITY) as GENERIC_LOCALITY
        ,PL.PLACES_LANGUAGE, DL1.SOVEREIGN
FROM REF_DEV.REF_GEOGRAPHIQUE.PLACES_DENORM PL
     INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL1 ON (PL.ISO = DL1.ISO)
WHERE IS_POSTAL=1
ORDER BY COUNTRY_CODE
;

select * from REF_DEV.REF_GEOGRAPHIQUE.PLACES
where iso = 'FR' and name_lang1 ilike 'montauban%'
order by id;
-- 475510


select * from REF_DEV.REF_GEOGRAPHIQUE.PLACES_DENORM
where iso = 'FR' and locality ilike 'montauban%'
order by PLACES_ID
;
--1000475510
--1000000000
--

with sel as (
    SELECT   CASE WHEN DL1.SOVEREIGN IS NULL OR TRIM(DL1.SOVEREIGN)='' THEN UPPER(PL.ISO)
                  ELSE UPPER(DL1.SOVEREIGN) 
            END COUNTRY_CODE
            ,PL.PLACES_ID
            ,REPLACE(PL.POSTCODE,' ') AS POSTCODE 
            ,PL.LOCALITY as LOCALITY_ORIGIN
            ,DL1.LANG1, DL1.LANG2 ,DL1.LANG2
            ,case when COUNTRY_CODE = 'FR' then PL.LOCALITY
                  when DL1.LANG1 = 'EN' then PLI.NAME_LANG1
                  when DL1.LANG2 = 'EN' then PLI.NAME_LANG2 
                  when DL1.LANG3 = 'EN' then PLI.NAME_LANG3
                  else PL.LOCALITY
             end as LOCALITY   
            ,PL.PLACES_LANGUAGE, DL1.SOVEREIGN
    FROM REF_DEV.REF_GEOGRAPHIQUE.PLACES_DENORM PL
        INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.PLACES PLI on PLI.ID = PL.PLACES_ID-1000000000
        INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL1 ON (PL.ISO = DL1.ISO)
    WHERE IS_POSTAL=1
)
SELECT COUNTRY_CODE
      ,PLACES_ID
      ,POSTCODE
      ,LOCALITY
      ,REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS(sel.LOCALITY) as GENERIC_LOCALITY
      ,PLACES_LANGUAGE
      ,SOVEREIGN
FROM sel
ORDER BY COUNTRY_CODE
;


CREATE OR REPLACE TRANSIENT TABLE REF_DEV.PUBLIC.PLACES_POSTCODES_SEARCH2 AS
SELECT   CASE WHEN DL1.SOVEREIGN IS NULL OR TRIM(DL1.SOVEREIGN)='' THEN UPPER(PL.ISO)
              ELSE UPPER(DL1.SOVEREIGN) 
         END COUNTRY_CODE
        ,PL.PLACES_ID
        ,REPLACE(PL.POSTCODE,' ') AS POSTCODE 
        ,PL.LOCALITY
        ,REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS(PL.LOCALITY) as GENERIC_LOCALITY
        ,PL.PLACES_LANGUAGE, DL1.SOVEREIGN 
FROM REF_DEV.REF_GEOGRAPHIQUE.PLACES_DENORM PL
     INNER JOIN REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL1 ON (PL.ISO = DL1.ISO)
WHERE IS_POSTAL=1
ORDER BY COUNTRY_CODE, GENERIC_LOCALITY
;

SELECT * FROM REF_DEV.PUBLIC.PLACES_SEARCH2
WHERE COUNTRY_CODE = UPPER('FR')
  AND LOCALITY LIKE CONCAT('Mau','%')
;

SELECT * FROM REF_DEV.PUBLIC.PLACES_SEARCH
WHERE COUNTRY_CODE = UPPER('US')
  AND LOCALITY LIKE CONCAT('San F','%')
ORDER BY LENGTH(LOCALITY), POSTCODE
;


CREATE OR REPLACE PROCEDURE REF_DEV.PUBLIC.GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_SEARCH2("COUNTRY" VARCHAR(2), "INPUT_PLACE" VARCHAR(16777216))
RETURNS TABLE ("PLACES_ID" NUMBER(38,0), "POSTCODE" VARCHAR(16777216), "LOCALITY" VARCHAR(16777216))
LANGUAGE SQL
EXECUTE AS OWNER
AS 
DECLARE
    query VARCHAR DEFAULT 'SELECT PLACES_ID, POSTCODE, LOCALITY 
                           FROM REF_DEV.PUBLIC.PLACES_POSTCODES_SEARCH2
                           WHERE COUNTRY_CODE = UPPER('''||:COUNTRY||''') 
                             AND GENERIC_LOCALITY LIKE REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS('''||:INPUT_PLACE||''')||''%''
                           ORDER BY LENGTH(LOCALITY), POSTCODE
                           LIMIT 50';
    res RESULTSET;
BEGIN
    res := (EXECUTE IMMEDIATE :query);             
    RETURN TABLE(res);
END;
;


call REF_DEV.PUBLIC.GET_ZIP_AND_PLACE_FROM_COUNTRY_AND_PLACE_SEARCH2('US','Chic');
-- 1.1 s
-- 819ms Chic
-- 1.3s Denv


select PL.*
from REF_DEV.REF_GEOGRAPHIQUE.PLACES PL
     inner join REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL on DL.ISO = PL.ISO
where PL.ISO = 'FR' and PL.NAME_LANG1 like 'Montaub%';


select PL.*
from REF_DEV.REF_GEOGRAPHIQUE.PLACES PL
where PL.NAME_LANG1 like 'Hong Kong%';

select PL.*
from REF_DEV.REF_GEOGRAPHIQUE.PLACES PL
where PL.NAME_LANG1 like 'Chicago%' and iso='US';





with selPL as (
  select PL.*
  from REF_DEV.REF_GEOGRAPHIQUE.PLACES PL
      inner join REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL on DL.ISO = PL.ISO
  where PL.ISO = 'FR' and PL.NAME_LANG1 like 'Montaub%'
)
select sPL.ISO, PPC.PLACE_ID, sPL.NAME_LANG1, PPC.POSTCODE_ID, PC.POSTCODE
from selPL sPL
     inner join REF_DEV.REF_GEOGRAPHIQUE.PLACES_POSTCODES PPC on PPC.ISO = SPL.ISO and PPC.PLACE_ID = SPL.ID 
     inner join REF_DEV.REF_GEOGRAPHIQUE.POSTCODES PC on PC.ISO = SPL.ISO and PC.ID = PPC.POSTCODE_ID
QUALIFY ROW_NUMBER() OVER (PARTITION BY sPL.ISO, PPC.PLACE_ID ORDER BY PC.POSTCODE) = 1
order by 1,3,5
;


select CASE WHEN DL.SOVEREIGN IS NULL OR TRIM(DL.SOVEREIGN)='' THEN UPPER(PL.ISO)
              ELSE UPPER(DL.SOVEREIGN) 
       END COUNTRY_CODE,
       PL.ISO, DL.NAME_EN as ISO_NAME, DL.SOVEREIGN,
       PL.ID as PLACE_ID, PL.NAME_LANG1 as PLACE_NAME,
       CASE WHEN COUNTRY_CODE = 'FR' AND DL.LANG1 = COUNTRY_CODE THEN PL.NAME_LANG1
            WHEN COUNTRY_CODE = 'FR' AND DL.LANG2 = COUNTRY_CODE THEN PL.NAME_LANG2
            WHEN COUNTRY_CODE = 'FR' AND DL.LANG3 = COUNTRY_CODE THEN PL.NAME_LANG3
            WHEN COUNTRY_CODE <> 'FR' AND DL.LANG1 = 'EN' THEN PL.NAME_LANG1
            WHEN COUNTRY_CODE <> 'FR' AND DL.LANG2 = 'EN' THEN PL.NAME_LANG2
            WHEN COUNTRY_CODE <> 'FR' AND DL.LANG3 = 'EN' THEN PL.NAME_LANG3
            ELSE PL.NAME_LANG1
       END AS LOCALITY,  
       PL.NAME_LANG1, DL.LANG1,
       PL.NAME_LANG2, DL.LANG2,
       PL.NAME_LANG3, DL.LANG3,
       REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS(LOCALITY) as NEUTRAL_LOCALITY,
       PPC.POSTCODE_ID, PC.POSTCODE,
       REPLACE(PC.POSTCODE,' ') AS NEUTRAL_POSTCODE 
from REF_DEV.REF_GEOGRAPHIQUE.PLACES PL
     inner join REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL on DL.ISO = PL.ISO
     left outer join REF_DEV.REF_GEOGRAPHIQUE.PLACES_POSTCODES PPC on PPC.ISO = PL.ISO and PPC.PLACE_ID = PL.ID and PPC.IS_POSTAL = 1 
     left outer join REF_DEV.REF_GEOGRAPHIQUE.POSTCODES PC on PC.ISO = PPC.ISO and PC.ID = PPC.POSTCODE_ID 
where COUNTRY_CODE = 'CN' and LOCALITY like 'Beijing%'
QUALIFY ROW_NUMBER() OVER (PARTITION BY COUNTRY_CODE, PL.ID ORDER BY nvl(PC.POSTCODE,'')) = 1
order by COUNTRY_CODE, LOCALITY, nvl(PC.POSTCODE,'')
;

CREATE OR REPLACE TRANSIENT TABLE REF_DEV.PUBLIC.COUNTRY_PLACES_SEARCH AS
select CASE WHEN DL.SOVEREIGN IS NULL OR TRIM(DL.SOVEREIGN)='' THEN UPPER(PL.ISO)
              ELSE UPPER(DL.SOVEREIGN) 
       END COUNTRY_CODE,
       PL.ID as PLACE_ID, PL.NAME_LANG1 as PLACE_NAME,
       CASE WHEN COUNTRY_CODE = 'FR' AND DL.LANG1 = COUNTRY_CODE THEN PL.NAME_LANG1
            WHEN COUNTRY_CODE = 'FR' AND DL.LANG2 = COUNTRY_CODE THEN PL.NAME_LANG2
            WHEN COUNTRY_CODE = 'FR' AND DL.LANG3 = COUNTRY_CODE THEN PL.NAME_LANG3
            WHEN COUNTRY_CODE <> 'FR' AND DL.LANG1 = 'EN' THEN PL.NAME_LANG1
            WHEN COUNTRY_CODE <> 'FR' AND DL.LANG2 = 'EN' THEN PL.NAME_LANG2
            WHEN COUNTRY_CODE <> 'FR' AND DL.LANG3 = 'EN' THEN PL.NAME_LANG3
            ELSE PL.NAME_LANG1
       END AS LOCALITY,  
       REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS(LOCALITY) as NEUTRAL_LOCALITY,
       PPC.POSTCODE_ID, PC.POSTCODE,
       REPLACE(PC.POSTCODE,' ') AS NEUTRAL_POSTCODE 
from REF_DEV.REF_GEOGRAPHIQUE.PLACES PL
     inner join REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL on DL.ISO = PL.ISO
     left outer join REF_DEV.REF_GEOGRAPHIQUE.PLACES_POSTCODES PPC on PPC.ISO = PL.ISO and PPC.PLACE_ID = PL.ID and PPC.IS_POSTAL = 1  
     left outer join REF_DEV.REF_GEOGRAPHIQUE.POSTCODES PC on PC.ISO = PPC.ISO and PC.ID = PPC.POSTCODE_ID
QUALIFY ROW_NUMBER() OVER (PARTITION BY COUNTRY_CODE, PL.ID ORDER BY nvl(NEUTRAL_POSTCODE,'')) = 1
order by COUNTRY_CODE, NEUTRAL_LOCALITY, nvl(NEUTRAL_POSTCODE,'')
;

select count(1) from REF_DEV.PUBLIC.COUNTRY_PLACES_SEARCH;
-- 3 858 264

SELECT * FROM REF_DEV.PUBLIC.COUNTRY_PLACES_SEARCH
WHERE COUNTRY_CODE = 'FR'
  AND NEUTRAL_LOCALITY LIKE REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS('Montaub')||'%'
ORDER BY LENGTH(LOCALITY)
LIMIT 50
;
-- 1,1s ; 1,2s ; 1,3 s


SELECT * FROM REF_DEV.PUBLIC.COUNTRY_PLACES_SEARCH
WHERE COUNTRY_CODE = 'FR'
  AND NEUTRAL_LOCALITY LIKE REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS('Montau')||'%'
ORDER BY LENGTH(LOCALITY)
LIMIT 50
;

SELECT * FROM REF_DEV.PUBLIC.COUNTRY_PLACES_SEARCH
WHERE COUNTRY_CODE = 'MX'
  AND NEUTRAL_LOCALITY LIKE REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS('Cancu')||'%'
ORDER BY LENGTH(LOCALITY)
LIMIT 50
;

SELECT * FROM REF_DEV.PUBLIC.COUNTRY_PLACES_SEARCH
WHERE COUNTRY_CODE = 'FR'
  AND NEUTRAL_LOCALITY LIKE REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS('Saint-Va')||'%'
ORDER BY LENGTH(LOCALITY)
LIMIT 50
;

-- Saint-Valery-en-Caux


SELECT * FROM REF_DEV.PUBLIC.COUNTRY_PLACES_SEARCH
WHERE COUNTRY_CODE = 'FR'
  AND NEUTRAL_LOCALITY LIKE REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS('Caussad')||'%'
ORDER BY LENGTH(LOCALITY)
LIMIT 50
;


CREATE OR REPLACE PROCEDURE REF_DEV.PUBLIC.GET_PLACES_FROM_COUNTRY_AND_PLACE_BEGINNING("COUNTRY" VARCHAR(2), "INPUT_PLACE" VARCHAR(16777216))
RETURNS TABLE ("PLACE_ID" NUMBER(38,0), "LOCALITY" VARCHAR(16777216), "POSTCODE" VARCHAR(16777216))
LANGUAGE SQL
EXECUTE AS OWNER
AS 
DECLARE
    query VARCHAR DEFAULT 'SELECT PLACE_ID, LOCALITY, POSTCODE 
                           FROM REF_DEV.PUBLIC.COUNTRY_PLACES_SEARCH
                           WHERE COUNTRY_CODE = UPPER('''||:COUNTRY||''') 
                             AND NEUTRAL_LOCALITY LIKE REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS('''||:INPUT_PLACE||''')||''%''
                           ORDER BY LENGTH(LOCALITY)
                           LIMIT 50';
    res RESULTSET;
BEGIN
    res := (EXECUTE IMMEDIATE :query);             
    RETURN TABLE(res);
END;
;


call REF_DEV.PUBLIC.GET_PLACES_FROM_COUNTRY_AND_PLACE_BEGINNING('US','Chic');
-- 926 ms ; 1,3 s


CREATE OR REPLACE TRANSIENT TABLE REF_DEV.PUBLIC.COUNTRY_PLACE_POSTCODES_SEARCH AS
select CASE WHEN DL.SOVEREIGN IS NULL OR TRIM(DL.SOVEREIGN)='' THEN UPPER(PL.ISO)
              ELSE UPPER(DL.SOVEREIGN) 
       END COUNTRY_CODE,
       PL.ID as PLACE_ID, PL.NAME_LANG1 as PLACE_NAME,
       CASE WHEN COUNTRY_CODE = 'FR' AND DL.LANG1 = COUNTRY_CODE THEN PL.NAME_LANG1
            WHEN COUNTRY_CODE = 'FR' AND DL.LANG2 = COUNTRY_CODE THEN PL.NAME_LANG2
            WHEN COUNTRY_CODE = 'FR' AND DL.LANG3 = COUNTRY_CODE THEN PL.NAME_LANG3
            WHEN COUNTRY_CODE <> 'FR' AND DL.LANG1 = 'EN' THEN PL.NAME_LANG1
            WHEN COUNTRY_CODE <> 'FR' AND DL.LANG2 = 'EN' THEN PL.NAME_LANG2
            WHEN COUNTRY_CODE <> 'FR' AND DL.LANG3 = 'EN' THEN PL.NAME_LANG3
            ELSE PL.NAME_LANG1
       END AS LOCALITY,  
       REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS(LOCALITY) as NEUTRAL_LOCALITY,
       PPC.POSTCODE_ID, PC.POSTCODE,
       REPLACE(PC.POSTCODE,' ') AS NEUTRAL_POSTCODE 
from REF_DEV.REF_GEOGRAPHIQUE.PLACES PL
     inner join REF_DEV.REF_GEOGRAPHIQUE.DATA_LANGUAGES DL on DL.ISO = PL.ISO
     inner join REF_DEV.REF_GEOGRAPHIQUE.PLACES_POSTCODES PPC on PPC.ISO = PL.ISO and PPC.PLACE_ID = PL.ID 
     inner join REF_DEV.REF_GEOGRAPHIQUE.POSTCODES PC on PC.ISO = PPC.ISO and PC.ID = PPC.POSTCODE_ID
where PPC.IS_POSTAL = 1  
order by COUNTRY_CODE, PLACE_ID, nvl(NEUTRAL_POSTCODE,'')
;

select count(1) from REF_DEV.PUBLIC.COUNTRY_PLACE_POSTCODES_SEARCH;
-- 11 504 639

SELECT * FROM REF_DEV.PUBLIC.COUNTRY_PLACE_POSTCODES_SEARCH
WHERE COUNTRY_CODE = 'FR'
  AND PLACE_ID = 500054
  AND NEUTRAL_POSTCODE LIKE REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS('820')||'%'
;
-- 506 ms

CREATE OR REPLACE PROCEDURE REF_DEV.PUBLIC.GET_POSITION_FROM_COUNTRY_AND_PLACE_POSTCODE_BEGINNING("COUNTRY" VARCHAR(2), "PPLACE_ID" NUMBER(38,0), "INPUT_POST_CODE" VARCHAR(16777216) )
RETURNS TABLE ("PLACE_ID" NUMBER(38,0), "LOCALITY" VARCHAR(16777216), "POSTCODE" VARCHAR(16777216))
LANGUAGE SQL
EXECUTE AS OWNER
AS 
DECLARE
    query VARCHAR DEFAULT 'SELECT PLACE_ID, LOCALITY, POSTCODE 
                           FROM REF_DEV.PUBLIC.COUNTRY_PLACE_POSTCODES_SEARCH
                           WHERE COUNTRY_CODE = '''||:COUNTRY||''' 
                             AND PLACE_ID = '||:PPLACE_ID||'
                             AND NEUTRAL_POSTCODE LIKE REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS('''||:INPUT_POST_CODE||''')||''%''
                           ORDER BY LENGTH(LOCALITY)
                           LIMIT 50';
    res RESULTSET;
BEGIN
    res := (EXECUTE IMMEDIATE :query);             
    RETURN TABLE(res);
END;
;

call REF_DEV.PUBLIC.GET_POSITION_FROM_COUNTRY_AND_PLACE_POSTCODE_BEGINNING('US',5547594,'60'); -- Chicago
-- 1,1 s


CREATE OR REPLACE PROCEDURE REF_DEV.PUBLIC.GET_POSTCODES_FROM_COUNTRY_AND_PLACE("COUNTRY" VARCHAR(2), "PPLACE_ID" NUMBER(38,0))
RETURNS TABLE ("PLACE_ID" NUMBER(38,0), "LOCALITY" VARCHAR(16777216), "POSTCODE" VARCHAR(16777216))
LANGUAGE SQL
EXECUTE AS OWNER
AS 
DECLARE
    query VARCHAR DEFAULT 'SELECT PLACE_ID, LOCALITY, POSTCODE 
                           FROM REF_DEV.PUBLIC.COUNTRY_PLACE_POSTCODES_SEARCH
                           WHERE COUNTRY_CODE = '''||:COUNTRY||''' 
                             AND PLACE_ID = '||:PPLACE_ID||'
                           ORDER BY NEUTRAL_POSTCODE
                           LIMIT 50';
    res RESULTSET;
BEGIN
    res := (EXECUTE IMMEDIATE :query);             
    RETURN TABLE(res);
END;
;

call REF_DEV.PUBLIC.GET_POSTCODES_FROM_COUNTRY_AND_PLACE('US',5547594); -- Chicago
-- 931 ms



