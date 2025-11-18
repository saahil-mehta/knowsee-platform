#!/usr/bin/env bash
# ==============================================================================
# Master Test Runner for Knowsee Platform
# ==============================================================================
# Purpose: Runs comprehensive test suite covering all aspects of the platform
#
# Test Categories:
# 1. Terraform validation and security tests
# 2. Terraform module tests
# 3. Python unit tests (backend)
# 4. Python integration tests (agent)
# 5. Backend linting and type checking
#
# Technical: This script orchestrates all test types and provides a single
# entry point for CI/CD pipelines and local development.
#
# Best Practice: Always run full test suite before:
# - Creating pull requests
# - Deploying to any environment
# - Merging to main branch
#
# Exit Codes:
# 0 = All tests passed
# 1 = One or more test suites failed
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Track failures
TOTAL_SUITES=0
FAILED_SUITES=0
PASSED_SUITES=0

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║         Knowsee Platform Comprehensive Test Suite             ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ==============================================================================
# Helper Functions
# ==============================================================================

run_test_suite() {
    local suite_name=$1
    local test_command=$2

    ((TOTAL_SUITES++))

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Running: ${suite_name}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if eval "${test_command}"; then
        echo ""
        echo -e "${GREEN}✓ ${suite_name} PASSED${NC}"
        ((PASSED_SUITES++))
        return 0
    else
        echo ""
        echo -e "${RED}✗ ${suite_name} FAILED${NC}"
        ((FAILED_SUITES++))
        return 1
    fi
}

# ==============================================================================
# Phase 1: Terraform Tests
# ==============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Phase 1: Infrastructure Tests (Terraform)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

run_test_suite \
    "Terraform Validation Tests" \
    "bash ${SCRIPT_DIR}/terraform/test_validate.sh"

run_test_suite \
    "Terraform Security Tests" \
    "bash ${SCRIPT_DIR}/terraform/test_security.sh"

run_test_suite \
    "Terraform Module Tests" \
    "bash ${SCRIPT_DIR}/terraform/test_modules.sh"

# ==============================================================================
# Phase 2: Python Backend Tests
# ==============================================================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Phase 2: Backend Tests (Python/ADK)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Install dependencies if needed
if [ ! -d "${ROOT_DIR}/.venv" ]; then
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    cd "${ROOT_DIR}" && uv sync --dev
fi

run_test_suite \
    "Python Unit Tests" \
    "cd ${ROOT_DIR} && uv run pytest tests/unit -v"

run_test_suite \
    "Python Integration Tests" \
    "cd ${ROOT_DIR} && uv run pytest tests/integration -v"

# ==============================================================================
# Phase 3: Code Quality Checks
# ==============================================================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Phase 3: Code Quality Checks${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

run_test_suite \
    "Code Spelling Check" \
    "cd ${ROOT_DIR} && uv run codespell --skip='.git,.venv,node_modules,*.lock,package-lock.json'"

run_test_suite \
    "Ruff Linting" \
    "cd ${ROOT_DIR} && uv run ruff check . --diff"

run_test_suite \
    "Ruff Formatting Check" \
    "cd ${ROOT_DIR} && uv run ruff format . --check --diff"

run_test_suite \
    "MyPy Type Checking" \
    "cd ${ROOT_DIR} && uv run mypy . --ignore-missing-imports"

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║                     Test Suite Summary                         ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Total Test Suites: ${TOTAL_SUITES}"
echo -e "Passed: ${GREEN}${PASSED_SUITES}${NC}"
echo -e "Failed: ${RED}${FAILED_SUITES}${NC}"
echo ""

if [ ${FAILED_SUITES} -eq 0 ]; then
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo -e "║  ${GREEN}✓✓✓ ALL TESTS PASSED ✓✓✓${NC}                                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}Your code is ready for deployment!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review changes: git diff"
    echo "  2. Commit changes: git commit -m 'description'"
    echo "  3. Push to remote: git push"
    echo "  4. Create pull request or deploy"
    echo ""
    exit 0
else
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo -e "║  ${RED}✗✗✗ SOME TESTS FAILED ✗✗✗${NC}                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${RED}Please fix the failing tests before proceeding.${NC}"
    echo ""
    echo "Tips:"
    echo "  - Review error messages above"
    echo "  - Run individual test suites for faster feedback"
    echo "  - Check test documentation for expected behaviour"
    echo ""
    exit 1
fi
