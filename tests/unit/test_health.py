"""Unit tests for health check functionality."""

from unittest.mock import AsyncMock, patch

import pytest


class TestCheckDbHealth:
    """Tests for the check_db_health function."""

    @pytest.mark.asyncio
    async def test_healthy_database(self) -> None:
        """Test that a healthy database returns success."""
        from contextlib import asynccontextmanager

        mock_session = AsyncMock()
        mock_session.execute = AsyncMock()

        @asynccontextmanager
        async def mock_session_ctx():
            yield mock_session

        def mock_factory():
            return mock_session_ctx()

        with patch("backend.src.db.config.get_session_factory", return_value=mock_factory):
            from backend.src.db.config import check_db_health

            result = await check_db_health(timeout=2.0)

            assert result["healthy"] is True
            assert "latency_ms" in result
            assert isinstance(result["latency_ms"], float)

    @pytest.mark.asyncio
    async def test_database_connection_error(self) -> None:
        """Test that database connection errors are caught."""
        from contextlib import asynccontextmanager

        @asynccontextmanager
        async def mock_session_ctx():
            raise Exception("Connection refused")
            yield  # noqa: B901 - unreachable but required for generator

        def mock_factory():
            return mock_session_ctx()

        with patch("backend.src.db.config.get_session_factory", return_value=mock_factory):
            from backend.src.db.config import check_db_health

            result = await check_db_health(timeout=2.0)

            assert result["healthy"] is False
            assert "error" in result
            assert "Connection refused" in result["error"]

    @pytest.mark.asyncio
    async def test_database_timeout(self) -> None:
        """Test that database timeout is handled correctly."""
        import asyncio
        from contextlib import asynccontextmanager

        async def slow_execute(*args, **kwargs):
            await asyncio.sleep(5)

        mock_session = AsyncMock()
        mock_session.execute = slow_execute

        @asynccontextmanager
        async def mock_session_ctx():
            yield mock_session

        def mock_factory():
            return mock_session_ctx()

        with patch("backend.src.db.config.get_session_factory", return_value=mock_factory):
            from backend.src.db.config import check_db_health

            result = await check_db_health(timeout=0.1)

            assert result["healthy"] is False
            assert "error" in result
            assert "timed out" in result["error"]


class TestHealthEndpoints:
    """Tests for health check HTTP endpoints."""

    @pytest.mark.asyncio
    async def test_liveness_endpoint(self, test_client) -> None:
        """Test the /health liveness endpoint."""
        response = await test_client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    @pytest.mark.asyncio
    async def test_live_endpoint(self, test_client) -> None:
        """Test the /health/live endpoint."""
        response = await test_client.get("/health/live")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    @pytest.mark.asyncio
    async def test_readiness_endpoint_healthy(self, test_client) -> None:
        """Test the /health/ready endpoint when database is healthy."""
        with patch(
            "backend.src.app.check_db_health",
            return_value={"healthy": True, "latency_ms": 5.0},
        ):
            response = await test_client.get("/health/ready")

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "ready"
            assert "checks" in data
            assert data["checks"]["database"]["healthy"] is True

    @pytest.mark.asyncio
    async def test_readiness_endpoint_unhealthy(self, test_client) -> None:
        """Test the /health/ready endpoint when database is unhealthy."""
        with patch(
            "backend.src.app.check_db_health",
            return_value={"healthy": False, "error": "Connection refused"},
        ):
            response = await test_client.get("/health/ready")

            assert response.status_code == 503
            data = response.json()
            assert data["status"] == "not_ready"
            assert data["checks"]["database"]["healthy"] is False
