with saer as (
    select * 
    from {{ ref('fam_bb_saerbidrag_inntekt_mnd') }}
   where gyldig_flagg = 1 
),

final as (
    select 
    KEY_FAK_BB_SAERBIDRAG,
    VEDTAKS_ID,
    aar_maaned,
    SAKSNR,
    VEDTAKSTIDSPUNKT,
    TYPE_INNTEKT,
    INNTEKT_KATEGORI,
    INNTEKT_MOTTAKER,
    INNTEKT_SKYLDNER,
    INNTEKT_KRAVHAVER,
    --GYLDIG_FLAGG,
    MART_LASTET_DATO,
    LASTET_DATO,
    'SÆRBIDRAG' as stonad_type
    from saer
    -- UNION med andre inntekter
)

select * from final