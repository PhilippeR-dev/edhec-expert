CREATE OR REPLACE FUNCTION REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS(N text)
 RETURNS TEXT
 LANGUAGE JAVASCRIPT
 AS $$
   N = N.normalize("NFD").replace(/\p{Diacritic}/gu, "");
   return N;
  $$;


select 
  --'Crème brulée' as texte
  --'Québec' as texte
  'Cancún' as texte
  ,REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS(texte) as texte_neutre
  ,REGEXP_REPLACE(trim(texte_neutre), '\\s+', ' ', 1, 0) as texte_neutre_sans_multi_espace
  ,UPPER(texte_neutre_sans_multi_espace) as texte_neutre_upper
;

SELECT REGEXP_REPLACE('Votre chaîne avec   plusieurs   espaces', '\\s+', ' ', 1, 0) AS chaine_modifiee;


CREATE OR REPLACE FUNCTION REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS(ptest text)
 RETURNS TEXT
 LANGUAGE SQL
 AS 
 $$
  SELECT UPPER(TRANSLATE(REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS(ptest),' -',''))
 $$;

  select 
  --'Crème brulée' as texte
  --'Québec' as texte
  --'Cancún' as texte
  --'San Fransico' as texte
  'Saint-Maur-des-Fossés' as texte
  ,REF_DEV.PUBLIC.REMOVE_SPECIAL_CHARS_PLUS(texte) as texte_search
;