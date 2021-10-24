CREATE INDEX isochrone_polys_districts_geom_idx ON geo.isochrone_polys_districts
  USING gist (geom);
  
with square_by_obj as (
	select object_id id, sum(square) square
	from source.sport_zones
	group by object_id
)
select id, geom, square
into geo.objects_buffer_iso
from isochrone_polys_districts
left join square_by_obj
using (id)
where square is not null

CREATE INDEX objects_buffer_iso_geom_idx ON geo.objects_buffer_iso
  USING gist (geom);
 
select id, st_centroid(geom) geom
into geo.grid_hex_wgs_centroid
from grid_hex_wgs

CREATE INDEX grid_hex_wgs_geom_idx ON geo.grid_hex_wgs
  USING gist (geom);
 
CREATE INDEX grid_hex_wgs_centroid_geom_idx ON geo.grid_hex_wgs_centroid
  USING gist (geom);

select id, square, geom, buffer
into geo.objects_centroids
from "source".sport_objects

CREATE INDEX objects_centroids_geom_idx ON geo.objects_centroids
  USING gist (geom);

 
-- SQLVIEW FILTER FOR OBJECTS
select distinct on (c.id) c.id, c.geom
from geo.objects_centroids c
join "source".sport_objects so using (id)
join "source".sport_zones sz on sz.object_id = c.id 
join "source".sport_zones_to_kinds szk on szk.sport_zone_id = sz.id
where (
		NULLIF('%obj_name%', '') is null or
		so.name = any(string_to_array('%obj_name%', ';'))
	)
	and
	(
		NULLIF('%org_id%', '') is null or
		so.org_id = any(string_to_array('%org_id%', ';')::int[])
	)
	and
	(
		NULLIF('%sz_name%', '') is null or
		sz.name = any(string_to_array('%sz_name%', ';'))
	)
	and
	(
		NULLIF('%sz_type%', '') is null or
		sz.zone_type = any(string_to_array('%sz_type%', ';')::int[])
	)
	and
	(
		NULLIF('%s_kind%', '') is null or
		szk.sport_kind_id = any(string_to_array('%s_kind%', ';')::int[])
	)
	and
	(
		NULLIF('%buf%', '') is null or
		c.buffer = any(string_to_array('%buf%', ';')::int[])
	)
	
-- SQLVIEW FILTER FOR BUFFERS
select distinct on (c.id) c.id, c.geom
from geo.objects_buffer_iso c
left join "source".sport_objects so using (id)
left join "source".sport_zones sz on sz.object_id = c.id 
left join "source".sport_zones_to_kinds szk on szk.sport_zone_id = sz.id
where (
		NULLIF('%obj_name%', '') is null or
		so.name = any(string_to_array('%obj_name%', ';'))
	)
	and
	(
		NULLIF('%org_id%', '') is null or
		so.org_id = any(string_to_array('%org_id%', ';')::int[])
	)
	and
	(
		NULLIF('%sz_name%', '') is null or
		sz.name = any(string_to_array('%sz_name%', ';'))
	)
	and
	(
		NULLIF('%sz_type%', '') is null or
		sz.zone_type = any(string_to_array('%sz_type%', ';')::int[])
	)
	and
	(
		NULLIF('%s_kind%', '') is null or
		szk.sport_kind_id = any(string_to_array('%s_kind%', ';')::int[])
	)
	and
	(
		NULLIF('%buf%', '') is null or
		c.buffer = any(string_to_array('%buf%', ';')::int[])
	)


-- Присвоение спорт. зонам id гексагона, на которые она распростроняет свою доступность
with hex_join as (
	select o.id, g.id as hex_id
	from geo.objects_buffer_iso o 
	left join geo.grid_hex_wgs_centroid g on st_intersects(g.geom, o.geom)
	join geo.objects_centroids c on o.id=c.id
)
select z.id, array_agg(hex_id) hex_ids
into geo.zones_arrays_hexagons
from "source".sport_zones z
join hex_join h
on h.id=z.object_id
group by z.id

