{{ config(
    materialized='incremental',
    unique_key = ['aar_maaned', 'gyldig_flagg'],
    incremental_strategy='delete+insert'
    ) 
}}

with periode_uten_opphort as (
 
  select aar_maaned, vedtak.fk_person1_kravhaver, fk_person1_mottaker, fk_person1_skyldner, vedtak.vedtakstidspunkt
        ,pk_bb_fagsak as fk_bb_fagsak, vedtak.saksnr
					   
        ,vedtaks_id, behandlings_type, pk_bb_bidrag_periode as fk_bb_bidrags_periode
													  
        ,periode_fra, periode_til, belop as belop_vedtak
        ,resultat,resultat_tekst,forste_vedtakstidspunkt
        ,periode_fra_opphor, aar, vedtak.STONADSTYPE, NETTO_TILSYNSUTGIFT, FAKTISK_TILSYNSUTGIFT, INNKREVING_FLAGG
        ,BIDRAGSEVNE, UNDERHOLDSKOSTNAD, SAMVAERSFRADRAG, NETTO_BARNETILLEGG_BP, NETTO_BARNETILLEGG_BM,
        SAMVAERSKLASSE, BPS_ANDEL_UNDERHOLDSKOSTNAD, BPBOR_MED_ANDRE_VOKSNE, valutakode
        --,TO_DATE(TO_CHAR(LAST_DAY(SYSDATE), 'YYYYMMDD'), 'YYYYMMDD') MAX_VEDTAKSDATO --Input max_vedtaksdato
        ,TO_DATE('{{ var ("max_vedtaksdato") }}', 'yyyymmdd') MAX_VEDTAKSDATO
        ,fk_dim_tid_mnd
        ,'{{ var ("periode_type") }}' periode_type --Input periode_type
        ,dim_kravhaver.pk_dim_person as fk_dim_person_kravhaver
        ,dim_kravhaver.fk_dim_kjonn as kravhaver_fk_dim_kjonn
        ,dim_kravhaver.fk_dim_geografi_bosted as fk_dim_geografi_bosted_kravhaver
        ,floor(months_between(vedtak.siste_dato_i_perioden, dim_kravhaver.fodt_dato)/12) alder_kravhaver
        
        ,case 
            when dim_kravhaver.kjonn_nr = 1 then 'M'
            when dim_kravhaver.kjonn_nr = 0 then 'K'
        end kjonn_kravhaver   
		
        ,case 
            when vedtak.valutakode != 'NOK' then 
                belop * nvl((
                    select max(nb.valutakurser) keep (dense_rank first order by nb.periode desc) as valutakurser --Return valuta fra siste periode som finnes i tabellen
                    from dim_nb_valuta nb
                    where nb.base_cur = vedtak.valutakode
                      and nb.periode <= vedtak.aar_maaned
                    --order by nb.periode desc fetch first 1 row only
                        ), 0) --Return 0 hvis valuta ikke finnes i tabellen. Beløp fra vedtak finnes i felt belop_vedtak
            else belop
        end belop
		
        ,SISTE_KOMPLETT_VEDTAK
        ,SISTE_KOMPLETT_VEDTAKSTIDSPUNKT
        
        ,dim_mottaker.pk_dim_person as fk_dim_person_mottaker
        ,dim_mottaker.fk_dim_kjonn as mottaker_fk_dim_kjonn
        ,case 
            when dim_mottaker.kjonn_nr = 1 then 'M'
            when dim_mottaker.kjonn_nr = 0 then 'K'
        end kjonn_mottaker  
        ,dim_mottaker.gt_verdi as gt_verdi_mottaker
        ,dim_mottaker.getitype as gt_type_mottaker
        ,dim_mottaker.bosted_kommune_nr as bosted_kommune_nr_mottaker
        ,dim_mottaker.fk_dim_land_statsborgerskap as fk_dim_land_statsborgerskap_mottaker
        ,dim_mottaker.fk_dim_geografi_bosted as fk_dim_geografi_bosted_mottaker
        ,floor(months_between(vedtak.siste_dato_i_perioden, dim_mottaker.fodt_dato)/12) alder_mottaker
        
        ,dim_skyldner.pk_dim_person as fk_dim_person_skyldner
        ,dim_skyldner.fk_dim_kjonn as skyldner_fk_dim_kjonn
        ,case 
            when dim_skyldner.kjonn_nr = 1 then 'M'
            when dim_skyldner.kjonn_nr = 0 then 'K'
        end kjonn_skyldner 
        ,dim_skyldner.gt_verdi as gt_verdi_skyldner
        ,dim_skyldner.getitype as gt_type_skyldner
        ,dim_skyldner.bosted_kommune_nr as bosted_kommune_nr_skyldner
        ,dim_skyldner.fk_dim_land_statsborgerskap as fk_dim_land_statsborgerskap_skyldner
        ,dim_skyldner.fk_dim_geografi_bosted as fk_dim_geografi_bosted_skyldner
        ,floor(months_between(vedtak.siste_dato_i_perioden, dim_skyldner.fodt_dato)/12) alder_skyldner
        
        ,inntekts_typer.P_TYPE_INNTEKT_1,inntekts_typer.P_inntekt_1
        ,inntekts_typer.P_TYPE_INNTEKT_2,inntekts_typer.P_inntekt_2,inntekts_typer.P_TYPE_INNTEKT_3,inntekts_typer.P_inntekt_3
        ,inntekts_typer.P_INNTEKT_TOTAL, inntekts_typer.P_ANTALL_TYPER
        
        ,inntekts_typer.M_TYPE_INNTEKT_1
        ,inntekts_typer.M_inntekt_1, inntekts_typer.M_TYPE_INNTEKT_2, inntekts_typer.M_inntekt_2
        ,inntekts_typer.M_type_inntekt_3, inntekts_typer.M_inntekt_3, inntekts_typer.M_type_inntekt_4
        ,inntekts_typer.M_inntekt_4,inntekts_typer.M_type_inntekt_5, inntekts_typer.M_inntekt_5
        ,inntekts_typer.M_INNTEKT_TOTAL, inntekts_typer.M_ANTALL_TYPER
																	  
        ,'{{ var ("gyldig_flagg") }}' as gyldig_flagg --Input gyldig_flagg
        ,localtimestamp AS lastet_dato
  from {{ ref('periode_opphor_bidrag') }} vedtak

  left join {{ source ('person', 'dim_person') }} dim_kravhaver
  on dim_kravhaver.fk_person1 = vedtak.fk_person1_kravhaver
  and vedtak.fk_person1_kravhaver != -1
  and vedtak.siste_dato_i_perioden between dim_kravhaver.gyldig_fra_dato and dim_kravhaver.gyldig_til_dato
 
  left join {{ source ('person', 'dim_person') }} dim_mottaker
  on dim_mottaker.fk_person1 = vedtak.fk_person1_mottaker
  and vedtak.fk_person1_mottaker != -1
  and vedtak.siste_dato_i_perioden between dim_mottaker.gyldig_fra_dato and dim_mottaker.gyldig_til_dato
  
  left join {{ source ('person', 'dim_person') }} dim_skyldner
  on dim_skyldner.fk_person1 = vedtak.fk_person1_skyldner
  and vedtak.fk_person1_skyldner != -1
  and vedtak.siste_dato_i_perioden between dim_skyldner.gyldig_fra_dato and dim_skyldner.gyldig_til_dato

  --left join {{ ref("inntekt_bidrag") }} inntekts_typer

  --on vedtak.pK_BB_BIDRAGS_PERIODE = inntekts_typer.FK_BB_BIDRAG_PERIODE

  left join (
  select * from (
    select i.*,
            ROW_NUMBER() OVER (PARTITION BY i.saksnr, i.fk_person1_kravhaver--, i.stonadstype
            ORDER BY 
                CASE WHEN i.fk_bb_bidrag_periode IS NOT NULL THEN 0 ELSE 1 END,
                    i.vedtakstidspunkt DESC) AS rn
    from {{ ref("inntekt_bidrag") }} i
  ) inntekt
  where rn = 1
  ) inntekts_typer
  ON vedtak.saksnr = inntekts_typer.saksnr
  and vedtak.fk_person1_kravhaver = inntekts_typer.fk_person1_kravhaver

  where siste_dato_i_perioden < nvl(periode_fra_opphor, siste_dato_i_perioden+1)
)

