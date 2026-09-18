
{{
    config(
        materialized='incremental'
    )
}}

with perioder as (
    select * from {{ref ('int_bb_bidrag_periode')}}
)

select 
    pk_bb_bidrag_periode
    ,fk_bb_fagsak
    ,periode_fra
    ,periode_til
    ,belop
    ,resultat
    ,valutakode
    ,bidragsevne
    ,underholdskostnad
    ,samvaersfradrag
    ,netto_tilsynsutgift
    ,faktisk_tilsynsutgift
    ,netto_barnetillegg_bp
    ,netto_barnetillegg_bm
    ,samvaersklasse
    ,bps_andel_underholdskostnad
    ,bpbor_med_andre_voksne
    ,kafka_offset
    ,localtimestamp as lastet_dato    
from perioder

{% if is_incremental() %}
    WHERE kafka_offset > COALESCE(( SELECT MAX(t.kafka_offset) FROM {{ this }} t ), 0)
{% endif %}

