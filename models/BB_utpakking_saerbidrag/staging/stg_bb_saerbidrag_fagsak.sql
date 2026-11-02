with bb_meta_data as (
    select * from {{ref ('stg_bb_saerbidrag_meta_data')}}
),
 
pre_final as (
    select * from bb_meta_data
        ,json_table(melding, '$'
            columns (
                saksnr                  VARCHAR2(255 CHAR)  PATH '$.saksnr'
                ,referanse              VARCHAR2(255 CHAR)  PATH '$.referanse'
                ,vedtaks_id             VARCHAR2(255 CHAR)  PATH '$.vedtaksid'
                ,omgjor_vedtaks_id      VARCHAR2(255 CHAR)  PATH '$.omgjørVedtakId'
                ,vedtakstidspunkt       TIMESTAMP(3)        PATH '$.vedtakstidspunkt'
                ,behandlings_type       varchar2(50 char)   PATH '$.type'
                ,kategori               VARCHAR2(255 CHAR)  PATH '$.kategori'
                ,skyldner               VARCHAR2(255 CHAR)  PATH '$.skyldner'
                ,kravhaver              VARCHAR2(255 CHAR)  PATH '$.kravhaver'
                ,mottaker               VARCHAR2(255 CHAR)  PATH '$.mottaker'
                ,innkreving_flagg       VARCHAR2(255 CHAR)  PATH '$.innkreving'
                ,historisk_vedtak       VARCHAR2(255 CHAR)  PATH '$.historiskVedtak'
                ,resultat               VARCHAR2(255 CHAR)  PATH '$.resultat'
                ,valuta_kode            VARCHAR2(5 CHAR)    PATH '$.valutakode'
                ,belop                  NUMBER              PATH '$.beløp'
                ,krav_belop             NUMBER              PATH '$.kravbeløp'
                ,godkjent_belop         NUMBER              PATH '$.godkjentBeløp'
                ,betalt_belop           NUMBER              PATH '$.betaltBeløp'
               )
        ) j
),


final as (
    select kafka_offset
        ,pk_bb_meta_data as fk_bb_meta_data
        ,saksnr
        ,referanse
        ,vedtaks_id
        ,omgjor_vedtaks_id
        ,vedtakstidspunkt
        ,behandlings_type
        ,kategori
        ,skyldner
        ,kravhaver
        ,mottaker
        ,innkreving_flagg
        ,historisk_vedtak
        ,resultat
        ,valuta_kode
        ,belop
        ,krav_belop
        ,godkjent_belop
        ,betalt_belop
    from pre_final
)

select * from final
 