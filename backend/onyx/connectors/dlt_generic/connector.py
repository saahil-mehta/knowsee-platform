"""
DLT (Data Load Tool) Generic Connector

This connector wraps dlthub sources to easily add marketing data sources
like Google Ads, Facebook Ads, HubSpot, etc.

Example usage:
    connector = DltGenericConnector(
        source_name="google_ads",
        credentials={"developer_token": "...", "customer_id": "..."}
    )
"""

import json
from typing import Any

try:
    import dlt
    from dlt.sources import DltSource
    DLT_AVAILABLE = True
except ImportError:
    DLT_AVAILABLE = False

from onyx.configs.app_configs import INDEX_BATCH_SIZE
from onyx.configs.constants import DocumentSource
from onyx.connectors.interfaces import GenerateDocumentsOutput
from onyx.connectors.interfaces import LoadConnector
from onyx.connectors.interfaces import PollConnector
from onyx.connectors.interfaces import SecondsSinceUnixEpoch
from onyx.connectors.models import ConnectorMissingCredentialError
from onyx.connectors.models import Document
from onyx.connectors.models import Section
from onyx.utils.logger import setup_logger

logger = setup_logger()


class DltGenericConnector(LoadConnector, PollConnector):
    """
    Generic connector that wraps any dlthub source.

    This allows you to quickly add connectors for:
    - Google Ads
    - Facebook Ads
    - Google Analytics
    - Stripe
    - HubSpot
    - Zendesk
    - And 100+ other sources

    See: https://dlthub.com/docs/dlt-ecosystem/verified-sources
    """

    def __init__(
        self,
        source_name: str,
        resource_name: str | None = None,
        batch_size: int = INDEX_BATCH_SIZE,
        **source_config: Any,
    ) -> None:
        """
        Initialize the DLT connector.

        Args:
            source_name: Name of the DLT source (e.g., "google_ads", "facebook_ads")
            resource_name: Specific resource to load (e.g., "campaigns", "ad_groups")
                          If None, loads all resources from the source
            batch_size: Number of documents to yield at once
            **source_config: Additional configuration passed to the DLT source
        """
        if not DLT_AVAILABLE:
            raise ImportError(
                "dlt is not installed. Install it with: pip install dlt"
            )

        self.source_name = source_name
        self.resource_name = resource_name
        self.batch_size = batch_size
        self.source_config = source_config
        self.credentials: dict[str, Any] | None = None

    def load_credentials(self, credentials: dict[str, Any]) -> dict[str, Any] | None:
        """Load and validate credentials."""
        self.credentials = credentials
        return None

    def _create_dlt_source(self) -> DltSource:
        """Create a DLT source instance with credentials."""
        if not self.credentials:
            raise ConnectorMissingCredentialError("DLT Generic")

        try:
            # Create DLT source with credentials
            source = dlt.source(
                self.source_name,
                credentials=self.credentials,
                **self.source_config,
            )
            return source
        except Exception as e:
            logger.error(f"Failed to create DLT source '{self.source_name}': {e}")
            raise

    def _record_to_document(self, record: dict[str, Any], source_type: str) -> Document:
        """
        Convert a DLT record to an Onyx Document.

        Override this method in subclasses for source-specific formatting.
        """
        # Try to extract common fields
        doc_id = str(record.get("id") or record.get("_id") or hash(json.dumps(record, sort_keys=True)))
        title = (
            record.get("name")
            or record.get("title")
            or record.get("subject")
            or f"{source_type} Record {doc_id}"
        )

        # Convert record to readable text
        text_parts = []
        for key, value in record.items():
            if not key.startswith("_") and value is not None:
                text_parts.append(f"{key}: {value}")

        text_content = "\n".join(text_parts)

        # Extract link if available
        link = (
            record.get("url")
            or record.get("link")
            or record.get("web_url")
        )

        return Document(
            id=doc_id,
            sections=[Section(link=link, text=text_content)],
            source=DocumentSource.INGESTION_API,  # Or create specific source
            semantic_identifier=title,
            doc_updated_at=record.get("updated_at") or record.get("modified_date"),
            metadata={
                "source_name": self.source_name,
                "resource_name": self.resource_name or "default",
                **{k: v for k, v in record.items() if isinstance(v, (str, int, float, bool))},
            },
        )

    def load_from_state(self) -> GenerateDocumentsOutput:
        """Full load of all data from the DLT source."""
        logger.info(f"Starting full load from DLT source: {self.source_name}")

        source = self._create_dlt_source()

        # Determine which resources to load
        if self.resource_name:
            # Load specific resource
            if self.resource_name not in source.resources:
                raise ValueError(
                    f"Resource '{self.resource_name}' not found in source '{self.source_name}'. "
                    f"Available: {list(source.resources.keys())}"
                )
            resources = {self.resource_name: source.resources[self.resource_name]}
        else:
            # Load all resources
            resources = source.resources

        # Process each resource
        for resource_name, resource in resources.items():
            logger.info(f"Loading resource: {resource_name}")

            doc_batch = []
            record_count = 0

            try:
                # Iterate through records from DLT
                for record in resource:
                    try:
                        doc = self._record_to_document(record, resource_name)
                        doc_batch.append(doc)
                        record_count += 1

                        # Yield batch when full
                        if len(doc_batch) >= self.batch_size:
                            logger.debug(f"Yielding batch of {len(doc_batch)} documents")
                            yield doc_batch
                            doc_batch = []

                    except Exception as e:
                        logger.error(f"Failed to convert record to document: {e}")
                        logger.debug(f"Problematic record: {record}")
                        continue

                # Yield remaining documents
                if doc_batch:
                    logger.debug(f"Yielding final batch of {len(doc_batch)} documents")
                    yield doc_batch

                logger.info(
                    f"Completed loading {record_count} records from resource '{resource_name}'"
                )

            except Exception as e:
                logger.error(f"Error loading resource '{resource_name}': {e}")
                raise

    def poll_source(
        self, start: SecondsSinceUnixEpoch, end: SecondsSinceUnixEpoch
    ) -> GenerateDocumentsOutput:
        """
        Incremental load of data modified between start and end times.

        Note: DLT handles incremental loading automatically if the source supports it.
        For sources without native incremental support, this falls back to full load.
        """
        logger.info(
            f"Starting incremental load from DLT source: {self.source_name} "
            f"(time range: {start} to {end})"
        )

        # For now, just do a full load
        # DLT's incremental loading would be configured at the source level
        # via state management
        yield from self.load_from_state()


