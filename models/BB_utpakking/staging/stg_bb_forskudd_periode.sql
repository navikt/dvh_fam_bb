with bb_meta_data as (
    select 
        kafka_offset, melding 
    from {{ref ('stg_bb_forskudd_meta_data')}}
),

final as (
    select *
    from bb_meta_data
        ,json_table(melding, '$'
            columns (
                vedtaks_id VARCHAR2(255 CHAR) PATH '$.vedtaksid',
                nested PATH '$.forskuddPeriodeListe[*]'
                columns (
                    periode_fra                     VARCHAR2(255 CHAR) PATH '$.periodeFra'
                   ,periode_til                     VARCHAR2(255 CHAR) PATH '$.periodeTil'
                   ,belop                           VARCHAR2(255 CHAR) PATH '$.beløp'
                   ,resultat                        VARCHAR2(255 CHAR) PATH '$.resultat'
                   ,barnets_alders_gruppe           VARCHAR2(255 CHAR) PATH '$.barnetsAldersgruppe'
                   ,antall_barn_i_egen_husstand     VARCHAR2(255 CHAR) PATH '$.antallBarnIEgenHusstand'
                   ,sivilstand                      VARCHAR2(255 CHAR) PATH '$.sivilstand'
                   ,barn_bor_med_mottaker           VARCHAR2(255 CHAR) PATH '$.barnBorMedMottaker'
                   ))
        ) j
    where periode_fra is not null
)

select 
    vedtaks_id
    ,periode_fra
    ,periode_til
    ,belop
    ,resultat
    ,barnets_alders_gruppe
    ,antall_barn_i_egen_husstand
    ,sivilstand
    ,barn_bor_med_mottaker
    ,kafka_offset
from final