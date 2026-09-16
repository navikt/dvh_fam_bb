with bb_bidrag_perioder as (
    select * from {{ref ('stg_bb_bidrag_periode')}}
),

fagsak as (
    select vedtaks_id, pk_bb_fagsak, kafka_offset, fk_person1_kravhaver, saksnr, stonadstype
    from {{ref ('int_bb_bidrag_fagsak')}}
),

final as (
    select
        periode_fra--to_date(periode_fra,'yyyy-mm-dd') as periode_fra
        ,periode_til--to_date(periode_til,'yyyy-mm-dd') as periode_til
        ,belop
        ,fagsak.vedtaks_id
        ,fagsak.saksnr
        ,fagsak.fk_person1_kravhaver
        ,fagsak.stonadstype
        ,valutakode  
        ,resultat
        ,bidragsevne
        ,underholdskostnad
        ,samvaersfradrag
        ,netto_barnetillegg_bp
        ,netto_barnetillegg_bm
        ,samvaersklasse
        ,bps_andel_underholdskostnad
        ,CASE
            WHEN bpbor_med_andre_voksne = 'true' THEN '1'
            WHEN bpbor_med_andre_voksne = 'false' THEN '0'
            ELSE bpbor_med_andre_voksne  
        END bpbor_med_andre_voksne
        ,netto_tilsynsutgift
        ,faktisk_tilsynsutgift 
        ,bb_bidrag_perioder.kafka_offset
        ,fagsak.pk_bb_fagsak as fk_bb_fagsak
    from bb_bidrag_perioder
    join fagsak
        on bb_bidrag_perioder.kafka_offset = fagsak.kafka_offset
        and bb_bidrag_perioder.vedtaks_id = fagsak.vedtaks_id
)

select 
    STANDARD_HASH(vedtaks_id || '|' || fk_person1_kravhaver || '|' || periode_fra || '|' || stonadstype,'MD5') AS pk_bb_bidrag_periode
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
from final

