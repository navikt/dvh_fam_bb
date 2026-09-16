with bb_forskudd_perioder as (
    select * from {{ref ('stg_bb_forskudd_periode')}}
),

fagsak as (
    select vedtaks_id, pk_bb_fagsak, kafka_offset, fk_person1_kravhaver, SAKSNR
    from {{ref ('int_bb_forskudd_fagsak')}}
),

final as (
    select
        to_date(periode_fra,'yyyy-mm-dd') as periode_fra
       ,to_date(periode_til,'yyyy-mm-dd') as periode_til
       ,belop
       ,fagsak.vedtaks_id
       ,fagsak.saksnr
       ,fagsak.fk_person1_kravhaver
       ,resultat
       ,barnets_alders_gruppe
       ,antall_barn_i_egen_husstand
       ,sivilstand
       ,case
           when barn_bor_med_mottaker = 'true' then '1'
           when barn_bor_med_mottaker = 'false' then '0'
           else barn_bor_med_mottaker  
        end barn_bor_med_mottaker
       ,fp.kafka_offset
       ,fagsak.pk_bb_fagsak as fk_bb_fagsak
    from bb_forskudd_perioder fp
    join fagsak
    on fp.kafka_offset = fagsak.kafka_offset
    and fp.vedtaks_id = fagsak.vedtaks_id
)

select 
    STANDARD_HASH(vedtaks_id || '|' || fk_person1_kravhaver || '|' || periode_fra,'MD5') AS pk_bb_forskudd_periode
    ,periode_fra
    ,periode_til
    ,belop
    ,resultat
    ,barnets_alders_gruppe
    ,antall_barn_i_egen_husstand
    ,sivilstand
    ,barn_bor_med_mottaker
    ,kafka_offset
    ,fk_bb_fagsak
from final
