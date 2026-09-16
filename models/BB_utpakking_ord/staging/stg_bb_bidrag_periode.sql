with bb_meta_data as (
    select 
        kafka_offset, melding 
    from {{ref ('stg_bb_bidrag_meta_data')}}
),

final as (
    select *
    from bb_meta_data
        ,json_table(melding, '$'
            columns (
                vedtaks_id varchar2(255) path '$.vedtaksid',
                nested path '$.bidragPeriodeListe[*]'
                columns (
                    periode_fra                 date path '$.periodeFra'
                   ,periode_til                 date path '$.periodeTil'
                   ,belop                       number(18,2)  path '$.beløp'
                   ,valutakode                  varchar2(255)  path '$.valutakode'                   
                   ,resultat                    varchar2(255) path '$.resultat'
                   ,bidragsevne                 number(18,2)  path '$.bidragsevne'
                   ,underholdskostnad           number(18,2)  path '$.underholdskostnad'
                   ,samvaersfradrag             number(18,2)  path '$.samværsfradrag'
                   ,netto_barnetillegg_bp       number(18,2)  path '$.nettoBarnetilleggSkyldner'
                   ,netto_barnetillegg_bm       number(18,2)  path '$.nettoBarnetilleggMottaker'
                   ,samvaersklasse              varchar2(255) path '$.samværsklasse'
                   ,bps_andel_underholdskostnad number(18,2)  path '$.skyldnersAndelUnderholdskostnad'
                   ,bpbor_med_andre_voksne      varchar2(255) path '$.skyldnerBorMedAndreVoksne'
                   ,netto_tilsynsutgift         number(18,2)  path '$.nettoTilsynsutgift'
                   ,faktisk_tilsynsutgift       number(18,2)  path '$.faktiskUtgift'
                )
            )
        ) j
    where periode_fra is not null
)

select 
    vedtaks_id
    ,periode_fra
    ,periode_til
    ,belop
    ,valutakode 
    ,resultat
    ,bidragsevne 
    ,underholdskostnad
    ,samvaersfradrag
    ,netto_barnetillegg_bp
    ,netto_barnetillegg_bm 
    ,samvaersklasse 
    ,bps_andel_underholdskostnad
    ,bpbor_med_andre_voksne
    ,netto_tilsynsutgift
    ,faktisk_tilsynsutgift
    ,kafka_offset
from final