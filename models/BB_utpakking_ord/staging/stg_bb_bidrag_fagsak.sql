with bb_meta_data as (
    select 
        pk_bb_meta_data, kafka_offset, melding
    from {{ref ('stg_bb_bidrag_meta_data')}}
),

final as (
    select * from bb_meta_data,
    json_table(melding, '$'
        COLUMNS (
            vedtaks_id          VARCHAR2(255 CHAR) PATH '$.vedtaksid'
            ,vedtakstidspunkt   timestamp  PATH '$.vedtakstidspunkt'
            ,behandlings_type   VARCHAR2(255 CHAR) PATH '$.type'
            ,saksnr             VARCHAR2(255 CHAR) PATH '$.saksnr'
            ,fnr_skyldner       VARCHAR2(255 CHAR) PATH '$.skyldner'
            ,fnr_kravhaver      VARCHAR2(255 CHAR) PATH '$.kravhaver'
            ,fnr_mottaker       VARCHAR2(255 CHAR) PATH '$.mottaker'
            ,historisk_vedtak   VARCHAR2(255 CHAR) PATH '$.historiskVedtak'
            ,innkreving_flagg   VARCHAR2(255 CHAR) PATH '$.innkreving'
            ,stonadstype        VARCHAR2(255 CHAR) PATH '$.stønadstype'
        )
    ) j 
)

select 
    kafka_offset
    ,vedtaks_id
    ,vedtakstidspunkt
    ,behandlings_type
    ,saksnr
    ,fnr_skyldner 
    ,fnr_kravhaver
    ,fnr_mottaker
    ,historisk_vedtak
    ,innkreving_flagg
    ,stonadstype
    ,pk_bb_meta_data as fk_bb_meta_data
from final
