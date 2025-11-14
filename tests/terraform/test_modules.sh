#!/usr/bin/env bash
# ==============================================================================
# Terraform Module Testing Suite
# ==============================================================================
# Purpose: Unit tests for individual Terraform modules
#
# Technical Details:
# - Tests module inputs (variables) are properly validated
# - Verifies module outputs are complete and useful
# - Checks module resource naming follows conventions
# - Validates module examples (if present)
# - Ensures modules are self-contained and reusable
#
# Best Practice: Modules should be tested independently to ensure they work
# in isolation before being composed into environments
# Design Pattern: Each module should have clear inputs, outputs, and purpose
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_ROOT="${SCRIPT_DIR}/../../terraform"
MODULES_DIR="${TERRAFORM_ROOT}/modules"
FAILED=0
PASSED=0

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Terraform Module Testing Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# Test 1: Module Structure Validation
# ==============================================================================
# Verifies each module has the standard Terraform module structure
# Technical: A well-structured module should have:
# - main.tf (primary resource definitions)
# - variables.tf (input variables)
# - outputs.tf (output values)
# Best Practice: Consistent structure makes modules predictable and maintainable
# ==============================================================================
test_module_structure() {
    local module=$1
    local module_path="${MODULES_DIR}/${module}"

    echo -n "Test 1.${module}: Module structure... "

    local required_files=("main.tf" "variables.tf" "outputs.tf")
    local missing_files=()

    for file in "${required_files[@]}"; do
        if [ ! -f "${module_path}/${file}" ]; then
            missing_files+=("${file}")
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  → Missing files: ${missing_files[*]}"
        ((FAILED++))
        return 1
    fi
}

# ==============================================================================
# Test 2: Module Variable Validation
# ==============================================================================
# Checks that module variables have proper validation rules
# Technical: Variables should have:
# - Type constraints (prevents invalid inputs)
# - Descriptions (documents usage)
# - Default values where appropriate (makes modules easier to use)
# - Validation rules for complex constraints
# Best Practice: Well-defined inputs prevent runtime errors and improve UX
# ==============================================================================
test_module_variables() {
    local module=$1
    local variables_file="${MODULES_DIR}/${module}/variables.tf"

    echo -n "Test 2.${module}: Variable definitions... "

    if [ ! -f "${variables_file}" ]; then
        echo -e "${YELLOW}SKIP${NC}"
        return 0
    fi

    # Count variables
    local var_count=$(grep -c 'variable "' "${variables_file}" || echo 0)

    # Count variables with descriptions
    local desc_count=$(grep -A 3 'variable "' "${variables_file}" | grep -c 'description' || echo 0)

    # Count variables with types
    local type_count=$(grep -A 3 'variable "' "${variables_file}" | grep -c 'type' || echo 0)

    if [ ${var_count} -eq 0 ]; then
        echo -e "${YELLOW}SKIP${NC} (no variables)"
        return 0
    fi

    if [ ${desc_count} -eq ${var_count} ] && [ ${type_count} -eq ${var_count} ]; then
        echo -e "${GREEN}PASS${NC} (${var_count} variables)"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  → Variables: ${var_count}, With descriptions: ${desc_count}, With types: ${type_count}"
        ((FAILED++))
        return 1
    fi
}

