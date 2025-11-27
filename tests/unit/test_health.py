"""Unit tests for health check functionality."""

from unittest.mock import AsyncMock, patch

import pytest


class TestCheckDbHealth:
    """Tests for the check_db_health function."""

    @pytest.mark.asyncio
    async def test_healthy_database(self) -> None:
        """Test that a healthy database returns success."""
        mock_session = AsyncMock()
        mock_session.execute = AsyncMock()

        with patch(
            "backend.src.db.config.async_session_factory"
        ) as mock_factory:
            mock_factory.return_value.__aenter__.return_value = mock_session
            mock_factory.return_value.__aexit__.return_value = None

            from backend.src.db.config import check_db_health

            result = await check_db_health(timeout=2.0)

            assert result["healthy"] is True
            assert "latency_ms" in result
            assert isinstance(result["latency_ms"], float)

    @pytest.mark.asyncio
    async def test_database_connection_error(self) -> None:
        """Test that database connection errors are caught."""
        with patch(
            "backend.src.db.config.async_session_factory"
        ) as mock_factory:
            mock_factory.return_value.__aenter__.side_effect = Exception(
                "Connection refused"
            )

            from backend.src.db.config import check_db_health

            result = await check_db_health(timeout=2.0)

            assert result["healthy"] is False
            assert "error" in result
            assert "Connection refused" in result["error"]

    @pytest.mark.asyncio
    async def test_database_timeout(self) -> None:
        """Test that database timeout is handled correctly."""
        import asyncio

        async def slow_execute(*args, **kwargs):
            await asyncio.sleep(5)

        mock_session = AsyncMock()
        mock_session.execute = slow_execute

        with patch(
            "backend.src.db.config.async_session_factory"
        ) as mock_factory:
            mock_factory.return_value.__aenter__.return_value = mock_session
            mock_factory.return_value.__aexit__.return_value = None

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
