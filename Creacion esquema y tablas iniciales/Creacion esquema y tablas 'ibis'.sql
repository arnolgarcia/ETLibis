/*
Descripcion:	Scripts para la generacion de las tablas basicas del esquema 'ibis', estas son:
					- ibis_consolidado_dia
					- ibis_puntos
					- ibis_radares
Version:		1.0
Fecha:			08/03/2016
Autor:			Arnol
*/

/*
-- Creacion del esquema 'ibis'
*/
CREATE SCHEMA ibis
;


/*
-- Creacion de tabla 'ibis_radares'
*/
-- Crear secuencia 'ibis_radares_seq'
CREATE SEQUENCE ibis.ibis_radares_seq
;

-- Crear tabla 'ibis_radares
CREATE TABLE ibis.ibis_radares (
	"id" int4 DEFAULT nextval('ibis.ibis_radares_seq'::regclass) NOT NULL,
	"fecha_ini" date,
	"fecha_fin" date,
	"nro_dias" int8,
	"nro_puntos" float8,
	"descripcion" varchar(1000) COLLATE "default",
	PRIMARY KEY ("id")
)
WITH (OIDS=FALSE)
;

-- Asignar a usuario 'postgres'
ALTER TABLE ibis.ibis_radares OWNER TO "postgres"
;


/*
-- Creacion de tabla 'ibis_puntos'
*/
-- Crear secuencia 'ibis_puntos_seq'
CREATE SEQUENCE ibis.ibis_puntos_seq;

-- Crear tabla 'ibis_puntos'
CREATE TABLE ibis.ibis_puntos (
	id int4 DEFAULT nextval('ibis.ibis_puntos_seq'::regclass) NOT NULL,
	ibis_radares_id int4 NOT NULL,
	x float8 NOT NULL,
	y float8 NOT NULL,
	PRIMARY KEY(id),
	FOREIGN KEY ("ibis_radares_id") REFERENCES "ibis"."ibis_radares" ("id") ON DELETE CASCADE ON UPDATE CASCADE
)
WITH (OIDS=FALSE
);

-- Asignar a usuario 'postgres'
ALTER TABLE ibis.ibis_puntos OWNER TO "postgres"
;

-- Agregar campo geom
ALTER TABLE ibis.ibis_puntos ADD COLUMN geom geometry (Point, 1000)
;


/*
-- Creacion de tabla 'ibis_consolidado_dia'
*/
-- Crear tabla 'ibis_consolidado_dia'
CREATE TABLE "ibis"."ibis_consolidado_dia" (
	"fecha" date NOT NULL,
	"ibis_radares_id" int8 NOT NULL,
	"ibis_puntos_id" int4 NOT NULL,
	"x" float8 NOT NULL,
	"y" float8 NOT NULL,
	"desplazamiento" float8,
	"geom" "public"."geometry",
	PRIMARY KEY ("fecha", "ibis_puntos_id")
)
WITH (OIDS=FALSE)
;

-- Asignar tabla a usuario 'postgres'
ALTER TABLE "ibis"."ibis_consolidado_dia" OWNER TO "postgres"
;

-- Crear llaves foraneas
ALTER TABLE "ibis"."ibis_consolidado_dia"
ADD CONSTRAINT "ibis_consolidado_dia__ibis_radares_id__fkey" FOREIGN KEY ("ibis_radares_id") REFERENCES "ibis"."ibis_radares" ("id"),
ADD CONSTRAINT "ibis_consolidado_dia__ibis_puntos_id__fkey" FOREIGN KEY ("ibis_puntos_id") REFERENCES "ibis"."ibis_puntos" ("id")
;

/*-- Esto ya no es necesario dado las llaves primarias y el resto de las tablas. Igual lo dejo por si hay cambios en el futuro
-- Crear indices para 
CREATE INDEX "idx_ibis_consolidado_dia" ON "ibis"."NewTable" USING gist ("geom" "public"."gist_geometry_ops_2d");
CREATE INDEX "idx_ibis_consolidado_dia_fecha" ON "ibis"."NewTable" USING btree ("fecha" "pg_catalog"."date_ops");
CREATE INDEX "idx_ibis_consolidado_id_ibis_radar" ON "ibis"."NewTable" USING btree ("id_ibis_radar" "pg_catalog"."int8_ops");
*/
