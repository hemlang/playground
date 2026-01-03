#!/bin/bash
# ==============================================================================
# Grove Sandbox Security Setup Script
# ==============================================================================
#
# This script checks and configures security features for running Grove
# in a production environment with untrusted code execution.
#
# Usage:
#   ./setup-sandbox.sh          # Check current status
#   ./setup-sandbox.sh --fix    # Attempt to fix issues (requires root)
#
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
WARN=0
FAIL=0

FIX_MODE=false
if [[ "$1" == "--fix" ]]; then
    FIX_MODE=true
fi

# ==============================================================================
# Helper functions
# ==============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((PASS++))
}

check_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((WARN++))
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((FAIL++))
}

check_info() {
    echo -e "  ${BLUE}ℹ${NC} $1"
}

# ==============================================================================
# Checks
# ==============================================================================

check_bubblewrap() {
    print_header "Bubblewrap (bwrap)"

    if command -v bwrap &> /dev/null; then
        local version=$(bwrap --version 2>&1 | head -1)
        check_pass "Installed: $version"

        # Test if it actually works
        if bwrap --unshare-user --uid 65534 --gid 65534 /bin/true 2>/dev/null; then
            check_pass "Functional with user namespaces"
        else
            check_fail "Cannot use user namespaces (see kernel settings)"
        fi
    else
        check_fail "Not installed"
        echo ""
        echo "      Install with:"
        echo "        Debian/Ubuntu: sudo apt install bubblewrap"
        echo "        Fedora/RHEL:   sudo dnf install bubblewrap"
        echo "        Arch:          sudo pacman -S bubblewrap"

        if $FIX_MODE; then
            echo ""
            echo "      Attempting to install..."
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y bubblewrap
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y bubblewrap
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm bubblewrap
            else
                echo "      Could not detect package manager"
            fi
        fi
    fi
}

check_user_namespaces() {
    print_header "Kernel: User Namespaces"

    local userns_file="/proc/sys/kernel/unprivileged_userns_clone"

    if [[ -f "$userns_file" ]]; then
        local value=$(cat "$userns_file")
        if [[ "$value" == "1" ]]; then
            check_pass "Unprivileged user namespaces enabled"
        else
            check_fail "Unprivileged user namespaces disabled"
            echo ""
            echo "      Enable with:"
            echo "        sudo sysctl kernel.unprivileged_userns_clone=1"
            echo "        echo 'kernel.unprivileged_userns_clone=1' | sudo tee /etc/sysctl.d/99-userns.conf"

            if $FIX_MODE; then
                echo ""
                echo "      Attempting to enable..."
                sudo sysctl kernel.unprivileged_userns_clone=1
                echo 'kernel.unprivileged_userns_clone=1' | sudo tee /etc/sysctl.d/99-userns.conf
            fi
        fi
    else
        # File doesn't exist - might be enabled by default or configured differently
        check_info "unprivileged_userns_clone sysctl not present"
        check_info "Namespaces may be enabled by default on this kernel"

        # Try to test directly
        if command -v unshare &> /dev/null; then
            if unshare --user --map-root-user true 2>/dev/null; then
                check_pass "User namespaces work (tested with unshare)"
            else
                check_warn "User namespaces may not work for unprivileged users"
            fi
        fi
    fi
}

check_seccomp() {
    print_header "Kernel: Seccomp"

    if [[ -f "/proc/sys/kernel/seccomp/actions_avail" ]]; then
        check_pass "Seccomp available"
        local actions=$(cat /proc/sys/kernel/seccomp/actions_avail)
        check_info "Actions: $actions"
    elif grep -q "CONFIG_SECCOMP=y" /boot/config-$(uname -r) 2>/dev/null; then
        check_pass "Seccomp compiled into kernel"
    elif [[ -f "/proc/self/seccomp" ]]; then
        check_pass "Seccomp available (legacy check)"
    else
        check_warn "Could not verify seccomp support"
    fi
}

