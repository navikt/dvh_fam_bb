with inntekt as (
    select *
    from {{ref ('stg_bb_forskudd_inntekt')}}
),

bb_fagsak as (
    select vedtaks_id, pk_bb_fagsak, kafka_offset, fk_person1_kravhaver, vedtakstidspunkt
    from {{ref ('int_bb_forskudd_fagsak')}}
),


final as (
    select
        i.type_inntekt
        ,i.inntekt
        ,i.inntekt_kategori
        ,i.gjelder_kravhaver
        ,STANDARD_HASH(fs.vedtaks_id || '|' || fs.fk_person1_kravhaver || '|' || i.periode_fra,'MD5') AS fk_bb_forskudd_periode
        ,i.periode_fra
        ,i.periode_til
        ,i.kafka_offset
        ,fs.vedtaks_id
        ,fs.fk_person1_kravhaver
    from inntekt i
    inner join bb_fagsak fs
        on i.kafka_offset = fs.kafka_offset
        and i.vedtaks_id = fs.vedtaks_id
)

select 
    standard_hash(vedtaks_id || '|' || type_inntekt || '|' || inntekt_kategori || '|' || periode_fra || '|' || gjelder_kravhaver || '|' || fk_person1_kravhaver,'MD5') pk_bb_inntekt
    ,f.*
from final f