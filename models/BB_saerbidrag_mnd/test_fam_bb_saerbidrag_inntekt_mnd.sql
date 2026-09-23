{{
    config(
        materialized='table'
    )
}}

/* 
Henter alle inntekter.
*/

with inn as (
    select * from {{ref ('fam_bb_saerbidrag_inntekt')}}
),
 
/* 
Pivoterer ut inntekt for personene i hver sin kolonne, og summerer på inntekttype.
*/

final as (
 SELECT * 
FROM ( 
    SELECT
    fk_bb_saerbidrag_fagsak,
    saksnr,
    vedtaks_id,
    vedtakstidspunkt,
    type_inntekt,
    inntekt_kategori,
    inntekt_for,
    inntekt_belop,
    lastet_dato as mart_lastet_dato
    FROM inn
) 
PIVOT ( 
    SUM(inntekt_belop)  
    FOR inntekt_for IN ( 
        'M' AS inntekt_mottaker,
        'P' AS inntekt_skyldner,
        'K' as inntekt_kravhaver
    ) 
) piv
)

/* 
Slutt-tabellen med utvalgte kolonner, gyldig_flagg og lastet_dato.
*/

select     
    RAWTOHEX(fk_bb_saerbidrag_fagsak)  as key_fak_bb_saerbidrag,
    vedtaks_id,
    saksnr,
    vedtakstidspunkt,
    type_inntekt,
    inntekt_kategori,
    inntekt_mottaker,
    inntekt_skyldner,
    inntekt_kravhaver,
    '{{ var("gyldig_flagg") }}'  as gyldig_flagg,
    mart_lastet_dato,
    localtimestamp as lastet_dato  
 from final