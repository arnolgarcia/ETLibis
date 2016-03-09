/*
Descripcion:	Scripts para la generacion de las tablas vistas y tablas para datos acumulados del ibis:
					- v_ibis_consolidado_last_day
					- v_ibis_consolidado_last_week
					- v_ibis_consolidado_last_month
					- v_ibis_resumen_last
					- ibis_resumen_last
Parametros?:	Si:
					- SRID asociado al geom de los datos de radar, por defecto esta en 1000
Version:		1.0
Fecha:			08/03/2016
Autor:			Arnol
*/


/*
-- Crear vistas para el desplazamiento acumulado del ultimo dia
*/
-- Crear vista 'v_ibis_consolidado_last_day'
CREATE VIEW "ibis"."v_ibis_consolidado_last_day" AS (
	SELECT
		t1."id" as ibis_puntos_id,
		t2.desplazamiento as deformacion_acumulada, -- en unidades de [mm]
		t2.desplazamiento/24 as velocidad_mm_hr -- en unidades de [mm/hr]
	FROM 
		ibis.ibis_puntos t1,
		ibis.ibis_consolidado_dia t2,
		ibis.ibis_radares t3
	WHERE
		t1."id" = t2.ibis_puntos_id AND
		t2.fecha = (t3.fecha_fin)::DATE
		-- No se necesita filtrar por ibis_radares_id pues el ibis_puntos_id es unico
)
;


/*
-- Crear vistas para el desplazamiento acumulado de la ultima semana
*/
-- Crear vista 'v_ibis_consolidado_last_week'
CREATE VIEW "ibis"."v_ibis_consolidado_last_week" AS (
	SELECT
		t1."id" as ibis_puntos_id,
		SUM(t2.desplazamiento) as deformacion_acumulada, -- en unidades de [mm]
		AVG(t2.desplazamiento)/24 as velocidad_mm_hr -- en unidades de [mm/hr]
	FROM 
		ibis.ibis_puntos t1,
		ibis.ibis_consolidado_dia t2,
		ibis.ibis_radares t3
	WHERE
		t1."id" = t2.ibis_puntos_id AND
		t2.fecha > (t3.fecha_fin)::DATE - INTERVAL '7 days'
		-- No se necesita filtrar por ibis_radares_id pues el ibis_puntos_id es unico
	GROUP BY
		t1."id"
)
;


/*
-- Crear vistas para el desplazamiento acumulado del ultimo mes
*/
-- Crear vista 'v_ibis_consolidado_last_month'
CREATE VIEW "ibis"."v_ibis_consolidado_last_month" AS (
	SELECT
		t1."id" AS ibis_puntos_id,
		SUM(t2.desplazamiento) AS deformacion_acumulada, -- en unidades de [mm]
		AVG(t2.desplazamiento)/24 AS velocidad_mm_hr -- en unidades de [mm/hr]
	FROM 
		ibis.ibis_puntos t1,
		ibis.ibis_consolidado_dia t2,
		ibis.ibis_radares t3
	WHERE
		t1."id" = t2.ibis_puntos_id AND
		t2.fecha > (t3.fecha_fin)::DATE - INTERVAL '1 month'
		-- No se necesita filtrar por ibis_radares_id pues el ibis_puntos_id es unico
	GROUP BY
		t1."id"
)
;


/*
-- Crear vistas con los desplazamientos acumulados del ultimo dia, ultima semana y ultimo mes
*/
-- Crear vista 'v_ibis_resumen_last'
CREATE VIEW "ibis"."v_ibis_resumen_last" AS (
	SELECT
		t1."id" AS ibis_puntos_id,
		t1.ibis_radares_id,
		t1.x,
		t1.y,
		t1.geom,
		td.deformacion_acumulada AS deformacion_acumulada_last_day,
		tw.deformacion_acumulada AS deformacion_acumulada_last_week,
		tm.deformacion_acumulada AS deformacion_acumulada_last_month,
		td.velocidad_mm_hr AS velocidad_last_day,
		tw.velocidad_mm_hr AS velocidad_last_week,
		tm.velocidad_mm_hr AS velocidad_last_month
	FROM
		ibis.ibis_puntos t1,
		ibis.v_ibis_consolidado_last_day td,
		ibis.v_ibis_consolidado_last_week tw,
		ibis.v_ibis_consolidado_last_month tm
	WHERE
		t1."id" = td.ibis_puntos_id AND
		t1."id" = tm.ibis_puntos_id AND
		t1."id" = tw.ibis_puntos_id
	ORDER BY
		t1."id"
)
;


/*
-- Crear tabla a partir de la vista 'v_ibis_resumen_last'
*/
-- Crear tabla 'ibis_resumen_last'
CREATE TABLE "ibis"."ibis_resumen_last"(
	"ibis_puntos_id" int4 NOT NULL,
	"ibis_radares_id" int4 NOT NULL,
	"x" float8,
	"y" float8,
	"deformacion_acumulada_last_day" float8,
	"deformacion_acumulada_last_week" float8,
	"deformacion_acumulada_last_month" float8,
	"velocidad_last_day" float8,
	"velocidad_last_week" float8,
	"velocidad_last_month" float8,
	PRIMARY KEY ("ibis_puntos_id")
)
WITH (OIDS=FALSE)
;

-- Asignar a usuario 'postgres'
ALTER TABLE ibis.ibis_resumen_last OWNER TO "postgres"
;

-- Agregar campo geom
ALTER TABLE ibis.ibis_resumen_last ADD COLUMN geom geometry (Point, 1000)
;

-- Agregar llaves foraneas
ALTER TABLE "ibis"."ibis_resumen_last"
ADD CONSTRAINT "ibis_resumen_last__ibis_puntos_id__fkey" FOREIGN KEY ("ibis_puntos_id") REFERENCES "ibis"."ibis_puntos" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT "ibis_resumen_last__ibis_radares_id__fkey" FOREIGN KEY ("ibis_radares_id") REFERENCES "ibis"."ibis_radares" ("id") ON DELETE CASCADE ON UPDATE CASCADE
;


/*
-- Crear funcion para actualizar tabla 'ibis_resumen_last'
*/
-- Crear funcion
CREATE OR REPLACE FUNCTION ibis.fn_update_ibis_resumen_last() RETURNS VOID AS $$
	-- Eliminar valores antiguos
	TRUNCATE ibis.ibis_resumen_last;

	-- Insertar valores a partir de la vista 'ibis_resumen_last'
	INSERT INTO ibis.ibis_resumen_last(
		"ibis_puntos_id",
		"ibis_radares_id",
		"x",
		"y",
		"deformacion_acumulada_last_day",
		"deformacion_acumulada_last_week",
		"deformacion_acumulada_last_month",
		"velocidad_last_day",
		"velocidad_last_week",
		"velocidad_last_month",
		"geom"
	)
		SELECT
			t1.ibis_puntos_id,
			t1.ibis_radares_id,
			t1.x,
			t1.y,
			t1.deformacion_acumulada_last_day,
			t1.deformacion_acumulada_last_week,
			t1.deformacion_acumulada_last_month,
			t1.velocidad_last_day,
			t1.velocidad_last_week,
			t1.velocidad_last_month,
			t1.geom
		FROM
			ibis.v_ibis_resumen_last t1
	;
$$ LANGUAGE SQL;
