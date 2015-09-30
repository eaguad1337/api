import json

import falcon

from playhouse.shortcuts import model_to_dict

from models.models_bkn import *
from utils.myjson import JSONEncoderPlus
from utils.mypeewee import ts_match, ts_rank


class LicitacionItem(object):

    @database.atomic()
    def on_get(self, req, resp, licitacion_id=None):

        # Get the licitacion
        try:
            if '-' in licitacion_id:
                licitacion = Licitacion.get(Licitacion.codigo == licitacion_id)
            elif licitacion_id.isdigit():
                licitacion = Licitacion.get(Licitacion.id == licitacion_id)
            else:
                raise Licitacion.DoesNotExist()

        except Licitacion.DoesNotExist:
            raise falcon.HTTPNotFound()

        response = json.dumps(model_to_dict(licitacion, backrefs=True), cls=JSONEncoderPlus)

        callback = req.params.get('callback', None)
        if callback:
            response = "%s(%s)" % (callback, response)

        resp.body = response


class LicitacionList(object):

    ALLOWED_PARAMS = ['q']
    MAX_RESULTS = 10

    @database.atomic()
    def on_get(self, req, resp):

        # Get all licitaciones
        licitaciones = Licitacion.select().order_by(Licitacion.fecha_creacion.desc())

        # Get page
        q_page = req.params.get('pagina', '1')
        q_page = max(int(q_page) if q_page.isdigit() else 1, 1)

        q_q = req.params.get('q', None)
        if q_q:
            # TODO Try to make just one query over one index instead of two or more ORed queries
            licitaciones = licitaciones.where(ts_match(Licitacion.nombre, q_q) | ts_match(Licitacion.descripcion, q_q))

        response = {
            'n_licitaciones': licitaciones.count(),
            'licitaciones': [licitacion for licitacion in licitaciones.paginate(q_page, LicitacionList.MAX_RESULTS).dicts()]
        }

        resp.body = json.dumps(response, cls=JSONEncoderPlus, sort_keys=True)
