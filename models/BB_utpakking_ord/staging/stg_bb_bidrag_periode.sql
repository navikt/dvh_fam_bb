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
                vedtaks_id VARCHAR2(255 CHAR) PATH '$.vedtaksid',
                nested PATH '$.bidragPeriodeListe[*]'
                columns (
                    periode_fra                 DATE PATH '$.periodeFra'
                   ,periode_til                 DATE PATH '$.periodeTil'
                   ,belop                       NUMBER  PATH '$.beløp'
                   ,valutakode                  VARCHAR2(255 CHAR)  PATH '$.valutakode'                   
                   ,resultat                    VARCHAR2(255 CHAR) PATH '$.resultat'
                   ,bidragsevne                 NUMBER  PATH '$.bidragsevne'
                   ,underholdskostnad           NUMBER  PATH '$.underholdskostnad'
                   ,samvaersfradrag             NUMBER  PATH '$.samværsfradrag'
                   ,netto_barnetillegg_bp       NUMBER  PATH '$.nettoBarnetilleggSkyldner'
                   ,netto_barnetillegg_bm       NUMBER  PATH '$.nettoBarnetilleggMottaker'
                   ,samvaersklasse              VARCHAR2(255 CHAR) PATH '$.samværsklasse'
                   ,bps_andel_underholdskostnad NUMBER  PATH '$.skyldnersAndelUnderholdskostnad'
                   ,bpbor_med_andre_voksne      varchar2 PATH '$.skyldnerBorMedAndreVoksne'
                   ,netto_tilsynsutgift         NUMBER  PATH '$.nettoTilsynsutgift'
                   ,faktisk_tilsynsutgift       NUMBER  PATH '$.faktiskUtgift'
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