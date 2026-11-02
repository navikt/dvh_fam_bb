with bb_meta_data as (
    select * from {{ref ('stg_bb_saerbidrag_meta_data')}}
),

skyld as (
    select * 
    from bb_meta_data
        ,json_table(melding, '$'
            columns (
                saksnr              VARCHAR2(255 CHAR)  PATH '$.saksnr'
                ,vedtaks_id         VARCHAR2(255 CHAR)  PATH '$.vedtaksid'
                ,vedtakstidspunkt   TIMESTAMP(3)        PATH '$.vedtakstidspunkt'
                ,skyldner           VARCHAR2(255 CHAR)  PATH '$.skyldner'
                ,kravhaver          VARCHAR2(255 CHAR)  PATH '$.kravhaver'
                ,mottaker           VARCHAR2(255 CHAR)  PATH '$.mottaker'
                ,historisk_vedtak   VARCHAR2(255 CHAR)  PATH '$.historiskVedtak'

                ,nested PATH '$.skyldnerInntektListe[*]'
                    columns(
                        type_inntekt            VARCHAR2(255)   PATH '$.type'
                        ,gjelder_kravhaver      VARCHAR2(255)   PATH '$.gjelderKravhaver'
                        ,inntekt_kategori       VARCHAR2(255)   PATH '$.inntektstype'
                        ,inntekt_belop          NUMBER    PATH '$.beløp'

                    )
            )
        ) j
    where inntekt_belop is not null
    and historisk_vedtak = 'false'
),

mott as (
    select * 
    from bb_meta_data
        ,json_table(melding, '$'
            columns (
                saksnr VARCHAR2(255 CHAR) PATH '$.saksnr'
                ,vedtaks_id  VARCHAR2(255 CHAR) PATH '$.vedtaksid'
                ,vedtakstidspunkt TIMESTAMP(3) PATH '$.vedtakstidspunkt'
                ,skyldner VARCHAR2(255 CHAR) PATH '$.skyldner'
                ,kravhaver VARCHAR2(255 CHAR) PATH '$.kravhaver'
                ,mottaker VARCHAR2(255 CHAR) PATH '$.mottaker'
                ,historisk_vedtak VARCHAR2(255 CHAR) PATH '$.historiskVedtak'

                ,nested PATH '$.mottakerInntektListe[*]'
                    columns(
                        type_inntekt VARCHAR2(255)   PATH '$.type'
                        ,gjelder_kravhaver   VARCHAR2(255)   PATH '$.gjelderKravhaver'
                        ,inntekt_kategori VARCHAR2(255)   PATH '$.inntektstype'
                        ,inntekt_belop    NUMBER(16,2)    PATH '$.beløp'
                    )
            )
        ) j
    where inntekt_belop is not null
    and historisk_vedtak = 'false'
),


krav as (
    select * 
    from bb_meta_data
        ,json_table(melding, '$'
            columns (
                saksnr VARCHAR2(255 CHAR) PATH '$.saksnr'
                ,vedtaks_id  VARCHAR2(255 CHAR) PATH '$.vedtaksid'
                ,vedtakstidspunkt TIMESTAMP(3) PATH '$.vedtakstidspunkt'
                ,skyldner VARCHAR2(255 CHAR) PATH '$.skyldner'
                ,kravhaver VARCHAR2(255 CHAR) PATH '$.kravhaver'
                ,mottaker VARCHAR2(255 CHAR) PATH '$.mottaker'
                ,historisk_vedtak VARCHAR2(255 CHAR) PATH '$.historiskVedtak'

                ,nested PATH '$.kravhaverInntektListe[*]'
                    columns(
                        type_inntekt VARCHAR2(255)   PATH '$.type'
                        ,gjelder_kravhaver   VARCHAR2(255)   PATH '$.gjelderKravhaver'
                        ,inntekt_kategori VARCHAR2(255)   PATH '$.inntektstype'
                        ,inntekt_belop    NUMBER(16,2)    PATH '$.beløp'
                    )
            )
        ) j
    where inntekt_belop is not null
    and historisk_vedtak = 'false'
),

final as (
    select kafka_offset
        ,saksnr
        ,vedtaks_id
        ,vedtakstidspunkt
        ,kravhaver
        ,gjelder_kravhaver
        ,historisk_vedtak
        ,type_inntekt
        ,inntekt_kategori
        ,'P' as inntekt_for -- p for pliktig/skyldner
        ,inntekt_belop
    from skyld
 
    union all

    select kafka_offset
        ,saksnr
        ,vedtaks_id
        ,vedtakstidspunkt
        ,kravhaver
        ,gjelder_kravhaver
        ,historisk_vedtak
        ,type_inntekt
        ,inntekt_kategori
        ,'M' as inntekt_for -- m for mottaker
        ,inntekt_belop
    from mott

        union all

    select kafka_offset
        ,saksnr
        ,vedtaks_id
        ,vedtakstidspunkt
        ,kravhaver
        ,gjelder_kravhaver
        ,historisk_vedtak
        ,type_inntekt
        ,inntekt_kategori
        ,'K' as inntekt_for -- k for kravhaver
        ,inntekt_belop
    from krav
)

select * from final