class GoogleAdsConnector(DltGenericConnector):
    """
    Specialized connector for Google Ads.

    Example credentials:
    {
        "developer_token": "your-developer-token",
        "client_id": "your-client-id",
        "client_secret": "your-client-secret",
        "refresh_token": "your-refresh-token",
        "customer_id": "1234567890",
    }
    """

    def __init__(
        self,
        customer_id: str,
        resource_name: str | None = None,
        batch_size: int = INDEX_BATCH_SIZE,
    ) -> None:
        super().__init__(
            source_name="google_ads",
            resource_name=resource_name,
            batch_size=batch_size,
            customer_id=customer_id,
        )

    def _record_to_document(self, record: dict[str, Any], source_type: str) -> Document:
        """Custom formatting for Google Ads records."""
        # Extract campaign/ad group/ad specific fields
        doc_id = str(record.get("id") or record.get("resource_name"))
        title = record.get("name", f"Google Ads {source_type} {doc_id}")

        # Format metrics nicely
        text_parts = [f"**{title}**\n"]

        # Add status
        if "status" in record:
            text_parts.append(f"Status: {record['status']}")

        # Add metrics
        metrics = record.get("metrics", {})
        if metrics:
            text_parts.append("\nMetrics:")
            for metric_name, value in metrics.items():
                text_parts.append(f"  - {metric_name}: {value}")

        text_content = "\n".join(text_parts)

        return Document(
            id=doc_id,
            sections=[Section(link=None, text=text_content)],
            source=DocumentSource.INGESTION_API,
            semantic_identifier=title,
            metadata={
                "source": "google_ads",
                "resource_type": source_type,
                "customer_id": self.source_config.get("customer_id"),
                **{k: v for k, v in record.items() if isinstance(v, (str, int, float, bool))},
            },
        )


class FacebookAdsConnector(DltGenericConnector):
    """
    Specialized connector for Facebook Ads.

    Example credentials:
    {
        "access_token": "your-access-token",
        "account_id": "act_1234567890",
    }
    """

    def __init__(
        self,
        account_id: str,
        resource_name: str | None = None,
        batch_size: int = INDEX_BATCH_SIZE,
    ) -> None:
        super().__init__(
            source_name="facebook_ads",
            resource_name=resource_name,
            batch_size=batch_size,
            account_id=account_id,
        )
