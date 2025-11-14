#!/usr/bin/env bash
# ==============================================================================
# Terraform Security & Best Practices Test Suite
# ==============================================================================
# Purpose: Validates Terraform configurations against security and best practice rules
#
# Technical Details:
# - Checks for hardcoded secrets and sensitive data
# - Validates IAM permissions follow least privilege
# - Ensures encryption is enabled where required
# - Verifies deletion protection on critical resources
# - Checks for public access misconfigurations
#
# Best Practice: Security testing should be automated and run on every commit
# to catch vulnerabilities before they reach production
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_ROOT="${SCRIPT_DIR}/../../terraform"
FAILED=0
PASSED=0

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Terraform Security & Best Practices Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# Test 1: No Hardcoded Secrets
# ==============================================================================
# Searches for common patterns that indicate hardcoded sensitive data
# Technical: Uses regex to find API keys, passwords, tokens in .tf files
# Best Practice: Secrets should NEVER be in source code, always use Secret
# Manager, environment variables, or secure parameter stores
# Security Risk: HIGH - Hardcoded secrets can be exposed in version control
# ==============================================================================
test_no_hardcoded_secrets() {
    echo -n "Test 1: No hardcoded secrets... "

    local secret_patterns=(
        'password\s*=\s*"[^$]'
        'api_key\s*=\s*"[^$]'
        'secret\s*=\s*"[^$]'
        'token\s*=\s*"[^$]'
        'private_key\s*=\s*"-----BEGIN'
    )

    local violations=0

    for pattern in "${secret_patterns[@]}"; do
        if grep -rn -E "${pattern}" "${TERRAFORM_ROOT}" --include="*.tf" --include="*.tfvars" 2>/dev/null | \
           grep -v "secret_env_vars" | grep -v "secret_key_ref" | grep -v "description" | grep -q .; then
            ((violations++))
        fi
    done

    if [ ${violations} -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  → Found potential hardcoded secrets"
        echo "  → Use Secret Manager or environment variables instead"
        ((FAILED++))
        return 1
    fi
}

# ==============================================================================
# Test 2: IAM Overly Permissive Roles Check
# ==============================================================================
# Checks for use of overly broad IAM roles like 'roles/owner' or 'roles/editor'
# Technical: Scans for role assignments that grant excessive permissions
# Best Practice: Follow principle of least privilege - grant only required permissions
# Security Risk: MEDIUM - Overly permissive roles increase attack surface
# ==============================================================================
test_iam_least_privilege() {
    echo -n "Test 2: IAM least privilege check... "

    local dangerous_roles=(
        'roles/owner'
        'roles/editor'
        'roles/\*'
    )

    local violations=0

    for role in "${dangerous_roles[@]}"; do
        if grep -rn "role.*=.*\"${role}\"" "${TERRAFORM_ROOT}" --include="*.tf" 2>/dev/null | grep -q .; then
            ((violations++))
        fi
    done

    if [ ${violations} -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}WARN${NC}"
        echo "  → Found potentially overly permissive IAM roles"
        echo "  → Consider using more specific roles"
        # This is a warning, not a failure
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Test 3: Storage Bucket Public Access Check
# ==============================================================================
# Verifies storage buckets don't allow public access unless explicitly intended
# Technical: Checks for bucket IAM bindings with 'allUsers' or 'allAuthenticatedUsers'
# Best Practice: Buckets should be private by default, use signed URLs for sharing
# Security Risk: HIGH - Public buckets can leak sensitive data
# ==============================================================================
test_no_public_buckets() {
    echo -n "Test 3: No public storage buckets... "

    if grep -rn -E '(allUsers|allAuthenticatedUsers)' "${TERRAFORM_ROOT}" --include="*.tf" 2>/dev/null | grep -q .; then
        echo -e "${RED}FAIL${NC}"
        echo "  → Found bucket with public access"
        echo "  → Ensure this is intentional and documented"
        ((FAILED++))
        return 1
    else
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Test 4: Encryption at Rest Check
# ==============================================================================
# Verifies that encryption is enabled for storage and databases
# Technical: Checks for explicit encryption configuration or CMEK usage
# Best Practice: Always encrypt data at rest for compliance and security
# Security Risk: MEDIUM - Unencrypted data can be exposed if physical media is compromised
# ==============================================================================
test_encryption_at_rest() {
    echo -n "Test 4: Encryption at rest check... "

    # This is a simplified check - in production, you'd verify encryption
    # is explicitly enabled for BigQuery, Cloud SQL, GCS, etc.
    # For now, we check if KMS module exists (indicating encryption awareness)

    if [ -d "${TERRAFORM_ROOT}/modules/kms" ] || \
       grep -rn "kms_key_name" "${TERRAFORM_ROOT}" --include="*.tf" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}WARN${NC}"
        echo "  → No explicit KMS encryption configuration found"
        echo "  → Google Cloud uses encryption by default, but consider CMEK for compliance"
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Test 5: Deletion Protection Check
# ==============================================================================
# Ensures critical resources have deletion protection enabled
# Technical: Checks for deletion_protection = true on production resources
# Best Practice: Production databases and critical resources should have
# deletion protection to prevent accidental deletion
# Security Risk: LOW - Prevents operational mistakes rather than security breaches
# ==============================================================================
test_deletion_protection() {
    echo -n "Test 5: Deletion protection check... "

    # Check prod environment has deletion_protection enabled
    local prod_dir="${TERRAFORM_ROOT}/environments/prod"

    if [ ! -d "${prod_dir}" ]; then
        echo -e "${YELLOW}SKIP${NC} (prod environment not found)"
        return 0
    fi

    # Check if deletion_protection is set to true in prod
    if grep -rn "deletion_protection.*=.*true" "${prod_dir}" --include="*.tf" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}WARN${NC}"
        echo "  → Consider enabling deletion_protection for production resources"
        echo "  → This prevents accidental deletion of critical infrastructure"
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Test 6: Terraform State Backend Security
# ==============================================================================
# Verifies Terraform state is stored securely (not local)
# Technical: Checks for GCS backend configuration with encryption
# Best Practice: State files contain sensitive data and should be:
# - Stored remotely (not in version control)
# - Encrypted at rest
# - Access controlled via IAM
# Security Risk: HIGH - State files contain resource IDs, IPs, and sometimes secrets
# ==============================================================================
test_state_backend_security() {
    echo -n "Test 6: Terraform state backend security... "

    local environments_without_backend=0

    for env_dir in "${TERRAFORM_ROOT}"/environments/*/; do
        if [ ! -f "${env_dir}/backend.tf" ]; then
            ((environments_without_backend++))
        fi
    done

    if [ ${environments_without_backend} -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  → ${environments_without_backend} environments missing backend.tf"
        echo "  → All environments must use remote state backend (GCS)"
        ((FAILED++))
        return 1
    fi
}

# ==============================================================================
# Test 7: Network Security - No Default VPC
# ==============================================================================
# Checks if resources are using default VPC (bad practice)
# Technical: Searches for references to 'default' network
# Best Practice: Create custom VPCs with proper firewall rules rather than
# using default VPC which has permissive rules
# Security Risk: MEDIUM - Default VPC has overly permissive firewall rules
# ==============================================================================
test_no_default_vpc() {
    echo -n "Test 7: No default VPC usage... "

    if grep -rn 'network.*=.*"default"' "${TERRAFORM_ROOT}" --include="*.tf" 2>/dev/null | grep -q .; then
        echo -e "${YELLOW}WARN${NC}"
        echo "  → Found usage of default VPC"
        echo "  → Consider using custom VPC with tailored firewall rules"
        ((PASSED++))
        return 0
    else
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Test 8: Service Account Key Management
# ==============================================================================
# Ensures service account keys are not being created (prefer Workload Identity)
# Technical: Checks for google_service_account_key resources
# Best Practice: Use Workload Identity Federation instead of downloadable keys
# - Keys can be leaked or stolen
# - Workload Identity is more secure and doesn't require key rotation
# Security Risk: MEDIUM - Service account keys are long-lived credentials
# ==============================================================================
test_no_service_account_keys() {
    echo -n "Test 8: No service account keys... "

    if grep -rn 'google_service_account_key' "${TERRAFORM_ROOT}" --include="*.tf" 2>/dev/null | grep -q .; then
        echo -e "${YELLOW}WARN${NC}"
        echo "  → Found service account key creation"
        echo "  → Use Workload Identity Federation instead for better security"
        ((PASSED++))
        return 0
    else
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Test 9: Cloud Run Authentication Check
# ==============================================================================
# Verifies Cloud Run services require authentication
# Technical: Checks for allow-unauthenticated flag
# Best Practice: Services should require authentication by default, use IAP or
# service-to-service authentication
# Security Risk: HIGH - Unauthenticated services are publicly accessible
# ==============================================================================
test_cloud_run_authentication() {
    echo -n "Test 9: Cloud Run authentication required... "

    # Check for ingress = "INGRESS_TRAFFIC_ALL" without authentication
    # This is a simplified check - proper validation would check IAM policies
    if grep -rn 'allow.*unauthenticated' "${TERRAFORM_ROOT}" --include="*.tf" 2>/dev/null | grep -v "no-allow-unauthenticated" | grep -q .; then
        echo -e "${RED}FAIL${NC}"
        echo "  → Found Cloud Run service allowing unauthenticated access"
        echo "  → Ensure this is intentional and protected by other means (IAP, API Gateway)"
        ((FAILED++))
        return 1
    else
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    fi
}

# ==============================================================================
# Run All Tests
# ==============================================================================

echo "Running security tests..."
echo ""

test_no_hardcoded_secrets
test_iam_least_privilege
test_no_public_buckets
test_encryption_at_rest
test_deletion_protection
test_state_backend_security
test_no_default_vpc
test_no_service_account_keys
test_cloud_run_authentication

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Security Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${FAILED} -eq 0 ]; then
    echo -e "${GREEN}✓ All security tests passed${NC}"
    echo ""
    echo "Note: This is a basic security check. For production deployments,"
    echo "consider using dedicated tools like:"
    echo "  - Checkov (infrastructure security scanner)"
    echo "  - TFLint (Terraform linter)"
    echo "  - Terrascan (security scanner)"
    echo "  - Sentinel (policy as code)"
    exit 0
else
    echo -e "${RED}✗ Some security tests failed${NC}"
    echo "Review the failures above and fix security issues before deploying"
    exit 1
fi