-- SQLVIEW thresholds for heatmap square
with zones as (
	select distinct on (sz.id) sz.id, sz.square 
	from  "source".sport_zones sz
	left join "source".sport_objects so on so.id = sz.object_id 
	left join "source".sport_zones_to_kinds szk on sz.id = szk.sport_zone_id 
	where (
			NULLIF('%obj_name%', '') is null or
			so.name = any(string_to_array('%obj_name%', ';'))
		)
		and
		(
			NULLIF('%org_id%', '') is null or
			so.org_id = any(string_to_array('%org_id%', ';')::int[])
		)
		and
		(
			NULLIF('%sz_name%', '') is null or
			sz.name = any(string_to_array('%sz_name%', ';'))
		)	
		and
		(
			NULLIF('%sz_type%', '') is null or
			sz.zone_type = any(string_to_array('%sz_type%', ';')::int[])
		)	
		and
		(
			NULLIF('%bu%', '') is null or
			so.buffer = any(string_to_array('%buf%', ';')::int[])
		)
		and
		(
			NULLIF('%s_kind%', '') is null or
			szk.sport_kind_id = any(string_to_array('%s_kind%', ';')::int[])
		)
)
, zones_to_hex as (
	select unnest(h.hex_ids) hex_id, square
	from zones z, geo.zones_arrays_hexagons h 
	where z.id=h.id
)
, hex_sum as (
	select hex_id, sum(square) square
	from zones_to_hex
	group by hex_id
)
select ar[1] class_empty, ar[2] class_1, ar[3] class_2, ar[4] class_3, ar[5] class_4, ar[6] class_5
from (
	select array_prepend(.9, geo.CDB_JenksBins(array_agg(h.square), 5, 0)::numeric[]) ar
	from hex_sum h
) a

-- SQLVIEW FILTER FOR HEATMAP SQUARE 
with zones as (
	select distinct on (sz.id) sz.id, sz.square 
	from  "source".sport_zones sz
	left join "source".sport_objects so on so.id = sz.object_id 
	left join "source".sport_zones_to_kinds szk on sz.id = szk.sport_zone_id 
	where (
			NULLIF('%obj_name%', '') is null or
			so.name = any(string_to_array('%obj_name%', ';'))
		)
		and
		(
			NULLIF('%org_id%', '') is null or
			so.org_id = any(string_to_array('%org_id%', ';')::int[])
		)
		and
		(
			NULLIF('%sz_name%', '') is null or
			sz.name = any(string_to_array('%sz_name%', ';'))
		)	
		and
		(
			NULLIF('%sz_type%', '') is null or
			sz.zone_type = any(string_to_array('%sz_type%', ';')::int[])
		)	
		and
		(
			NULLIF('%buf%', '') is null or
			so.buffer = any(string_to_array('%buf%', ';')::int[])
		)
		and
		(
			NULLIF('%s_kind%', '') is null or
			szk.sport_kind_id = any(string_to_array('%s_kind%', ';')::int[])
		)
)
, zones_to_hex as (
	select unnest(h.hex_ids) hex_id, square
	from zones z, geo.zones_arrays_hexagons h 
	where z.id=h.id
)
, hex_sum as (
	select hex_id id, sum(square) square
	from zones_to_hex
	group by hex_id
)
select g.*, coalesce(square, null, 0) sum_square
from geo.grid_hex_wgs g
left join hex_sum using(id)


-- НАСЕЛЕНИЕ

-- Жилые дома
with living_unoms as (
	select a.unom, st_centroid(a.geom) geom_point, geom geom_poly, st_area(st_transform(geom, 32637)) square
	from ar.ar_poly_03_09_wgs a 
	inner join (select distinct unom::int from temp.nasel_geo_deg_20210903_2) j
	using (unom)
)
, koef as (
	select o.geom, avg(population)/sum(square) square_koef 
	from ar.okruga_wgs o 
	left join living_unoms u
	on st_intersects (u.geom_point, o.geom)
	group by o.geom 
)
select l.*, (square_koef*square)::int popul 
into ar.living_unoms
from living_unoms l
left join koef k
on st_intersects(l.geom_point, k.geom)

CREATE INDEX living_unoms_geom_idx ON geo.living_unoms
  USING gist (geom);
 
 CREATE INDEX objs_count_geom_idx ON geo.objs_count
  USING gist (geom);

select id, st_transform(st_buffer(st_transform(geom, 32637), 100), 4326) geom, unom, geom_point, square, popul
into geo.living_unoms_buffer_100
from geo.living_unoms

 CREATE INDEX living_unoms_buffer_100_geom_idx ON geo.living_unoms_buffer_100
  USING gist (geom);

-- Heatmap population
select geom, coalesce(population, null, 0) population
into geo.grid_hex_wgs_population
from grid_hex_wgs
left join 
 (
	select g.id, sum(popul) population
	from geo.living_unoms_buffer_100 t, geo.grid_hex_wgs_centroid g
	where st_intersects(t.geom, g.geom)
	group by g.id
 ) c
