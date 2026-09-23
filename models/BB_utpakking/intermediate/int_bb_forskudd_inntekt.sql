with inntekt as (
    select *
    from {{ref ('stg_bb_forskudd_inntekt')}}
),

fagsak as (
    select vedtaks_id, pk_bb_fagsak, kafka_offset, fk_person1_kravhaver, vedtakstidspunkt
    from {{ref ('int_bb_forskudd_fagsak')}}
),


final as (
    select
        distinct STANDARD_HASH(fs.vedtaks_id || '|' || fs.fk_person1_kravhaver || '|' || i.periode_fra,'MD5') as fk_bb_forskudd_periode
        ,fs.fk_person1_kravhaver
        ,i.type_inntekt
        ,i.inntekt
        ,i.inntekt_kategori
        ,i.gjelder_kravhaver
        ,i.periode_fra
        ,i.periode_til
        ,i.inntekt_for
        ,i.kafka_offset
        ,fs.vedtaks_id
    from inntekt i
    inner join fagsak fs
        on i.vedtaks_id = fs.vedtaks_id
        and i.kafka_offset = fs.kafka_offset
)

select 
    standard_hash(vedtaks_id || '|' || type_inntekt || '|' || inntekt_kategori || '|' || periode_fra || '|' || inntekt_for || '|' || gjelder_kravhaver || '|' || fk_person1_kravhaver,'MD5') as pk_bb_inntekt
    ,fk_bb_forskudd_periode    
    ,fk_person1_kravhaver
    ,type_inntekt
    ,inntekt
    ,inntekt_kategori
    ,periode_fra
    ,periode_til
    ,inntekt_for
    ,kafka_offset
    ,vedtaks_id
from final 