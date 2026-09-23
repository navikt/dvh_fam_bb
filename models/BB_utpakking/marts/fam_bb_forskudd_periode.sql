
{{
    config(
        materialized='incremental'
    )
}}

with perioder as (
    select * from {{ref ('int_bb_forskudd_periode')}}
)

select 
    pk_bb_forskudd_periode
    ,fk_bb_fagsak
    ,periode_fra
    ,periode_til
    ,belop
    ,resultat
    ,barnets_alders_gruppe
    ,antall_barn_i_egen_husstand
    ,sivilstand
    ,barn_bor_med_mottaker
    ,kafka_offset
    ,localtimestamp as lastet_dato
from perioder

{% if is_incremental() %}
    WHERE kafka_offset > COALESCE(( SELECT MAX(t.kafka_offset) FROM {{ this }} t ), 0)
{% endif %}

