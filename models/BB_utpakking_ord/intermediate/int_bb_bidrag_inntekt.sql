with inntekt as (
    select *
    from {{ref ('stg_bb_bidrag_inntekt')}}
),

fagsak as (
    select vedtaks_id, pk_bb_fagsak, kafka_offset, fk_person1_kravhaver, vedtakstidspunkt, stonadstype
    from {{ref ('int_bb_bidrag_fagsak')}}
),


final as (
    select
        STANDARD_HASH(fs.vedtaks_id || '|' || fs.fk_person1_kravhaver || '|' || i.periode_fra || '|' || fs.stonadstype,'MD5') AS fk_bb_bidrag_periode
        ,fs.fk_person1_kravhaver        
        ,i.type_inntekt
        ,i.inntekt
        ,i.inntekt_kategori
        ,i.inntekt_for
        ,gjelder_kravhaver
        --,nvl(ident_krav.fk_person1, -1) as fk_person1_gjelder_kravhaver
        --,bp.pk_bb_bidrag_periode as fk_bb_bidrag_periode
        ,i.periode_fra
        ,i.periode_til
        --,row_number() over (partition by fs.vedtaks_id, fs.fk_person1_kravhaver , bp.periode_fra, i.type_inntekt  order by i.type_inntekt) as type_inntekt_nr 
        ,i.kafka_offset
        ,fs.vedtaks_id
    from inntekt i
    inner join fagsak fs
        on i.kafka_offset = fs.kafka_offset
        and i.vedtaks_id = fs.vedtaks_id
        /*
    inner join bb_bidrag_periode bp
        on bp.periode_fra = i.periode_fra
        and (bp.periode_til = i.periode_til
                or (bp.periode_til is null and i.periode_til is null)
            )
        and bp.fk_bb_fagsak = fs.pk_bb_fagsak
    */

    /*
    left join {{ source ('person', 'ident_off_id_til_fk_person1') }} ident_krav
        on i.gjelder_kravhaver = ident_krav.off_id
        and TRUNC(fs.vedtakstidspunkt, 'DD') >= ident_krav.gyldig_fra_dato
        and TRUNC(fs.vedtakstidspunkt, 'DD') <= ident_krav.gyldig_til_dato
    */
)

select 
    standard_hash(vedtaks_id || '|' || type_inntekt || '|' || inntekt_kategori || '|' || periode_fra || '|' || gjelder_kravhaver || '|' || inntekt_for || '|' || fk_person1_kravhaver || '|' || inntekt ,'MD5') as pk_bb_inntekt
    --standard_hash(vedtaks_id || '|' || inntekt_for || '|' || inntekt_kategori || '|' || type_inntekt || '|' ||  gjelder_kravhaver,'MD5')
    ,fk_bb_bidrag_periode
    ,type_inntekt
    ,inntekt
    ,inntekt_kategori
    ,inntekt_for
    ,kafka_offset
from final 

