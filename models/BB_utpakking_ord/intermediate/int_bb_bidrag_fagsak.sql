with fagsak as (
    select * from {{ref ('stg_bb_bidrag_fagsak')}}
),

final as (
    select distinct 
        fagsak.vedtaks_id,
        fagsak.behandlings_type,
        --fagsak.fnr_skyldner,
        fagsak.saksnr,
        --fagsak.fnr_kravhaver,
        --fagsak.fnr_mottaker,
        fagsak.innkreving_flagg,
        fagsak.stonadstype,
        fagsak.fk_bb_meta_data,
        fagsak.vedtakstidspunkt,
        fagsak.historisk_vedtak,
        nvl(ident_skyldner.fk_person1, -1) as fk_person1_skyldner,
        nvl(ident_krav.fk_person1, -1) as fk_person1_kravhaver,
        nvl(ident_mottaker.fk_person1, -1) as fk_person1_mottaker,
        fagsak.kafka_offset
    from fagsak
    left join {{ source ('person', 'ident_off_id_til_fk_person1') }} ident_krav
        on fagsak.fnr_kravhaver = ident_krav.off_id
        and TRUNC(fagsak.vedtakstidspunkt, 'DD') >= ident_krav.gyldig_fra_dato
        and TRUNC(fagsak.vedtakstidspunkt, 'DD') <= ident_krav.gyldig_til_dato
    left join {{ source ('person', 'ident_off_id_til_fk_person1') }} ident_mottaker
        on fagsak.fnr_mottaker = ident_mottaker.off_id
        and TRUNC(fagsak.vedtakstidspunkt, 'DD') >= ident_mottaker.gyldig_fra_dato
        and TRUNC(fagsak.vedtakstidspunkt, 'DD') <= ident_mottaker.gyldig_til_dato
    left join {{ source ('person', 'ident_off_id_til_fk_person1') }} ident_skyldner
        on fagsak.fnr_skyldner = ident_skyldner.off_id
        and TRUNC(fagsak.vedtakstidspunkt, 'DD') >= ident_skyldner.gyldig_fra_dato
        and TRUNC(fagsak.vedtakstidspunkt, 'DD') <= ident_skyldner.gyldig_til_dato
)

select 
    STANDARD_HASH(vedtaks_id || '|' || fk_person1_kravhaver || '|' || stonadstype, 'MD5') as pk_bb_fagsak
    ,vedtaks_id
    ,behandlings_type
    ,saksnr
    ,vedtakstidspunkt
    ,case 
        when innkreving_flagg = 'true' then 1 
        else 0 
    end as innkreving_flagg
    ,case 
        when historisk_vedtak = 'true' then 1
        else 0
    end as historisk_vedtak
    ,stonadstype
    ,fk_bb_meta_data
    ,fk_person1_skyldner
    ,fk_person1_kravhaver
    ,fk_person1_mottaker
    ,kafka_offset
from final 