select 
p.VEDTAKSTIDSPUNKT
,p.VEDTAKS_ID
,p.VALUTAKODE
,p.UNDERHOLDSKOSTNAD
,p.STONADSTYPE
,p.SKYLDNER_FK_DIM_KJONN
,p.SISTE_KOMPLETT_VEDTAKSTIDSPUNKT
,p.SISTE_KOMPLETT_VEDTAK
,p.SAMVAERSKLASSE
,p.SAMVAERSFRADRAG
,p.SAKSNR
,p.RESULTAT_TEKST
,p.RESULTAT
,p.P_TYPE_INNTEKT_3
,p.P_TYPE_INNTEKT_2
,p.P_TYPE_INNTEKT_1
,p.P_INNTEKT_3
,p.P_INNTEKT_2
,p.P_INNTEKT_1
,p.P_INNTEKT_TOTAL
,p.PERIODE_TYPE
,p.PERIODE_TIL
,p.PERIODE_FRA_OPPHOR
,p.PERIODE_FRA
,p.P_ANTALL_TYPER
,p.NETTO_TILSYNSUTGIFT
,p.NETTO_BARNETILLEGG_BP
,p.NETTO_BARNETILLEGG_BM
,p.M_TYPE_INNTEKT_5
,p.M_TYPE_INNTEKT_4
,p.M_TYPE_INNTEKT_3
,p.M_TYPE_INNTEKT_2
,p.M_TYPE_INNTEKT_1
,p.MOTTAKER_FK_DIM_KJONN
,p.M_INNTEKT_5
,p.M_INNTEKT_4
,p.M_INNTEKT_3
,p.M_INNTEKT_2
,p.M_INNTEKT_1
,p.M_INNTEKT_TOTAL
,p.MAX_VEDTAKSDATO
,p.M_ANTALL_TYPER
,p.KRAVHAVER_FK_DIM_KJONN
,p.KJONN_SKYLDNER
,p.KJONN_MOTTAKER
,p.KJONN_KRAVHAVER
,p.INNKREVING_FLAGG
,p.GYLDIG_FLAGG
,p.GT_VERDI_SKYLDNER
,p.GT_VERDI_MOTTAKER
,p.GT_TYPE_SKYLDNER
,p.GT_TYPE_MOTTAKER
,p.FORSTE_VEDTAKSTIDSPUNKT
,p.FK_PERSON1_SKYLDNER
,p.FK_PERSON1_MOTTAKER
,p.FK_PERSON1_KRAVHAVER
,p.FK_DIM_PERSON_SKYLDNER
,p.FK_DIM_PERSON_MOTTAKER
,p.FK_DIM_PERSON_KRAVHAVER
,p.FK_DIM_LAND_STATSBORGERSKAP_SKYLDNER
,p.FK_DIM_LAND_STATSBORGERSKAP_MOTTAKER
,p.FK_DIM_GEOGRAFI_BOSTED_SKYLDNER
,p.FK_DIM_GEOGRAFI_BOSTED_MOTTAKER
,p.FK_DIM_GEOGRAFI_BOSTED_KRAVHAVER
,p.FK_BB_FAGSAK
,p.FK_BB_BIDRAGS_PERIODE
,p.FAKTISK_TILSYNSUTGIFT
,p.BPS_ANDEL_UNDERHOLDSKOSTNAD
,p.BPBOR_MED_ANDRE_VOKSNE
,p.BOSTED_KOMMUNE_NR_SKYLDNER
,p.BOSTED_KOMMUNE_NR_MOTTAKER
,p.BIDRAGSEVNE
,p.BELOP_VEDTAK
,p.BELOP
,p.BEHANDLINGS_TYPE
,p.ALDER_SKYLDNER
,p.ALDER_MOTTAKER
,p.ALDER_KRAVHAVER
,p.AAR_MAANED
,p.AAR
,kravhaver_dim_alder.pk_dim_alder as kravhaver_fk_dim_alder
,mottaker_dim_alder.pk_dim_alder as mottaker_fk_dim_alder
,skyldner_dim_alder.pk_dim_alder as skyldner_fk_dim_alder
,CONCAT(p.aar_maaned, '003') as fk_dim_tid
,p.lastet_dato

from periode_uten_opphort p

left join {{ source ('kode_verk' , 'dim_alder')}}  kravhaver_dim_alder
on p.alder_kravhaver = kravhaver_dim_alder.alder

left join {{ source ('kode_verk' , 'dim_alder')}}  mottaker_dim_alder
on p.alder_mottaker = mottaker_dim_alder.alder

left join {{ source ('kode_verk' , 'dim_alder')}}  skyldner_dim_alder
on p.alder_mottaker = skyldner_dim_alder.alder