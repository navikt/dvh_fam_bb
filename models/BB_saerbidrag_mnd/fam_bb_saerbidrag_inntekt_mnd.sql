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

inn_piv as (
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
    valuta_kode,
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
),

/* 
Valutakonvertering av inntekt, basert på siste tilgjengelige kurs ved månedslutt. Det vil si siste dag i mnd - 1, da kurser fra norges bank
tilgjengeliggjøres kl 16.
*/

inn_med_valuta_kon as (
    select t1.*
    ,case when t1.valuta_kode ='NOK' then t1.inntekt_mottaker else  (t1.inntekt_mottaker * t3.kurs ) / t3.valutamengde end as inntekt_mottaker_nok
    ,case when t1.valuta_kode ='NOK' then t1.inntekt_skyldner else  (t1.inntekt_skyldner * t3.kurs ) / t3.valutamengde end as inntekt_skyldner_nok
    ,case when t1.valuta_kode ='NOK' then t1.inntekt_kravhaver else  (t1.inntekt_kravhaver * t3.kurs ) / t3.valutamengde end as inntekt_kravhaver_nok
    from inn_piv t1
    left join {{ ref('dim_siste_dato_mnd') }} t2
    on concat(TO_CHAR(t1.vedtakstidspunkt, 'yyyymm'),'003') = t2.pk_dim_tid
    left join  (
        select valuta
            ,valutamengde
            ,kurs
            ,gyldig_fra_dato 
        from {{ source('kode_verk', 'valutakurser') }}
        where frekvens = 'DAG' 
        and kvoteringsvaluta = 'NOK'
      ) t3
    on t1.valuta_kode = t3.valuta 
    and t2.valuta_siste_kurs_dato_i_mnd = t3.gyldig_fra_dato

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
    valuta_kode,
    inntekt_mottaker,
    inntekt_skyldner,
    inntekt_kravhaver,
    inntekt_mottaker_nok,
    inntekt_skyldner_nok,
    inntekt_kravhaver_nok,
    '{{ var("gyldig_flagg") }}'  as gyldig_flagg,
    mart_lastet_dato,
    localtimestamp as lastet_dato  
 from inn_med_valuta_kon