check_cgroups() {
    print_header "Kernel: Cgroups"

    if [[ -d "/sys/fs/cgroup" ]]; then
        check_pass "Cgroups mounted at /sys/fs/cgroup"

        # Check cgroup version
        if [[ -f "/sys/fs/cgroup/cgroup.controllers" ]]; then
            check_info "Cgroups v2 (unified hierarchy)"
        else
            check_info "Cgroups v1 (legacy hierarchy)"
        fi

        # Check for memory controller
        if [[ -d "/sys/fs/cgroup/memory" ]] || grep -q "memory" /sys/fs/cgroup/cgroup.controllers 2>/dev/null; then
            check_pass "Memory controller available"
        else
            check_warn "Memory controller not found"
        fi

        # Check for pids controller
        if [[ -d "/sys/fs/cgroup/pids" ]] || grep -q "pids" /sys/fs/cgroup/cgroup.controllers 2>/dev/null; then
            check_pass "PIDs controller available"
        else
            check_warn "PIDs controller not found"
        fi
    else
        check_fail "Cgroups not mounted"
    fi
}

check_hemlock() {
    print_header "Hemlock Runtime"

    if command -v hemlock &> /dev/null; then
        local version=$(hemlock --version 2>&1 | head -1)
        check_pass "Installed: $version"

        # Check sandbox flag
        if hemlock --help 2>&1 | grep -q "\-\-sandbox"; then
            check_pass "Sandbox flag available"
        else
            check_warn "Sandbox flag not found in help output"
        fi
    else
        check_fail "hemlock not found in PATH"
    fi

    if command -v hemlockc &> /dev/null; then
        check_pass "hemlockc available for type checking"
    else
        check_warn "hemlockc not found (type checking will fail)"
    fi
}

check_temp_directory() {
    print_header "Temp Directory"

    local temp_dir="/tmp/hemlock-playground"

    if [[ -d "$temp_dir" ]]; then
        check_pass "Directory exists: $temp_dir"

        # Check permissions
        local perms=$(stat -c "%a" "$temp_dir")
        if [[ "$perms" == "700" ]] || [[ "$perms" == "750" ]]; then
            check_pass "Permissions are restrictive: $perms"
        else
            check_warn "Permissions are too open: $perms (recommend 700)"
            if $FIX_MODE; then
                chmod 700 "$temp_dir"
                echo "      Fixed: chmod 700 $temp_dir"
            fi
        fi

        # Check owner
        local owner=$(stat -c "%U" "$temp_dir")
        check_info "Owner: $owner"
    else
        check_info "Directory does not exist yet (will be created on first run)"
    fi
}

check_grove_user() {
    print_header "Dedicated User"

    if id "grove" &>/dev/null; then
        check_pass "Dedicated 'grove' user exists"
        local groups=$(id -nG grove)
        check_info "Groups: $groups"
    else
        check_warn "No dedicated 'grove' user"
        echo ""
        echo "      Create with:"
        echo "        sudo useradd -r -s /bin/false -d /nonexistent grove"

        if $FIX_MODE; then
            echo ""
            echo "      Attempting to create..."
            sudo useradd -r -s /bin/false -d /nonexistent grove
        fi
    fi
}

check_network_isolation() {
    print_header "Network Isolation"

    # Check if we can create network namespaces
    if command -v unshare &> /dev/null; then
        if unshare --net true 2>/dev/null; then
            check_pass "Network namespaces available"
        else
            check_warn "Cannot create network namespaces (may need privileges)"
        fi
    else
        check_warn "unshare command not available"
    fi

    check_info "Bubblewrap uses --unshare-net for network isolation"
    check_info "Additional VLAN isolation recommended for production"
}

check_resource_limits() {
    print_header "Resource Limits (ulimit)"

    # Check current limits
    local max_procs=$(ulimit -u)
    local max_mem=$(ulimit -v)
    local max_files=$(ulimit -n)

    check_info "Max processes: $max_procs"
    check_info "Max virtual memory: $max_mem"
    check_info "Max open files: $max_files"

    if [[ "$max_mem" == "unlimited" ]]; then
        check_warn "No virtual memory limit set"
        echo "      Consider setting limits in /etc/security/limits.conf"
    fi
}

