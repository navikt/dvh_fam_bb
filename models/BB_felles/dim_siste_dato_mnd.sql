{{ config(materialized='ephemeral') }}

select pk_dim_tid
,siste_dato_i_perioden
,siste_dato_i_perioden - 1 as valuta_siste_kurs_dato_i_mnd
from {{ source ('kode_verk', 'dim_tid') }}
where GYLDIG_FLAGG = 1 
and DIM_NIVAA = 3