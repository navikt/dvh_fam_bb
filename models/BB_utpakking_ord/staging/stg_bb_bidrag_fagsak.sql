with bb_meta_data as (
    select 
        pk_bb_meta_data, kafka_offset, melding
    from {{ref ('stg_bb_bidrag_meta_data')}}
),

final as (
    select * from bb_meta_data,
    json_table(melding, '$'
        COLUMNS (
            vedtaks_id          varchar2(255) path '$.vedtaksid'
            ,vedtakstidspunkt   timestamp(9)  path '$.vedtakstidspunkt'
            ,behandlings_type   varchar2(255) path '$.type'
            ,saksnr             varchar2(255) path '$.saksnr'
            ,fnr_skyldner       varchar2(255) path '$.skyldner'
            ,fnr_kravhaver      varchar2(255) path '$.kravhaver'
            ,fnr_mottaker       varchar2(255) path '$.mottaker'
            ,historisk_vedtak   varchar2(255) path '$.historiskVedtak'
            ,innkreving_flagg   varchar2(255) path '$.innkreving'
            ,stonadstype        varchar2(255) path '$.stønadstype'
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
