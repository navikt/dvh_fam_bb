with saer as (
    select * 
    from {{ ref('fam_bb_saerbidrag_inntekt_mnd') }}
   where gyldig_flagg = 1 
),

final as (
    select 
    KEY_FAK_BB_SAERBIDRAG,
    VEDTAKS_ID,
    SAKSNR,
    VEDTAKSTIDSPUNKT,
    TYPE_INNTEKT,
    INNTEKT_KATEGORI,
    VALUTA_KODE,
    INNTEKT_MOTTAKER,
    INNTEKT_SKYLDNER,
    INNTEKT_KRAVHAVER,
    INNTEKT_MOTTAKER_NOK,
    INNTEKT_SKYLDNER_NOK,
    INNTEKT_KRAVHAVER_NOK,
    --GYLDIG_FLAGG,
    MART_LASTET_DATO,
    LASTET_DATO,
    'SÆRBIDRAG' as stonad_type
    from saer
    -- UNION med andre inntekter
)

select * from final