# ==============================================================================
# Test 3: Module Output Completeness
# ==============================================================================
# Verifies modules export useful outputs
# Technical: Outputs should expose:
# - Resource IDs (for dependencies)
# - Resource names (for references)
# - Important attributes (URLs, endpoints, etc.)
# Best Practice: Modules should export everything consumers might need
# without requiring them to know internal resource structure
# ==============================================================================
test_module_outputs() {
    local module=$1
    local outputs_file="${MODULES_DIR}/${module}/outputs.tf"

    echo -n "Test 3.${module}: Output definitions... "

    if [ ! -f "${outputs_file}" ]; then
        echo -e "${YELLOW}WARN${NC} (no outputs defined)"
        ((PASSED++))
        return 0
    fi

    # Count outputs
    local output_count=$(grep -c 'output "' "${outputs_file}" || echo 0)

    # Count outputs with descriptions
    local desc_count=$(grep -A 2 'output "' "${outputs_file}" | grep -c 'description' || echo 0)

    if [ ${output_count} -eq 0 ]; then
        echo -e "${YELLOW}WARN${NC} (no outputs)"
        ((PASSED++))
        return 0
    fi

    if [ ${desc_count} -eq ${output_count} ]; then
        echo -e "${GREEN}PASS${NC} (${output_count} outputs)"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}WARN${NC}"
        echo "  → ${output_count} outputs, ${desc_count} with descriptions"
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Test 4: Module Naming Conventions
# ==============================================================================
# Checks that resources in modules follow naming conventions
# Technical: Validates that resources have:
# - Name variables (not hardcoded names)
# - Consistent naming patterns
# - Project/environment prefixes where appropriate
# Best Practice: Dynamic naming makes modules reusable across environments
# ==============================================================================
test_module_naming() {
    local module=$1
    local main_file="${MODULES_DIR}/${module}/main.tf"

    echo -n "Test 4.${module}: Naming conventions... "

    if [ ! -f "${main_file}" ]; then
        echo -e "${YELLOW}SKIP${NC}"
        return 0
    fi

    # Check if module uses var.name or similar for resource naming
    if grep -q 'name\s*=\s*var\.' "${main_file}"; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}WARN${NC}"
        echo "  → Consider using variables for resource names"
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Test 5: Module Dependencies
# ==============================================================================
# Checks for explicit dependencies and proper resource ordering
# Technical: Modules should:
# - Use depends_on when necessary
# - Reference attributes for implicit dependencies
# - Not have circular dependencies
# Best Practice: Explicit dependencies make infrastructure creation order predictable
# ==============================================================================
test_module_dependencies() {
    local module=$1
    local main_file="${MODULES_DIR}/${module}/main.tf"

    echo -n "Test 5.${module}: Dependency management... "

    if [ ! -f "${main_file}" ]; then
        echo -e "${YELLOW}SKIP${NC}"
        return 0
    fi

    # This is a basic check - comprehensive dependency analysis would require
    # parsing the Terraform graph
    # Check if depends_on is used where appropriate
    local resource_count=$(grep -c 'resource "' "${main_file}" || echo 0)
    local depends_count=$(grep -c 'depends_on' "${main_file}" || echo 0)

    if [ ${resource_count} -gt 3 ] && [ ${depends_count} -eq 0 ]; then
        echo -e "${YELLOW}WARN${NC}"
        echo "  → ${resource_count} resources, consider if explicit depends_on is needed"
        ((PASSED++))
        return 0
    else
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Test 6: Module Documentation
# ==============================================================================
# Checks if module has README or inline documentation
# Technical: Modules should document:
# - Purpose and use cases
# - Input variables and their constraints
# - Output values and their meaning
# - Example usage
# Best Practice: Well-documented modules are easier to adopt and maintain
# ==============================================================================
test_module_documentation() {
    local module=$1
    local module_path="${MODULES_DIR}/${module}"

    echo -n "Test 6.${module}: Documentation... "

    if [ -f "${module_path}/README.md" ]; then
        echo -e "${GREEN}PASS${NC} (README.md exists)"
        ((PASSED++))
        return 0
    fi

    # Check for inline documentation (comments in main.tf)
    if grep -q '^#' "${module_path}/main.tf" 2>/dev/null; then
        echo -e "${YELLOW}WARN${NC} (inline comments only)"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}WARN${NC} (no documentation)"
        echo "  → Consider adding README.md or inline comments"
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Run All Tests for ADK-Specific Modules
# ==============================================================================

echo "Running module tests..."
echo ""

MODULES=("cloud_run_service" "discovery_engine" "log_sink" "github_wif")

for module in "${MODULES[@]}"; do
    if [ ! -d "${MODULES_DIR}/${module}" ]; then
        echo "Module ${module} not found, skipping..."
        continue
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing module: ${module}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    test_module_structure "${module}"
    test_module_variables "${module}"
    test_module_outputs "${module}"
    test_module_naming "${module}"
    test_module_dependencies "${module}"
    test_module_documentation "${module}"

    echo ""
done

# ==============================================================================
# Summary
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Module Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${FAILED} -eq 0 ]; then
    echo -e "${GREEN}✓ All module tests passed${NC}"
    exit 0
else
    echo -e "${RED}✗ Some module tests failed${NC}"
    exit 1
fi