using (id)

CREATE INDEX grid_hex_wgs_population_geom_idx ON geo.grid_hex_wgs_population
  USING gist (geom);

-- Присвоение спорт. зонам unom домов, на которые она распростроняет свою доступность
with house_join as (
	select o.id, u.unom
	from geo.objects_buffer_iso o 
	left join geo.living_unoms u on st_intersects(u.geom, o.geom)
)
select z.id, array_agg(unom) unoms
into geo.zones_arrays_unoms
from "source".sport_zones z
join house_join h
on h.id=z.object_id
group by z.id

-- Присвоение unom-ам домов id гексагона, на которые интерполируются данные
with house_join as (
	select b.unom, g.id hex_id
	from geo.living_unoms_buffer_100 b
	left join geo.grid_hex_wgs g on st_intersects(b.geom, g.geom)
)
select u.unom, array_agg(hex_id) hex_ids
into geo.unoms_arrays_hexagons
from house_join u
group by u.unom


-- SQLVIEW THRESHOLDS FOR HEATMAP PROVISION
with zones as (
	select distinct on (sz.id) sz.id, sz.square 
	from  "source".sport_zones sz
	left join "source".sport_objects so on so.id = sz.object_id 
	left join "source".sport_zones_to_kinds szk on sz.id = szk.sport_zone_id 
	where (
			NULLIF('%obj_name%', '') is null or
			so.name = any(string_to_array('%obj_name%', ';'))
		)
		and
		(
			NULLIF('%org_name%', '') is null or
			so.org_id = any(string_to_array('%org_name%', ';')::int[])
		)
		and
		(
			NULLIF('%sz_name%', '') is null or
			sz.name = any(string_to_array('%sz_name%', ';'))
		)	
		and
		(
			NULLIF('%sz_type%', '') is null or
			sz.zone_type = any(string_to_array('%sz_type%', ';')::int[])
		)	
		and
		(
			NULLIF('%buf%', '') is null or
			so.buffer = any(string_to_array('%buf%', ';')::int[])
		)
		and
		(
			NULLIF('%s_kind%', '') is null or
			szk.sport_kind_id = any(string_to_array('%s_kind%', ';')::int[])
		)
)
, zones_to_unom as (
	select unnest(h.unoms) unom, square
	from zones z, geo.zones_arrays_unoms h 
	where z.id=h.id
)
, unom_sum as (
	select unom, sum(z.square) square
	from zones_to_unom z
	group by unom
)
, stat_aggr as (
	select l.unom, round(s.square/popul*100000, 0) square_provision from unom_sum s
	right join geo.living_unoms l using (unom)
)
, stats_to_hex as (
	select unnest(h.hex_ids) hex_id, s.square_provision
	from stat_aggr s, geo.unoms_arrays_hexagons h
	where s.unom=h.unom
)
, heat as (
	select s.hex_id, g.geom, avg(square_provision) square_provision
	from geo.grid_hex_wgs g, stats_to_hex s
	where g.id = s.hex_id
	group by s.hex_id, g.geom
)
SELECT 0.9 class_empty,
	PERCENTILE_CONT(0.2) WITHIN GROUP(ORDER BY square_provision) class_1, 
	PERCENTILE_CONT(0.4) WITHIN GROUP(ORDER BY square_provision) class_2,
	PERCENTILE_CONT(0.6) WITHIN GROUP(ORDER BY square_provision) class_3,
	PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY square_provision) class_4,
	PERCENTILE_CONT(1) WITHIN GROUP(ORDER BY square_provision) class_5
FROM heat;