check_apparmor_selinux() {
    print_header "MAC (AppArmor/SELinux)"

    # Check AppArmor
    if command -v aa-status &> /dev/null; then
        if aa-status --enabled 2>/dev/null; then
            check_pass "AppArmor enabled"
            local profiles=$(aa-status 2>/dev/null | grep "profiles are loaded" | head -1)
            check_info "$profiles"
        else
            check_info "AppArmor installed but not enabled"
        fi
    fi

    # Check SELinux
    if command -v getenforce &> /dev/null; then
        local selinux_mode=$(getenforce 2>/dev/null)
        if [[ "$selinux_mode" == "Enforcing" ]]; then
            check_pass "SELinux enforcing"
        elif [[ "$selinux_mode" == "Permissive" ]]; then
            check_warn "SELinux permissive (consider enforcing)"
        else
            check_info "SELinux: $selinux_mode"
        fi
    fi

    if ! command -v aa-status &> /dev/null && ! command -v getenforce &> /dev/null; then
        check_info "No MAC system detected (optional but recommended)"
    fi
}

generate_systemd_unit() {
    print_header "Systemd Service (Optional)"

    local unit_file="/etc/systemd/system/grove.service"

    if [[ -f "$unit_file" ]]; then
        check_pass "Systemd unit exists: $unit_file"
    else
        check_info "No systemd unit installed"
        echo ""
        echo "      Example unit file:"
        echo ""
        cat << 'UNIT'
      [Unit]
      Description=Grove - Hemlock Playground Server
      After=network.target

      [Service]
      Type=simple
      User=grove
      Group=grove
      WorkingDirectory=/opt/playground
      Environment=GROVE_SECURE_MODE=1
      Environment=GROVE_PORT=8080
      ExecStart=/usr/bin/hemlock grove.hml
      Restart=on-failure
      RestartSec=5

      # Security hardening
      NoNewPrivileges=yes
      ProtectSystem=strict
      ProtectHome=yes
      PrivateTmp=yes
      ReadWritePaths=/tmp/hemlock-playground

      [Install]
      WantedBy=multi-user.target
UNIT
        echo ""
    fi
}

print_summary() {
    print_header "Summary"

    echo ""
    echo -e "  ${GREEN}Passed:${NC}   $PASS"
    echo -e "  ${YELLOW}Warnings:${NC} $WARN"
    echo -e "  ${RED}Failed:${NC}   $FAIL"
    echo ""

    if [[ $FAIL -gt 0 ]]; then
        echo -e "  ${RED}Some critical checks failed.${NC}"
        echo "  Run with --fix to attempt automatic fixes (requires root)"
        echo ""
    elif [[ $WARN -gt 0 ]]; then
        echo -e "  ${YELLOW}Some warnings detected.${NC}"
        echo "  Review recommendations above for improved security."
        echo ""
    else
        echo -e "  ${GREEN}All checks passed!${NC}"
        echo ""
    fi

    echo "  To enable secure mode, run Grove with:"
    echo ""
    echo "    GROVE_SECURE_MODE=1 hemlock grove.hml"
    echo ""
}

print_environment_vars() {
    print_header "Environment Variables"

    echo ""
    echo "  Grove accepts these security-related environment variables:"
    echo ""
    echo "    GROVE_SECURE_MODE=1         Enable bubblewrap sandboxing"
    echo "    GROVE_BWRAP_PATH=/path      Custom bubblewrap binary path"
    echo "    GROVE_SANDBOX_MEMORY_MB=256 Memory limit per execution (MB)"
    echo "    GROVE_SANDBOX_PIDS_MAX=50   Max processes per execution"
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================

echo ""
echo "========================================"
echo "  Grove Sandbox Security Checker"
echo "========================================"
echo ""
echo "Checking system configuration for secure code execution..."

check_bubblewrap
check_user_namespaces
check_seccomp
check_cgroups
check_hemlock
check_temp_directory
check_grove_user
check_network_isolation
check_resource_limits
check_apparmor_selinux
generate_systemd_unit
print_environment_vars
print_summary
