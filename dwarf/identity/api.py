#!/usr/bin/env python
#
# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
# Copyright (c) 2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import bottle
import json
import logging

from dwarf import api_server
from dwarf import config
from dwarf import exception
from dwarf import utils

CONF = config.Config()
LOG = logging.getLogger(__name__)

TOKEN = {
    "id": "0011223344556677",
    "expires": "2100-01-01T00:00:00-00:00",
    "tenant": {
        "id": "1000",
        "name": "dwarf-tenant"
    }
}

USER = {
    "id": "1000",
    "name": "dwarf-user",
    "roles": []
}

SERVICE_COMPUTE = {
    "name": "Compute",
    "type": "compute",
    "endpoints": [{
        "tenantId": "1000",
        "publicURL": "http://%s:%s/v1.1/1000" % (CONF.bind_host, CONF.compute_api_port),
        "region": "dwarf-region",
        "versionId": "1.1",
        "versionInfo": "http://%s:%s/v1.1" % (CONF.bind_host, CONF.compute_api_port),
        "versionList": "http://%s:%s" % (CONF.bind_host, CONF.compute_api_port)
    }]
}

SERVICE_IMAGE = {
    "name": "Image Management",
    "type": "image",
    "endpoints": [{
        "tenantId": "1000",
        "publicURL": "http://%s:%s/v1" % (CONF.bind_host, CONF.image_api_port),
        "region": "dwarf-region",
        "versionId": "1.0",
        "versionInfo": "http://%s:%s/v1" % (CONF.bind_host, CONF.image_api_port),
        "versionList": "http://%s:%s" % (CONF.bind_host, CONF.image_api_port)
    }]
}

TOKENS_RESPONSE = {
    "access": {
        "token": TOKEN,
        "user": USER,
        "serviceCatalog": [
            SERVICE_COMPUTE,
            SERVICE_IMAGE
        ]
    }
}


@exception.catchall
def _route_tokens():
    """
    Route:  /v2.0/tokens
    Method: POST
    """
    utils.show_request(bottle.request)

    body = json.load(bottle.request.body)
    if 'auth' in body:
        return TOKENS_RESPONSE


class _IdentityApiServer(api_server.ApiServer):
    def __init__(self):
        super(_IdentityApiServer, self).__init__('Identity',
                                                 CONF.bind_host,
                                                 CONF.identity_api_port)

        self.app.route('/v2.0/tokens',
                       method='POST',
                       callback=_route_tokens)


_API_SERVER = None


def IdentityApiServer():
    """
    Factory function to return the already created object
    """
    global _API_SERVER   # pylint: disable=W0603
    if _API_SERVER is None:
        _API_SERVER = _IdentityApiServer()
    return _API_SERVER
