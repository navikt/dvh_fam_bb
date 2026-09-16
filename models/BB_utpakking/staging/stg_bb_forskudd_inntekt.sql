with bb_meta_data as (
  select 
    kafka_offset, melding 
  from {{ref ('stg_bb_forskudd_meta_data')}}
),

final as (

    {{ hent_inntekt_listel('forskuddPeriodeListe', 'mottakerInntektListe', 'M') }}

    union all

    {{ hent_inntekt_listel('forskuddPeriodeListe', 'kravhaverInntektListe', 'K') }}

)

select 
    kafka_offset
    ,vedtaks_id
    ,periode_fra
    ,periode_til
    ,type_inntekt
    ,inntekt
    ,flagg
    ,inntekt_kategori
    ,gjelder_kravhaver
from final 