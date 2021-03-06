-- ############################################################################
-- STATS STATS STATS STATS STATS STATS STATS STATS STATS STATS STATS STATS STAT
-- ############################################################################

DROP SCHEMA IF EXISTS stats CASCADE;
CREATE SCHEMA stats;

-- CREO TABLA MASTER de LICITACIONES
-- tiene muchos campos! :O

DROP TABLE IF EXISTS stats.licitacion_master;

CREATE TABLE stats.licitacion_master AS
    SELECT
        t2.id            AS licitacion_id,
        t2.code          AS licitacion_codigo,
        t2.name          AS nombre,
        t2.descripcion,
        t2.tipo,
        t2.moneda,
        t2.nombre_responsable_contrato,
        t2.email_responsable_contrato,
        t2.fono_responsable_contrato,
        t2.nombre_responsable_pago,
        t2.email_responsable_pago,
        t2.buyer_id      AS organismo_id,
        t3.id            AS adjudicacion_id,
        t4.fecha_creacion :: TIMESTAMP,
        t4.fecha_cierre :: TIMESTAMP,
        t4.fecha_inicio :: TIMESTAMP,
        t4.fecha_final :: TIMESTAMP,
        t4.fecha_publicacion :: TIMESTAMP,
        t4.fecha_pub_respuestas :: TIMESTAMP,
        t4.fecha_acto_apertura_tecnica :: TIMESTAMP,
        t4.fecha_acto_apertura_economica :: TIMESTAMP,
        t4.fecha_estimada_adjudicacion :: TIMESTAMP,
        t4.fecha_estimada_firma :: TIMESTAMP,
        t4.fecha_adjudicacion :: TIMESTAMP,
        t4.fecha_soporte_fisico :: TIMESTAMP,
        t4.fecha_tiempo_evaluacion :: TIMESTAMP,
        t4.fechas_usuario :: TIMESTAMP,
        t4.fecha_visita_terreno :: TIMESTAMP,
        t4.fecha_entrega_antecedentes :: TIMESTAMP,
        t5.codigo_unidad,
        t5.nombre_unidad,
        t5.direccion_unidad,
        t5.comuna_unidad,
        t5.region_unidad,
        t5.rut_usuario,
        t5.codigo_usuario,
        t5.nombre_usuario,
        t5.cargo_usuario,
        t6.catalogo_organismo_id AS catalogo_organismo_id,
        t6.organismo_nombre      AS nombre_organismo,
        t6.organismo_nombre_corto AS nombre_organismo_plot,
        t6.ministerio_id,
        t6.ministerio_nombre          AS nombre_ministerio
    FROM public.tenders AS t2
        LEFT JOIN public.adjudications AS t3
            ON (t2.id = t3.tender_id)
        LEFT JOIN public.tender_dates AS t4
            ON (t2.id = t4.id)
        LEFT JOIN public_companies AS t5
            ON (t2.buyer_id = t5.id)
        INNER JOIN _jerarquia AS t6
            ON (t5.code = t6.organismo_codigo)
    ORDER BY t2.id;

CREATE INDEX licitacion_master_licitacion_id_idx
ON stats.licitacion_master
USING BTREE
(licitacion_id);

-- CREO TABLA DE ITEM_LICITACION_ORGANISMO_EMPRESA
-- Es la mejor, por lo tanto se llama master plop!

-- MASTER PLOPS

DROP TABLE IF EXISTS stats.master_plop_all;