-- SQLVIEW FILTER FOR HEATMAP PROVISION
with zones as (
	select distinct on (sz.id) sz.id, sz.square 
	from  "source".sport_zones sz
	left join "source".sport_objects so on so.id = sz.object_id 
	left join "source".sport_zones_to_kinds szk on sz.id = szk.sport_zone_id 
	where (
			NULLIF('%obj_name%', '') is null or
			so.name = any(string_to_array('%obj_name%', ';'))
		)
		and
		(
			NULLIF('%org_name%', '') is null or
			so.org_id = any(string_to_array('%org_name%', ';')::int[])
		)
		and
		(
			NULLIF('%sz_name%', '') is null or
			sz.name = any(string_to_array('%sz_name%', ';'))
		)	
		and
		(
			NULLIF('%sz_type%', '') is null or
			sz.zone_type = any(string_to_array('%sz_type%', ';')::int[])
		)	
		and
		(
			NULLIF('%buf%', '') is null or
			so.buffer = any(string_to_array('%buf%', ';')::int[])
		)
		and
		(
			NULLIF('%s_kind%', '') is null or
			szk.sport_kind_id = any(string_to_array('%s_kind%', ';')::int[])
		)
)
, zones_to_unom as (
	select unnest(h.unoms) unom, square
	from zones z, geo.zones_arrays_unoms h 
	where z.id=h.id
)
, unom_sum as (
	select unom, sum(z.square) square
	from zones_to_unom z
	group by unom
)
, stat_aggr as (
	select l.unom, coalesce (round(s.square/popul*100000, 0), null, 0 ) square_provision from unom_sum s
	right join geo.living_unoms l using (unom)
)
, stats_to_hex as (
	select unnest(h.hex_ids) hex_id, s.square_provision
	from stat_aggr s, geo.unoms_arrays_hexagons h
	where s.unom=h.unom
)
select s.hex_id, g.geom, avg(square_provision) square_provision
from geo.grid_hex_wgs g, stats_to_hex s
where g.id = s.hex_id
group by s.hex_id, g.geom
 

-- analysis of choosen territory

-- Присвоение unom'ам id спорт. зон, которые доступны для этих домов
with house_join as (
	select o.id, u.unom
	from geo.objects_buffer_iso o 
	left join geo.living_unoms u on st_intersects(u.geom, o.geom)
)
select unom,  array_agg(z.id) ids
into geo.unoms_arrays_zones
from "source".sport_zones z
join house_join h
on h.id=z.object_id
group by unom

-- SQLVIEW provision by custom territory
with zones as (
	select distinct on (sz.id) sz.id, sz.square 
	from  "source".sport_zones sz
	left join "source".sport_objects so on so.id = sz.object_id 
	left join "source".sport_zones_to_kinds szk on sz.id = szk.sport_zone_id 
	where (
		NULLIF('%obj_name%', '') is null or
		so.name = any(string_to_array('%obj_name%', ';'))
	)
	and
	(
		NULLIF('%org_id%', '') is null or
		so.org_id = any(string_to_array('%org_id%', ';')::int[])
	)
	and
	(
		NULLIF('%sz_name%', '') is null or
		sz.name = any(string_to_array('%sz_name%', ';'))
	)
	and
	(
		NULLIF('%sz_type%', '') is null or
		sz.zone_type = any(string_to_array('%sz_type%', ';')::int[])
	)
	and
	(
		NULLIF('%s_kind%', '') is null or
		szk.sport_kind_id = any(string_to_array('%s_kind%', ';')::int[])
	)
	and
	(
		NULLIF('%buf%', '') is null or
		c.buffer = any(string_to_array('%buf%', ';')::int[])
	)
)
, houses as (
	select u.*
	from geo.living_unoms u 
	where st_intersects(u.geom, st_geomfromgeojson('%geojson%'))
)
, all_zones_for_unoms as (
	select unnest(uz.ids) id, h.unom
	from houses h, geo.unoms_arrays_zones uz
	where h.unom=uz.unom
)
, zones_filter as (
	select az.id, az.unom, z.square
	from all_zones_for_unoms az, zones z
	where az.id=z.id
)
, zone_types as (
	select zf.*, zt."name" zone_type 
	from zones_filter zf
	join "source".sport_zones sz on sz.id = zf.id 
	join "source".zone_types zt on zt.id = sz.zone_type 
)
, sport_kinds as (
	select zf.id,  count (distinct sk."name") sport_kinds_count
	from zones_filter zf
	join "source".sport_zones sz on sz.id = zf.id 
	join "source".sport_zones_to_kinds zk on zk.sport_zone_id = sz.id 
	join "source".sport_kinds sk on zk.sport_kind_id = sk.id
	where NULLIF('', '') is null or
		zk.sport_kind_id = any(string_to_array('', ';')::int[])
	group by zf.id
)
, aggr_by_unom as (
	select zt.unom, 
	count(zt.id)/avg(popul)*100000 sport_zones_provision, 
	array_agg(zone_type) zone_types, 
	sum(zt.square)/avg(popul)*100000sport_square_provision, 
	avg(sk.sport_kinds_count)/avg(popul)*100000 sport_kinds_provision, 
	avg(popul) population,
	avg(zt.square) square_sum
	from zone_types zt, sport_kinds sk, houses h
	where zt.id=sk.id and h.unom=zt.unom
	group by zt.unom
)
, zone_types_distinct as (
	select distinct on (id) id, zone_type, square
	from zone_types
)
, agg_by_type as (
	select zone_type, count(zone_type) type_count, round(sum(square)) sport_square_sum
	from zone_types_distinct
	group by zone_type
	order by count(zone_type) desc
)
, zone_types_names as (
	select json_agg(distinct zone_type) sport_zones_types, sum (sport_square_sum) sport_square_sum
	from agg_by_type
)
, all_aggregate as (
	select round(avg(sport_zones_provision), 0) sport_zones_provision, 
	round(avg(sport_square_provision), 0) sport_square_provision, 
	round(avg(sport_kinds_provision), 0) sport_kinds_provision,
	sum (population) population
	from aggr_by_unom, zone_types_names
)
select sport_zones_provision, 
	sport_square_provision, 
	sport_kinds_provision,
	population,
	sport_square_sum,
	sport_zones_types::text
	from all_aggregate, zone_types_names
	
	
