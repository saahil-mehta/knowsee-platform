#!/usr/bin/env bash
# ==============================================================================
# Terraform Validation Test Suite
# ==============================================================================
# Purpose: Validates Terraform configurations across all environments
#
# Technical Details:
# - Tests that all .tf files are syntactically valid
# - Verifies module references are correct
# - Ensures variable types and defaults are properly defined
# - Checks for circular dependencies
# - Validates provider requirements
#
# Best Practice: Run this before any terraform plan/apply to catch
# configuration errors early in the development cycle
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_ROOT="${SCRIPT_DIR}/../../terraform"
ENVIRONMENTS=("cicd" "dev" "staging" "prod")
FAILED=0
PASSED=0

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Terraform Validation Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# Test 1: Terraform Format Check
# ==============================================================================
# Verifies that all Terraform files follow proper formatting conventions
# This ensures code consistency and readability across the team
# Technical: Uses 'terraform fmt -check -recursive' which returns non-zero
# if any files need formatting
# ==============================================================================
test_format() {
    echo -n "Test 1: Terraform Format Check... "

    if terraform fmt -check -recursive "${TERRAFORM_ROOT}" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  → Run 'make fmt' to fix formatting issues"
        ((FAILED++))
        return 1
    fi
}

# ==============================================================================
# Test 2: Environment Validation
# ==============================================================================
# Validates each environment's Terraform configuration independently
# Technical: Runs 'terraform validate' which checks:
# - Variable references are valid
# - Resource attribute references exist
# - Module inputs match module variables
# - Provider configurations are correct
# Best Practice: Each environment should validate independently to ensure
# they can be deployed in isolation
# ==============================================================================
test_environment_validation() {
    local env=$1
    echo -n "Test 2.${env}: Validate ${env} environment... "

    local env_dir="${TERRAFORM_ROOT}/environments/${env}"

    if [ ! -d "${env_dir}" ]; then
        echo -e "${YELLOW}SKIP${NC} (directory not found)"
        return 0
    fi

    # Initialize without backend to avoid state requirements
    if ! terraform -chdir="${env_dir}" init -backend=false >/dev/null 2>&1; then
        echo -e "${RED}FAIL${NC}"
        echo "  → Failed to initialise ${env} environment"
        ((FAILED++))
        return 1
    fi

    # Validate configuration
    if terraform -chdir="${env_dir}" validate >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  → Validation errors in ${env} environment"
        terraform -chdir="${env_dir}" validate
        ((FAILED++))
        return 1
    fi
}

# ==============================================================================
# Test 3: Module Validation
# ==============================================================================
# Validates each Terraform module independently
# Technical: Modules should be self-contained and validate without a parent
# This ensures modules are properly encapsulated and reusable
# Best Practice: Well-designed modules should validate independently
# ==============================================================================
test_module_validation() {
    local module=$1
    echo -n "Test 3.${module}: Validate module/${module}... "

    local module_dir="${TERRAFORM_ROOT}/modules/${module}"

    if [ ! -f "${module_dir}/main.tf" ]; then
        echo -e "${YELLOW}SKIP${NC} (no main.tf found)"
        return 0
    fi

    # Initialize module without backend
    if ! terraform -chdir="${module_dir}" init -backend=false >/dev/null 2>&1; then
        echo -e "${RED}FAIL${NC}"
        echo "  → Failed to initialise ${module} module"
        ((FAILED++))
        return 1
    fi

    # Validate module
    if terraform -chdir="${module_dir}" validate >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  → Validation errors in ${module} module"
        terraform -chdir="${module_dir}" validate
        ((FAILED++))
        return 1
    fi
}

# ==============================================================================
# Test 4: Variable Definition Completeness
# ==============================================================================
# Ensures all variables have descriptions and types
# Technical: Parses variables.tf files and checks for missing metadata
# Best Practice: Every variable should have a description for documentation
# and a type constraint for validation
# ==============================================================================
test_variable_completeness() {
    echo -n "Test 4: Variable definition completeness... "

    local missing_descriptions=0
    local missing_types=0

    while IFS= read -r -d '' file; do
        # Check for variables without descriptions
        if grep -q 'variable "' "${file}" && \
           ! grep -A 3 'variable "' "${file}" | grep -q 'description'; then
            ((missing_descriptions++))
        fi

        # Check for variables without types
        if grep -q 'variable "' "${file}" && \
           ! grep -A 3 'variable "' "${file}" | grep -q 'type'; then
            ((missing_types++))
        fi
    done < <(find "${TERRAFORM_ROOT}" -name "variables.tf" -print0)

    if [ ${missing_descriptions} -eq 0 ] && [ ${missing_types} -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        [ ${missing_descriptions} -gt 0 ] && echo "  → ${missing_descriptions} variables missing descriptions"
        [ ${missing_types} -gt 0 ] && echo "  → ${missing_types} variables missing types"
        ((FAILED++))
        return 1
    fi
}

# ==============================================================================
# Test 5: Output Definition Check
# ==============================================================================
# Verifies all outputs have descriptions
# Technical: Outputs without descriptions are harder to understand and use
# Best Practice: Every output should explain what it provides and why it's useful
# ==============================================================================
test_output_completeness() {
    echo -n "Test 5: Output definition completeness... "

    local missing_descriptions=0

    while IFS= read -r -d '' file; do
        # Check for outputs without descriptions
        if grep -q 'output "' "${file}" && \
           ! grep -A 2 'output "' "${file}" | grep -q 'description'; then
            ((missing_descriptions++))
        fi
    done < <(find "${TERRAFORM_ROOT}" -name "outputs.tf" -print0)

    if [ ${missing_descriptions} -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  → ${missing_descriptions} outputs missing descriptions"
        ((FAILED++))
        return 1
    fi
}

# ==============================================================================
# Test 6: Required Providers Check
# ==============================================================================
# Ensures all environments define required providers with version constraints
# Technical: Version constraints prevent unexpected behaviour from provider updates
# Best Practice: Always pin provider versions to avoid breaking changes
# ==============================================================================
test_required_providers() {
    echo -n "Test 6: Required providers check... "

    local missing_providers=0

    for env in "${ENVIRONMENTS[@]}"; do
        local providers_file="${TERRAFORM_ROOT}/environments/${env}/providers.tf"

        if [ ! -f "${providers_file}" ]; then
            ((missing_providers++))
            continue
        fi

        # Check for required_providers block
        if ! grep -q "required_providers" "${providers_file}"; then
            ((missing_providers++))
        fi
    done

    if [ ${missing_providers} -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  → ${missing_providers} environments missing required_providers"
        ((FAILED++))
        return 1
    fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================

echo "Running validation tests..."
echo ""

# Test 1: Format check
test_format

# Test 2: Environment validation
for env in "${ENVIRONMENTS[@]}"; do
    test_environment_validation "${env}"
done

# Test 3: Module validation
for module in cloud_run_service discovery_engine log_sink github_wif; do
    test_module_validation "${module}"
done

# Test 4: Variable completeness
test_variable_completeness

# Test 5: Output completeness
test_output_completeness

# Test 6: Required providers
test_required_providers

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${FAILED} -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
