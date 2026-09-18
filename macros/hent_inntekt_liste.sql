{% macro hent_inntekt_liste(periode_liste, inntekt_liste, inntekt_for) %}

select
    kafka_offset,
    vedtaks_id,
    historisk_vedtak,
    periode_fra,
    periode_til,
    inntekt_kategori,
    gjelder_kravhaver,
    type_inntekt,
    inntekt,
    '{{ inntekt_for }}' as inntekt_for
from bb_meta_data
    ,json_table(melding, '$'
        columns (
            vedtaks_id varchar2(255) path '$.vedtaksid',
            historisk_vedtak varchar2(255) path '$.historiskVedtak',
            nested path '$.{{ periode_liste }}[*]'
            columns (
                periode_fra date path '$.periodeFra',
                periode_til date path '$.periodeTil',
                nested path '$.{{ inntekt_liste }}[*]'
                columns (
                    type_inntekt varchar2(255) path '$.type',
                    inntekt number(18,2) path '$.beløp',
                    inntekt_kategori varchar2(255) path '$.inntektstype',
                    gjelder_kravhaver varchar2(255) path '$.gjelderKravhaver'
                )
            )
        )
    ) j
where type_inntekt is not null
    and historisk_vedtak = 'false'

{% endmacro %}