-- SQLVIEW sport stats by custom territory
with zones as (
	select distinct on (sz.id) sz.id, sz.square 
	from  "source".sport_zones sz
	left join "source".sport_objects so on so.id = sz.object_id 
	left join "source".sport_zones_to_kinds szk on sz.id = szk.sport_zone_id 
	where (
		NULLIF('%obj_name%', '') is null or
		so.name = any(string_to_array('%obj_name%', ';'))
	)
	and
	(
		NULLIF('%org_id%', '') is null or
		so.org_id = any(string_to_array('%org_id%', ';')::int[])
	)
	and
	(
		NULLIF('%sz_name%', '') is null or
		sz.name = any(string_to_array('%sz_name%', ';'))
	)
	and
	(
		NULLIF('%sz_type%', '') is null or
		sz.zone_type = any(string_to_array('%sz_type%', ';')::int[])
	)
	and
	(
		NULLIF('%s_kind%', '') is null or
		szk.sport_kind_id = any(string_to_array('%s_kind%', ';')::int[])
	)
	and
	(
		NULLIF('%buf%', '') is null or
		c.buffer = any(string_to_array('%buf%', ';')::int[])
	)
)
, houses as (
	select u.*
	from geo.living_unoms u 
	where st_intersects(u.geom, st_geomfromgeojson('%geojson%'))
)
, all_zones_for_unoms as (
	select unnest(uz.ids) id, h.unom
	from houses h, geo.unoms_arrays_zones uz
	where h.unom=uz.unom
)
, zones_filter as (
	select az.id, az.unom, z.square
	from all_zones_for_unoms az, zones z
	where az.id=z.id
)
, zone_types as (
	select zf.*, zt."name" zone_type 
	from zones_filter zf
	join "source".sport_zones sz on sz.id = zf.id 
	join "source".zone_types zt on zt.id = sz.zone_type 
)
, zone_to_sport_kind as (
	select distinct on (zf.id)zf.id, sk."name"
	from zones_filter zf
	join "source".sport_zones sz on sz.id = zf.id 
	join "source".sport_zones_to_kinds zk on zk.sport_zone_id = sz.id 
	join "source".sport_kinds sk on zk.sport_kind_id = sk.id
	where NULLIF('', '') is null or
		zk.sport_kind_id = any(string_to_array('', ';')::int[])
)
, sport_kinds_by_name as (
	select json_agg(json_build_object('zone_type', sport_kind,'amount',amount)) sport_kinds_amount
	from (
		select "name" sport_kind, count("name") amount from zone_to_sport_kind
		group by "name"
		order by count("name") desc
	) ag
)
, zone_types_distinct as (
	select distinct on (id) id, zone_type, square
	from zone_types
)
, agg_by_type as (
	select zone_type, count(zone_type) type_count, round(sum(square)) sport_square_sum
	from zone_types_distinct
	group by zone_type
	order by count(zone_type) desc
)
, zone_types_names as (
	select json_agg(json_build_object('zone_type', zone_type,'amount',type_count)) sport_zones_amount, sum (sport_square_sum) sport_square_sum
	from agg_by_type
)
select
sport_square_sum,
sport_zones_amount::text,
sport_kinds_amount::text
from zone_types_names, sport_kinds_by_name
