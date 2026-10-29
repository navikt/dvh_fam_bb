{{
    config(
        materialized='table',
        post_hook="{{ dbt_dvh_macros.BREDAGG__sync_multi_source_comments([ ['kode_verk', 'dim_tid'], 
        ['kode_verk', 'dim_geografi'],['kode_verk', 'dim_alder'],
        ['kode_verk', 'dim_kjonn'] ]) }}"
    )
}}

with bidrag_skyldner as (
    select
        fk_dim_tid,
        fk_dim_geografi_bosted_skyldner as fk_dim_geografi,
        skyldner_fk_dim_alder as fk_dim_alder,
        skyldner_fk_dim_kjonn as fk_dim_kjonn,
        count(distinct fk_person1_skyldner) as bidrag_antall_skyldnere
    from fam_bb_bidrag
    where gyldig_flagg = 1
      and BELOP > 0
    group by
        fk_dim_tid,
        fk_dim_geografi_bosted_skyldner,
        skyldner_fk_dim_alder,
        skyldner_fk_dim_kjonn
),

/* Mottakere fra begge kilder */
mottakere_bidrag_og_forskudd as (
    select
        fk_dim_tid,
        fk_person1_mottaker,
        mottaker_fk_dim_alder as fk_dim_alder,
        mottaker_fk_dim_kjonn as fk_dim_kjonn,
        fk_dim_geografi_bosted_mottaker as fk_dim_geografi,
        1 as kilde_prioritet
    from fam_bb_bidrag
    where gyldig_flagg = 1
      and belop > 0

    UNION ALL

    select
        fk_dim_tid_mnd as fk_dim_tid,
        fk_person1_mottaker,
        mottaker_fk_dim_alder as fk_dim_alder,
        mottaker_fk_dim_kjonn as fk_dim_kjonn,
        fk_dim_geografi_bosted_mottaker as fk_dim_geografi,
        2 as kilde_prioritet
    from fam_bb_forskudd
    where gyldig_flagg = 1
      and belop > 0

),

/* en rad per mottaker og periode. Bidrag prioriteres hvis mottakeren finnes i begge kilder */
mottakere_prio_flagg as (
    select
        fk_dim_tid,
        fk_person1_mottaker,
        fk_dim_geografi,
        fk_dim_alder,
        fk_dim_kjonn,
        ROW_NUMBER() OVER (PARTITION BY fk_dim_tid, fk_person1_mottaker ORDER BY kilde_prioritet DESC,
                fk_dim_geografi, fk_dim_alder, fk_dim_kjonn) as rn
    from mottakere_bidrag_og_forskudd
),

mottakere as (
    select
        fk_dim_tid,
        fk_dim_geografi,
        fk_dim_alder,
        fk_dim_kjonn,
        count(*) as bidrag_antall_mottakere
    from mottakere_prio_flagg
    where rn = 1
    group by
        fk_dim_tid,
        fk_dim_geografi,
        fk_dim_alder,
        fk_dim_kjonn
),

bidrag_kravhaver as (
    select
        fk_dim_tid,
        fk_dim_geografi_bosted_kravhaver as fk_dim_geografi,
        kravhaver_fk_dim_alder as fk_dim_alder,
        kravhaver_fk_dim_kjonn as fk_dim_kjonn,
        count(distinct fk_person1_kravhaver) as bidrag_antall_kravhavere
    from fam_bb_bidrag
    where gyldig_flagg = 1
      and BELOP > 0
    group by
        fk_dim_tid,
        fk_dim_geografi_bosted_kravhaver,
        kravhaver_fk_dim_alder,
        kravhaver_fk_dim_kjonn
),

forskudd_mottaker as (
    select 
        fk_dim_tid_mnd as fk_dim_tid
        ,fk_dim_geografi_bosted_mottaker as fk_dim_geografi
        ,mottaker_fk_dim_alder as fk_dim_alder
        ,mottaker_fk_dim_kjonn as fk_dim_kjonn
        ,count(distinct fk_person1_mottaker) as forskudd_antall_mottakere
    from fam_bb_forskudd
    where gyldig_flagg = 1 --fk_person1_mottaker != -1 
    and BELOP > 0
    group by fk_dim_tid_mnd
    ,fk_dim_geografi_bosted_mottaker
    ,mottaker_fk_dim_alder
    ,mottaker_fk_dim_kjonn
),

final as (
    select
        'Barnebidrag' as kilde_omraade,

        {{ dbt_dvh_macros.BREDAGG__ephemeral_star( model_name='dim_skjelett', relation_alias='t1') }},

        s.bidrag_antall_skyldnere,
        m.bidrag_antall_mottakere,
        k.bidrag_antall_kravhavere,
        fm.forskudd_antall_mottakere,
        case
            when t1.ALDER_GRUPPE1_BESK IN ('19 år og under','20-24 år') then 'Under 25 år'
            when t1.ALDER_GRUPPE1_BESK = '25-29 år' then '25-29 år'
            when t1.ALDER_GRUPPE1_BESK = '30-34 år' then '30-34 år'
            when t1.ALDER_GRUPPE1_BESK = '35-39 år' then '35-39 år'
            when t1.ALDER_GRUPPE1_BESK = '40-44 år' then '40-44 år'
            when t1.ALDER_GRUPPE1_BESK IN ('45-49 år','50-54 år','55-59 år','60-64 år','65-69 år','70-74 år','75-79 år','80-84 år', '85-89 år', '90 år og over') then '45 år+'
            else 'Uoppgitt'
        end as alder_gruppe_bidrag

    from {{ ref('dim_skjelett') }} t1

    left join bidrag_skyldner s
        on t1.fk_dim_tid = s.fk_dim_tid
        and t1.fk_dim_geografi = s.fk_dim_geografi
        and t1.fk_dim_alder = s.fk_dim_alder
        and t1.fk_dim_kjonn = s.fk_dim_kjonn

    left join mottakere m
        on t1.fk_dim_tid = m.fk_dim_tid
        and t1.fk_dim_geografi = m.fk_dim_geografi
        and t1.fk_dim_alder = m.fk_dim_alder
        and t1.fk_dim_kjonn = m.fk_dim_kjonn

    left join bidrag_kravhaver k
        on t1.fk_dim_tid = k.fk_dim_tid
        and t1.fk_dim_geografi = k.fk_dim_geografi
        and t1.fk_dim_alder = k.fk_dim_alder
        and t1.fk_dim_kjonn = k.fk_dim_kjonn

    left join forskudd_mottaker fm
        on t1.fk_dim_tid = fm.fk_dim_tid
        and t1.fk_dim_geografi = fm.fk_dim_geografi
        and t1.fk_dim_alder = fm.fk_dim_alder
        and t1.fk_dim_kjonn = fm.fk_dim_kjonn
)

select
    final.*,
    '{{ var("gyldig_flagg") }}' as gyldig_flagg,
    localtimestamp as lastet_dato
from final