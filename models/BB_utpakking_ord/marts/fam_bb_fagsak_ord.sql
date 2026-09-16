{{
    config(
        materialized='incremental'
    )
}}

with fagsak as (
    select * from {{ref ('int_bb_bidrag_fagsak')}}
)

select 
    pk_bb_fagsak,
    vedtaks_id,
    kafka_offset,
    vedtakstidspunkt,
    behandlings_type,
    saksnr,
    innkreving_flagg,
    fk_person1_skyldner,
    fk_person1_kravhaver,
    fk_person1_mottaker,
    historisk_vedtak,
    stonadstype,
    fk_bb_meta_data,
    localtimestamp as lastet_dato
from fagsak

{% if is_incremental() %}
    WHERE kafka_offset > COALESCE(( SELECT MAX(t.kafka_offset) FROM {{ this }} t ), 0)
{% endif %}