CREATE TABLE stats.master_plop_all AS
    SELECT
        B.id                                                                                  AS licitacion_item_id,
        R.licitacion_id,
        R.nombre as licitacion_nombre,
        R.descripcion as licitacion_descripcion,
        R.licitacion_codigo,
        R.fecha_creacion,
        R.fecha_publicacion,
        R.fecha_adjudicacion,
        S.estado,
        R.catalogo_organismo_id                                                               AS organismo_id,
        R.nombre_organismo,
        R.nombre_organismo_plot                                                               AS nombre_organismo_corto,
        R.ministerio_id                                                                       AS ministerio_id,
        R.nombre_ministerio                                                                   AS nombre_ministerio,
        B.codigo_categoria :: INTEGER,
        XD.id                                                                                 AS categoria_id,
        XD.categoria_1                                                                        AS categoria_primer_nivel,
        XD.categoria_2                                                                        AS categoria_segundo_nivel,
        XD.categoria_3                                                                        AS categoria_tercer_nivel,
        B.codigo_producto :: INTEGER,
        B.nombre_producto,
        A.company_id,
        CC.nombre,
        CC.rut_sucursal,
        R.region_unidad                                                                       AS region,
        CASE WHEN cast(B.cantidad AS FLOAT) < cast(A.cantidad AS FLOAT)
            THEN cast(B.cantidad AS FLOAT)
        ELSE cast(A.cantidad AS FLOAT) END * cast(A.monto_unitario AS FLOAT) * QQ.tipo_cambio AS monto,
        cast(substring(S.fecha FROM 3 FOR 2) AS INTEGER)                                      AS mes,
        cast(substring(S.fecha FROM 5 FOR 4) AS INTEGER)                                      AS ano
    FROM tenders T
        INNER JOIN (
           SELECT
               ts.tender_id AS licitacion_id,
               ts.date AS fecha,
               max(ts.state) AS estado
           FROM tender_states ts JOIN
               (
                   SELECT
                       tender_id,
                       max(to_date(date, 'DDMMYYYY')) AS date
                   FROM tender_states
                   GROUP BY tender_id
               ) rs
                   ON ts.tender_id = rs.tender_id AND to_date(ts.date, 'DDMMYYY') = rs.date
           GROUP BY ts.tender_id, ts.date
       ) S
            ON T.id = S.licitacion_id
        LEFT JOIN tender_items B
            ON T.id = B.tender_id
        LEFT JOIN adjudication_items A
            ON B.id = A.tender_item_id
        INNER JOIN stats.licitacion_master R
            ON R.licitacion_id = B.tender_id
        INNER JOIN _currency QQ
            ON QQ.moneda = R.moneda
        INNER JOIN companies CC
            ON A.company_id = CC.id
        INNER JOIN _categoria_producto XD
            ON B.categoria = XD.categoria
    ORDER BY licitacion_id, licitacion_item_id;

CREATE INDEX master_plop_all_licitacion_nombre_idx
ON stats.master_plop_all
USING GIN (to_tsvector('spanish', licitacion_nombre));

CREATE INDEX master_plop_all_licitacion_descripcion_idx
ON stats.master_plop_all
USING GIN (to_tsvector('spanish',licitacion_descripcion));

CREATE INDEX master_plop_all_licitacion_id_idx
ON stats.master_plop_all
USING BTREE (licitacion_id);

CREATE INDEX master_plop_all_organismo_id_idx
ON stats.master_plop_all
USING BTREE (organismo_id);

CREATE INDEX master_plop_all_company_id_idx
ON stats.master_plop_all
USING BTREE (company_id);

CREATE INDEX master_plop_all_monto_idx
ON stats.master_plop_all
USING BTREE (monto);

CREATE INDEX master_plop_all_fecha_creacion_idx
ON stats.master_plop_all
USING BTREE (fecha_creacion);

CREATE INDEX master_plop_all_estado_idx
ON stats.master_plop_all
USING BTREE (estado);

DROP TABLE IF EXISTS stats.master_plop;

CREATE TABLE stats.master_plop AS
    SELECT *
    FROM stats.master_plop_all
    WHERE estado = 8
    ORDER BY licitacion_id, licitacion_item_id;

CREATE INDEX master_plop_licitacion_nombre_idx
ON stats.master_plop
USING GIN (to_tsvector('spanish', licitacion_nombre));

CREATE INDEX master_plop_licitacion_descripcion_idx
ON stats.master_plop
USING GIN (to_tsvector('spanish',licitacion_descripcion));

CREATE INDEX master_plop_licitacion_id_idx
ON stats.master_plop
USING BTREE (licitacion_id);

CREATE INDEX master_plop_organismo_id_idx
ON stats.master_plop
USING BTREE (organismo_id);

CREATE INDEX master_plop_company_id_idx
ON stats.master_plop
USING BTREE (company_id);

CREATE INDEX master_plop_monto_idx
ON stats.master_plop
USING BTREE (monto);

CREATE INDEX master_plop_fecha_creacion_idx
ON stats.master_plop
USING BTREE (fecha_creacion);

-- ESTADOS MAS RECIENTES

CREATE TABLE stats.licitacion_estado
(
    licitacion_id INTEGER PRIMARY KEY,
    estado        INTEGER NOT NULL
);

INSERT INTO stats.licitacion_estado (licitacion_id, estado)
    SELECT
        ts.tender_id,
        max(ts.state)
    FROM tender_states ts JOIN
        (
            SELECT
                tender_id,
                max(to_date(date, 'DDMMYYYY')) AS date
            FROM tender_states
            GROUP BY tender_id
        ) rs
            ON ts.tender_id = rs.tender_id AND to_date(ts.date, 'DDMMYYY') = rs.date
    GROUP BY ts.tender_id;

