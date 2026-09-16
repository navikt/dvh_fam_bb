{{
    config(
        materialized='incremental'
    )
}}

with inntekter as (
    select * from {{ref ('int_bb_bidrag_inntekt')}}
)


select
    pk_bb_inntekt
   ,fk_bb_bidrag_periode
   ,type_inntekt
   ,inntekt
   ,inntekt_kategori
   ,flagg
   ,kafka_offset
   ,localtimestamp as lastet_dato
from inntekter

{% if is_incremental() %}
    WHERE kafka_offset > COALESCE(( SELECT MAX(t.kafka_offset) FROM {{ this }} t ), 0)
{% endif %}