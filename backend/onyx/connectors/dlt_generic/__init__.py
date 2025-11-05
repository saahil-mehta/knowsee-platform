"""DLT (Data Load Tool) Generic Connector for Onyx."""

from onyx.connectors.dlt_generic.connector import DltGenericConnector
from onyx.connectors.dlt_generic.connector import FacebookAdsConnector
from onyx.connectors.dlt_generic.connector import GoogleAdsConnector

__all__ = [
    "DltGenericConnector",
    "GoogleAdsConnector",
    "FacebookAdsConnector",
]
