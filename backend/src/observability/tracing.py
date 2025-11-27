"""OpenTelemetry tracing configuration for Knowsee Platform.

Provides distributed tracing for requests across services.
"""

import os
from typing import Any

from fastapi import FastAPI

# Check if tracing is enabled
OTEL_ENABLED = os.getenv("OTEL_ENABLED", "false").lower() == "true"
OTEL_SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "knowsee-backend")
OTEL_EXPORTER_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4317")


def setup_tracing(app: FastAPI) -> None:
    """Set up OpenTelemetry tracing for the FastAPI application.

    Args:
        app: The FastAPI application instance.
    """
    if not OTEL_ENABLED:
        return

    from opentelemetry import trace
    from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
    from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
    from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
    from opentelemetry.sdk.resources import Resource
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor

    # Create resource with service info
    resource = Resource.create(
        {
            "service.name": OTEL_SERVICE_NAME,
            "service.version": os.getenv("APP_VERSION", "unknown"),
            "deployment.environment": os.getenv("ENVIRONMENT", "development"),
        }
    )

    # Set up tracer provider
    tracer_provider = TracerProvider(resource=resource)

    # Set up OTLP exporter
    otlp_exporter = OTLPSpanExporter(
        endpoint=OTEL_EXPORTER_ENDPOINT,
        insecure=True,  # Set to False in production with TLS
    )

    # Add span processor
    tracer_provider.add_span_processor(BatchSpanProcessor(otlp_exporter))

    # Set as global tracer provider
    trace.set_tracer_provider(tracer_provider)

    # Instrument FastAPI
    FastAPIInstrumentor.instrument_app(
        app,
        excluded_urls="health,health/ready,health/live,metrics",
    )

    # Instrument SQLAlchemy (will need engine to be passed)
    # This is typically done after engine creation
    SQLAlchemyInstrumentor().instrument()


def get_tracer(name: str = "knowsee") -> Any:
    """Get a tracer instance for manual span creation.

    Args:
        name: Tracer name (typically module name)

    Returns:
        OpenTelemetry tracer instance or no-op tracer if disabled.

    Usage:
        tracer = get_tracer(__name__)

        with tracer.start_as_current_span("my_operation") as span:
            span.set_attribute("key", "value")
            # ... do work ...
    """
    if not OTEL_ENABLED:
        # Return a no-op tracer when tracing is disabled
        from opentelemetry.trace import NoOpTracer

        return NoOpTracer()

    from opentelemetry import trace

    return trace.get_tracer(name)


def instrument_sqlalchemy_engine(engine: Any) -> None:
    """Instrument a SQLAlchemy engine for tracing.

    Args:
        engine: SQLAlchemy engine instance.
    """
    if not OTEL_ENABLED:
        return

    from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor

    SQLAlchemyInstrumentor().instrument(engine=engine.sync_engine)
