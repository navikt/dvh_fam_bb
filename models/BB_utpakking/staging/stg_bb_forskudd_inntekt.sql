with bb_meta_data as (
  select 
    kafka_offset, melding 
  from {{ref ('stg_bb_forskudd_meta_data')}}
),

final as (

    {{ hent_inntekt_liste('forskuddPeriodeListe', 'mottakerInntektListe', 'M') }}

    union all

    {{ hent_inntekt_liste('forskuddPeriodeListe', 'kravhaverInntektListe', 'K') }}

)

select 
    kafka_offset
    ,vedtaks_id
    ,periode_fra
    ,periode_til
    ,type_inntekt
    ,inntekt
    ,inntekt_for
    ,inntekt_kategori
    ,gjelder_kravhaver
from final 