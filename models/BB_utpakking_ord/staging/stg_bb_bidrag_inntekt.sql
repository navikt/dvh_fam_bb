with bb_meta_data as (

    select
        kafka_offset,
        melding
    from {{ ref('stg_bb_bidrag_meta_data') }}

),

final as (

    {{ hent_inntekt_liste('bidragPeriodeListe', 'skyldnerInntektListe', 'P') }}

    union all

    {{ hent_inntekt_liste('bidragPeriodeListe', 'mottakerInntektListe', 'M') }}

    union all

    {{ hent_inntekt_liste('bidragPeriodeListe', 'kravhaverInntektListe', 'K') }}

)

select
    type_inntekt,
    inntekt,
    vedtaks_id,
    inntekt_kategori,
    gjelder_kravhaver,
    inntekt_for,
    periode_fra,
    periode_til,
    kafka_offset
from final