CREATE INDEX licitacion_estado_licitacion_id_idx
ON stats.licitacion_estado
USING BTREE (licitacion_id);

CREATE INDEX licitacion_estado_estado_idx
ON stats.licitacion_estado
USING BTREE (estado);

-- COMPARADOR

DROP TABLE IF EXISTS stats.ministerio_producto_stats;

CREATE TABLE stats.ministerio_producto_stats AS
    SELECT
        ministerio_id,
        categoria_id,
        categoria_tercer_nivel                                      AS categoria_nombre,
        nombre_ministerio                                           AS ministerio_nombre,
        monto_total,
        (monto_total / cantidad_licitaciones_adjudicadas) :: BIGINT AS monto_promedio,
        cantidad_proveedores                                        AS n_proveedores,
        cantidad_licitaciones_adjudicadas                           AS n_licitaciones_adjudicadas
    FROM (

             SELECT
                 categoria_id,
                 categoria_tercer_nivel,
                 ministerio_id,
                 nombre_ministerio,
                 sum(monto_total)                         AS monto_total,
                 count(cantidad_licitaciones_adjudicadas) AS cantidad_licitaciones_adjudicadas,
                 count(DISTINCT cantidad_proveedores)     AS cantidad_proveedores
             FROM
                 (
                     SELECT
                         categoria_id,
                         categoria_tercer_nivel,
                         ministerio_id,
                         nombre_ministerio,
                         monto :: BIGINT AS monto_total,
                         licitacion_id   AS cantidad_licitaciones_adjudicadas,
                         company_id      AS cantidad_proveedores
                     FROM stats.master_plop
                 ) AA
             GROUP BY categoria_id, categoria_tercer_nivel, ministerio_id, nombre_ministerio
         ) BB
    ORDER BY categoria_id, categoria_nombre, ministerio_id, ministerio_nombre;

-- CREO QUERIES PARA LAS VISUALIZACIONES DEL PRINCIPIO

-- MONTOS POR MINISTERIO, ORGANISMO

CREATE TABLE stats.ministerio_organismo_monto AS

    SELECT
        nombre_ministerio,
        nombre_organismo_corto AS nombre_organismo,
        sum(monto) AS monto
    FROM stats.master_plop
    GROUP BY nombre_ministerio, nombre_organismo_corto
    ORDER BY monto DESC;

-- query 1 desagregada

-- MONTOS POR MINISTERIO, ORGANISMO, REGION, SEMESTRE

CREATE TABLE stats.ministerio_organismo_region_semestre_monto AS
    SELECT
        nombre_ministerio,
        nombre_organismo_corto AS nombre_organismo,
        sum(monto)    AS monto,
        CASE WHEN mes <= '6' AND ano = '2013'
            THEN 'S1'
        WHEN mes > '6' AND ano = '2013'
            THEN 'S2'
        WHEN mes <= '6' AND ano = '2014'
            THEN 'S3'
        WHEN mes > '6' AND ano = '2014'
            THEN 'S4'
        WHEN mes <= '6' AND ano = '2015'
            THEN 'S5'
        ELSE 'S6' END AS Semestre,
        region
    FROM stats.master_plop
    GROUP BY nombre_ministerio, nombre_organismo_corto, semestre, region;

-- query 2

-- MONTOS POR PROVEEDOR

DROP TABLE IF EXISTS stats.proveedor_monto;

CREATE TABLE stats.proveedor_monto AS
    SELECT
        company_id,
        sum(coalesce(monto, 0)) AS monto
    FROM stats.master_plop
    GROUP BY company_id
    ORDER BY monto DESC
    LIMIT 5;

--query 2 desagregada

-- MONTOS POR PROVEEDOR, SEMESTRE

DROP TABLE IF EXISTS temp2;

CREATE TEMP TABLE temp2 AS
    SELECT
        company_id,
        sum(monto)    AS monto,
        CASE WHEN mes <= '6' AND ano = '2013'
            THEN 'S1'
        WHEN mes > '6' AND ano = '2013'
            THEN 'S2'
        WHEN mes <= '6' AND ano = '2014'
            THEN 'S3'
        WHEN mes > '6' AND ano = '2014'
            THEN 'S4'
        WHEN mes <= '6' AND ano = '2015'
            THEN 'S5'
        ELSE 'S6' END AS Semestre
    FROM stats.master_plop
    GROUP BY company_id, semestre;

