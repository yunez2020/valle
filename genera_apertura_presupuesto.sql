/* Script que se utiliza para transformar un presupuesto por hotel/pos/semana
en hotel/pos/semana/habitacion/nivel usando datos historicos */

/* Creacion de pivote para presupuesto para que estén las combinaciones*/
/* requiere de la tabla capacidad para los tipos de habitacion y dic_niveles */

drop table if exists tmp_pivote_ppto;
create table tmp_pivote_ppto
select p.hotel, p.pos, p.semana_temp, c.tipohabrm, n.nivel
from ppto_original_excel p
left join capacidad c
on p.hotel=c.hotel
cross join dic_niveles n;
create index idx_pvt_det on tmp_pivote_ppto(hotel,pos, semana_temp,tipohabrm,nivel);

/* Se usa el ffl del 2017 para distribuir por nivel y tipohabrm*/
/* Se elimina el N0 y se asume como N1 */


drop table if exists distribucion_anio_completo_detalle_aux;
create table distribucion_anio_completo_detalle_aux
select fecha_vista, semana_temp,hotel, tipohabrm,nacionalidad_gestion as pos, if(nivel='N0', 'N1', nivel) as  nivel, agno, sum(noches_cama) as nc, sum(habitaciones_noches) as hn, sum(ingreso_neto) as ia
from final_final_last_2017
where fecha_vista='20171006'
and semana_temp between 1 and 15
and agno=2017
group by fecha_vista, semana_temp,hotel, tipohabrm,nacionalidad_gestion, nivel, agno;
create index idx_ac on distribucion_anio_completo_detalle_aux(hotel, pos, semana_temp, tipohabrm,nivel);

drop table if exists distribucion_anio_completo_detalle_aux2;
create table distribucion_anio_completo_detalle_aux2
select fecha_vista, semana_temp,hotel, tipohabrm,pos, nivel, agno, sum(nc) as nc, sum(hn) as hn, sum(ia) as ia
from distribucion_anio_completo_detalle_aux
group by fecha_vista, semana_temp,hotel, tipohabrm,pos, nivel, agno;
create index idx_ac on distribucion_anio_completo_detalle_aux2(hotel, pos, semana_temp, tipohabrm,nivel);


drop table if exists distribucion_anio_completo_detalle;
create table distribucion_anio_completo_detalle
select pv.*, d.nc, d.hn, d.ia
from tmp_pivote_ppto pv
left join distribucion_anio_completo_detalle_aux2 d
on pv.hotel=d.hotel
and pv.pos=d.pos
and pv.semana_temp=d.semana_temp
and pv.tipohabrm=d.tipohabrm
and pv.nivel=d.nivel;
create index idx_ac on distribucion_anio_completo_detalle(hotel, pos, semana_temp, tipohabrm,nivel);

drop table distribucion_anio_completo_detalle_aux;
drop table distribucion_anio_completo_detalle_aux2;

update distribucion_anio_completo_detalle
set nc=0 where nc is null or ia=0;

update distribucion_anio_completo_detalle
set hn=0 where hn is null or nc=0;

update distribucion_anio_completo_detalle
set ia=0 where ia is null;



drop table if exists distribucion_anio_completo_agregado;
create table distribucion_anio_completo_agregado
select hotel, pos, semana_temp, sum(nc) as nc, sum(hn) as hn, sum(ia) as ia, if(sum(hn)=0,0,round(sum(nc)/sum(hn),4)) as coef_ocup
from distribucion_anio_completo_detalle
group by hotel, pos, semana_temp;
create index idx_ac on distribucion_anio_completo_agregado(hotel, pos, semana_temp);

drop table if exists distribucion_proporcional;
create table distribucion_proporcional
select d.hotel, d.pos, d.semana_temp, d.tipohabrm, d.nivel, if(a.nc=0,0,round(d.nc/a.nc,4)) as coef_nc, if(a.hn=0,0,round(d.hn/a.hn,4)) as coef_hn, if(a.ia=0,0,round(d.ia/a.ia,4)) as coef_ia, a.coef_ocup
from distribucion_anio_completo_detalle d
left join distribucion_anio_completo_agregado a
on d.hotel=a.hotel
and d.pos=a.pos
and d.semana_temp=a.semana_temp;

drop table if exists presupuesto;
create table presupuesto (
  hotel varchar(3) NOT NULL,
  semana_temp int(11) NOT NULL,
  pos varchar(3) NOT NULL,
  nivel varchar(2) NOT NULL,
  tipohabrm varchar(12) NOT NULL,
  ppto_nc int(11) NOT NULL,
  ppto_hn int(11) not null,
  ppto_ingreso int(11) NOT NULL,
  ppto_tarifa double NOT NULL,
  agno int(11) NOT NULL,
  PRIMARY KEY (hotel,semana_temp,pos,nivel,tipohabrm)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

truncate presupuesto;
insert into presupuesto
select p.hotel, p.semana_temp, p.pos, d.nivel, d.tipohabrm, round(coef_nc*ppto_nc), ifnull(round(coef_nc*ppto_nc/coef_ocup),0), round(coef_ia*ppto_ingreso), if(coef_nc*ppto_nc=0,0,round(coef_ia*ppto_ingreso/(coef_nc*ppto_nc),1)), 2023
from ppto_original_excel p
left join distribucion_proporcional d
on p.hotel=d.hotel
and p.pos=d.pos
and p.semana_temp=d.semana_temp;

/* rellena los hotel-pos-semana_temp que no tienen historia y tienen presupuesto */

update presupuesto p,
(select a.hotel, a.semana_temp, a.pos, ppto_nc, ppto_ingreso
from ppto_original_excel a
left join distribucion_anio_completo_agregado b
on a.hotel=b.hotel
and a.semana_temp=b.semana_temp
and a.pos=b.pos
where (a.ppto_nc>0 or a.ppto_ingreso>0)
and (b.nc=0 or b.ia=0)) as r
set p.ppto_nc=r.ppto_nc, p.ppto_ingreso=r.ppto_ingreso
where p.hotel=r.hotel
and p.semana_temp=r.semana_temp
and p.pos=r.pos
and p.nivel='N1'
and (p.tipohabrm='Double' or p.tipohabrm='DoubleSouth');


drop table if exists distribucion_anio_completo_agregado;
drop table if exists distribucion_anio_completo_detalle;
drop table if exists distribucion_proporcional;
drop table if exists tmp_pivote_ppto;

