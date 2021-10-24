create extension postgis;

drop table if exists source.sport_table_raw;

CREATE TABLE source.sport_table_raw (
  "id Объекта" int4,
  "Объект" VARCHAR(1000),
  "Адрес" VARCHAR(1000),
  "id Ведомственной Организации" int4,
  "Ведомственная Организация" VARCHAR(1000),
  "id Спортзоны" int4,
  "Спортзона" VARCHAR(1000),
  "Тип спортзоны" VARCHAR(1000),
  "Доступность номер" int4,
  "Доступность" VARCHAR(255),
  "Вид спорта" VARCHAR(1000),
  "Широта (Latitude)" numeric,
  "Долгота (Longitude)" numeric,
  "Площадь спортзоны" numeric 
);

select "id Объекта" object_id, "Объект" object_name, "id Ведомственной Организации" org_id,"Ведомственная Организация" org_name, 
"id Спортзоны" sportzone_id, "Спортзона" sportzone_name, "Тип спортзоны" sportzone_type, 
"Доступность" accessib, "Вид спорта" sport, "Широта (Latitude)" lat,  "Долгота (Longitude)" lon,  "Площадь спортзоны" square
from sport_table_raw str;

drop table if exists source.sport_kinds cascade;

select distinct "Вид спорта" as name
into source.sport_kinds
from source.sport_table_raw str;

alter table source.sport_kinds
add column id serial;

ALTER TABLE source.sport_kinds ADD PRIMARY KEY (id);

drop table if exists source.zone_types cascade;

select distinct "Тип спортзоны" as name
into source.zone_types
from source.sport_table_raw str;

alter table source.zone_types
add column id serial;

ALTER TABLE source.zone_types ADD PRIMARY KEY (id);

drop table if exists source.organizations cascade;

select distinct "id Ведомственной Организации" id,"Ведомственная Организация" as name
into source.organizations
from source.sport_table_raw str 
order by "id Ведомственной Организации";

ALTER TABLE source.organizations ADD PRIMARY KEY (id);

drop table if exists source.sport_objects cascade;

select "id Объекта" id, "Объект" as name, "id Ведомственной Организации" org_id, "Доступность номер" accessib, st_setsrid(st_point("Долгота (Longitude)", "Широта (Latitude)"), 4326) geom
into source.sport_objects
from source.sport_table_raw str 
group by "id Объекта", "Объект", "id Ведомственной Организации",
"Доступность номер", geom;

ALTER TABLE source.sport_objects ADD PRIMARY KEY (id);
ALTER TABLE source.sport_objects ADD CONSTRAINT sport_objects_orgs FOREIGN KEY (org_id) REFERENCES organizations (id);

drop table if exists source.sport_zones cascade;

select distinct on ("id Спортзоны") "id Спортзоны" id, "Спортзона" as name, zt.id zone_type, "id Объекта" object_id, "Площадь спортзоны" square
into source.sport_zones
from source.sport_table_raw str 
join zone_types zt on zt.name = str."Тип спортзоны";

ALTER TABLE source.sport_zones ADD PRIMARY KEY (id);
ALTER TABLE source.sport_zones ADD CONSTRAINT sport_zones_objects FOREIGN KEY (object_id) REFERENCES sport_objects (id);
ALTER TABLE source.sport_zones ADD CONSTRAINT sport_zones_types FOREIGN KEY (zone_type) REFERENCES zone_types (id);

drop table if exists source.sport_zones_to_kinds cascade;

select distinct "id Спортзоны" sport_zone_id, sk.id sport_kind_id
into source.sport_zones_to_kinds
from source.sport_table_raw str
join sport_kinds sk on sk.name = str."Вид спорта";

alter table source.sport_zones_to_kinds
add column id serial;

ALTER TABLE source.sport_zones_to_kinds ADD PRIMARY KEY (id);
ALTER TABLE source.sport_zones_to_kinds ADD CONSTRAINT sport_zones_to_kinds_zones FOREIGN KEY (sport_zone_id) REFERENCES sport_zones (id);
ALTER TABLE source.sport_zones_to_kinds ADD CONSTRAINT sport_zones_to_kinds_kinds FOREIGN KEY (sport_kind_id) REFERENCES sport_kinds (id);


alter table "source".sport_objects
add column  buffer int

update "source".sport_objects
set buffer = CASE 
		WHEN accessib=1  THEN 5000
		WHEN accessib=2  THEN 3000
		WHEN accessib=3  THEN 1000
		WHEN accessib=4  THEN 500 
	end 