CREATE TABLE stats.proveedor_region_semestre_monto AS
    (SELECT *
     FROM temp2
     WHERE semestre = 'S1'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp2
     WHERE semestre = 'S2'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp2
     WHERE semestre = 'S3'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp2
     WHERE semestre = 'S4'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp2
     WHERE semestre = 'S5'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp2
     WHERE semestre = 'S6'
     ORDER BY monto DESC
     LIMIT 5);

-- query 4

-- MONTOS POR LICITACION

CREATE TABLE stats.licitacion_monto AS
    SELECT
        licitacion_codigo,
        sum(monto) AS monto
    FROM stats.master_plop
    GROUP BY licitacion_codigo
    ORDER BY monto DESC
    LIMIT 5;

-- query 4 desagregada

-- MONTOS POR LICITACION, REGION, SEMESTRE

DROP TABLE IF EXISTS temp4;

CREATE TEMP TABLE temp4 AS
    SELECT
        licitacion_codigo,
        sum(monto)    AS monto,
        CASE WHEN mes <= '6' AND ano = '2013'
            THEN 'S1'
        WHEN mes > '6' AND ano = '2013'
            THEN 'S2'
        WHEN mes <= '6' AND ano = '2014'
            THEN 'S3'
        WHEN mes > '6' AND ano = '2014'
            THEN 'S4'
        WHEN mes <= '6' AND ano = '2015'
            THEN 'S5'
        ELSE 'S6' END AS Semestre,
        region
    FROM stats.master_plop
    GROUP BY licitacion_codigo, semestre, region;

CREATE TABLE stats.licitacion_region_semestre_monto AS

    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S1' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S2' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S3' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S4' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S5' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp4
     WHERE semestre = 'S6' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5);

-- query 5

-- MONTO POR CATEGORIA DE PRODUCTO

CREATE TABLE stats.categoria_monto AS
    SELECT
        categoria_tercer_nivel,
        sum(monto) AS monto
    FROM stats.master_plop
    GROUP BY categoria_tercer_nivel
    ORDER BY monto DESC
    LIMIT 5;

-- query 5 desagregada

-- MONTO POR CATEGPRIA DE PRODUCTO, REGION, SEMESTRE

DROP TABLE IF EXISTS temp5;

CREATE TEMP TABLE temp5 AS
    SELECT
        categoria_tercer_nivel AS categoria,
        sum(monto)             AS monto,
        CASE WHEN mes <= '6' AND ano = '2013'
            THEN 'S1'
        WHEN mes > '6' AND ano = '2013'
            THEN 'S2'
        WHEN mes <= '6' AND ano = '2014'
            THEN 'S3'
        WHEN mes > '6' AND ano = '2014'
            THEN 'S4'
        WHEN mes <= '6' AND ano = '2015'
            THEN 'S5'
        ELSE 'S6' END          AS Semestre,
        region                 AS region
    FROM stats.master_plop
    GROUP BY categoria, semestre, region;

CREATE TABLE stats.categoria_region_semestre_monto AS
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región de Atacama '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región de Antofagasta '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región de Coquimbo '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región del Biobío '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región de los Lagos '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región de Tarapacá  '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región de Magallanes y de la Antártica'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región Metropolitana de Santiago'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región Aysén del General Carlos Ibáñez del Campo'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región de Los Ríos'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región de la Araucanía '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región de Arica y Parinacota'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región del Maule '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región del Libertador General Bernardo O´Higgins'
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S1' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S2' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S3' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S4' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S5' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5)
    UNION ALL
    (SELECT *
     FROM temp5
     WHERE semestre = 'S6' AND region = 'Región de Valparaíso '
     ORDER BY monto DESC
     LIMIT 5);

-- SUMARIO

CREATE TABLE stats.sumario
(
    monto_transado BIGINT NOT NULL,
    n_licitaciones BIGINT NOT NULL,
    n_organismos   BIGINT NOT NULL,
    n_proveedores  BIGINT NOT NULL
);

INSERT INTO stats.sumario (monto_transado, n_licitaciones, n_organismos, n_proveedores)
    SELECT
        (SELECT SUM(A.monto)
         FROM
             (SELECT monto
              FROM stats.master_plop) A) AS monto_transado,
        (SELECT COUNT(B)
         FROM
             (SELECT DISTINCT id
              FROM bkn.licitacion) B)    AS n_licitaciones,
        (SELECT COUNT(C)
         FROM
             (SELECT DISTINCT id
              FROM _catalogo_organismo) C)        AS n_organismo,
        COUNT(*)
    FROM
        (SELECT DISTINCT id
         FROM bkn.proveedor) n_proveedores;
