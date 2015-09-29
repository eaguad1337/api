import json

import falcon

from peewee import fn, SQL
from playhouse.shortcuts import model_to_dict

from models import models as models_old
from models.models_bkn import *
from models import models_stats
from utils.myjson import JSONEncoderPlus


class OrganismoItem(object):

    ALLOWED_FILTERS = ['producto']

    @database.atomic()
    def on_get(self, req, resp, organismo_id=None):

        # Get the organismo
        try:
            organismo = Comprador.get(Comprador.id == organismo_id)
            # organismo = models_old.JerarquiaDistinct.select(
            #     models_old.JerarquiaDistinct.id,
            #     models_old.JerarquiaDistinct.codigo_organismo.alias('codigo'),
            #     models_old.JerarquiaDistinct.nombre_categoria.alias('categoria'),
            #     models_old.JerarquiaDistinct.nombre_organismo.alias('nombre')
            # ).where(
            #     models_old.JerarquiaDistinct.id == organismo_id
            # )

        except Comprador.DoesNotExist:
            raise falcon.HTTPNotFound()

        response = model_to_dict(organismo, backrefs=False)

        codigo_producto = req.params.get('producto', None)
        if codigo_producto and codigo_producto.isdigit():
            codigo_producto = int(codigo_producto)

        # Top licitaciones adjudicadas
        top_licitaciones = models_stats.LicitacionItemAdjudicadas.select(
            models_stats.LicitacionItemAdjudicadas.licitacion.alias('id'),
            Licitacion.nombre,
            Licitacion.codigo,
            fn.sum(models_stats.LicitacionItemAdjudicadas.monto).alias('monto')
        ).where(
            models_stats.LicitacionItemAdjudicadas.jerarquia_distinct == organismo.id
        ).join(
            Licitacion,
            on=(models_stats.LicitacionItemAdjudicadas.licitacion == Licitacion.id)
        ).group_by(
            models_stats.LicitacionItemAdjudicadas.licitacion,
            Licitacion.nombre,
            Licitacion.codigo
        ).order_by(
            SQL('monto').desc()
        ).limit(10)

        # Top proveedores
        top_proveedores = models_stats.LicitacionItemAdjudicadas.select(
            models_stats.LicitacionItemAdjudicadas.proveedor.alias('id'),
            models_stats.LicitacionItemAdjudicadas.nombre_proveedor.alias('nombre'),
            models_stats.LicitacionItemAdjudicadas.rut_proveedor.alias('rut'),
            fn.sum(models_stats.LicitacionItemAdjudicadas.monto).alias('monto')
        ).where(
            models_stats.LicitacionItemAdjudicadas.jerarquia_distinct == organismo.id
        ).group_by(
            models_stats.LicitacionItemAdjudicadas.proveedor,
            models_stats.LicitacionItemAdjudicadas.nombre_proveedor,
            models_stats.LicitacionItemAdjudicadas.rut_proveedor
        ).order_by(
            SQL('monto').desc()
        ).limit(10)

        # Latest licitaciones
        estados_recientes = LicitacionEstado.select(
            LicitacionEstado.licitacion,
            fn.max(LicitacionEstado.fecha)
        ).group_by(
            LicitacionEstado.licitacion
        ).alias('estados_recientes')

        estados = LicitacionEstado.select(
            LicitacionEstado.licitacion,
            LicitacionEstado.estado,
            LicitacionEstado.fecha
        ).join(
            estados_recientes,
            on=(LicitacionEstado.licitacion == estados_recientes.c.licitacion_id)
        ).alias('estados')

        licitaciones = Licitacion.select(
            Licitacion.id,
            Licitacion.nombre,
            Licitacion.codigo,
            Licitacion.fecha_creacion,
            estados.c.estado,
        ).join(
            Comprador
        ).where(
            Comprador.jerarquia_id == organismo.id
        ).join(
            estados,
            on=(Licitacion.id == estados.c.licitacion_id)
        ).order_by(
            Licitacion.fecha_creacion.desc()
        ).limit(10)

        # licitacion_items_producto = models_stats.LicitacionItemAdjudicadas.select(
        #     models_stats.LicitacionItemAdjudicadas.licitacion,
        #     fn.sum(models_stats.LicitacionItemAdjudicadas.monto).alias('monto')
        # ).where(
        #     models_stats.LicitacionItemAdjudicadas.jerarquia_distinct == organismo.jerarquia_id,
        #     (models_stats.LicitacionItemAdjudicadas.codigo_producto == codigo_producto) if codigo_producto else SQL('1 = 1')
        # ).group_by(
        #     models_stats.LicitacionItemAdjudicadas.licitacion
        # )

        response['extra'] = {
            'top_licitaciones': [licitacion for licitacion in top_licitaciones.dicts()],
            'top_proveedores': [proveedor for proveedor in top_proveedores.dicts()],
            'licitaciones': [licitacion for licitacion in licitaciones.dicts()],

            # 'cantidad_licitaciones': licitacion_items_producto.count(),
            # 'cantidad_licitaciones_adjudicadas': 123,
            # 'monto_total': 123,
            # 'monto_promedio': 123,
            # 'cantidad_proveedores': 123
        }

        resp.body = json.dumps(response, cls=JSONEncoderPlus)
