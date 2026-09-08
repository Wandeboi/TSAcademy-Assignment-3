#!/usr/bin/env bash
#
# app.sh — DevOps CI/CD demo application
#
# Usage:
#   app.sh system-info
#   app.sh check-host <host>
#   app.sh check-port <host> <port>
#   app.sh help
#
# Exit codes:
#   0 - success
#   1 - operational/runtime failure
#   2 - invalid input
#
set -u

PROG_NAME="app.sh"

print_help() {
    cat <<EOF
${PROG_NAME} - DevOps CI/CD demo application

Usage:
  ${PROG_NAME} system-info                Display system information
  ${PROG_NAME} check-host <host>           Resolve and check a host
  ${PROG_NAME} check-port <host> <port>    Check TCP connectivity to a host:port
  ${PROG_NAME} help                        Show this help message

Exit codes:
  0   success
  1   operational/runtime failure
  2   invalid command or input
EOF
}

cmd_system_info() {
    if [[ true
    echo "======================================"
    echo " System Information"
    echo "======================================"

    echo "Hostname        : $(hostname 2>/dev/null || uname -n)"
    echo "Current User    : $(whoami 2>/dev/null || id -un)"
    echo "Date/Time       : $(date '+%Y-%m-%d %H:%M:%S %Z')"

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        echo "Operating System: $(. /etc/os-release && echo "${PRETTY_NAME:-${NAME:-Unknown}}")"
    else
        echo "Operating System: $(uname -s)"
    fi

    echo "Kernel Version  : $(uname -r 2>/dev/null || echo unknown)"

    if command -v uptime >/dev/null 2>&1; then
        echo "Uptime          : $(uptime -p 2>/dev/null || uptime)"
    else
        echo "Uptime          : unavailable"
    fi

    return 0
}

cmd_check_host() {
    local host="${1:-}"

    if [[ -z "${host}" ]]; then
        echo "Error: 'check-host' requires a host argument" >&2
        echo "Usage: ${PROG_NAME} check-host <host>" >&2
        return 2
    fi

    echo "======================================"
    echo " Host Check: ${host}"
    echo "======================================"

    local resolved=""
    if command -v getent >/dev/null 2>&1; then
        resolved="$(getent hosts "${host}" 2>/dev/null | awk '{print $1}' | head -1)"
    fi
    if [[ -z "${resolved}" ]] && command -v nslookup >/dev/null 2>&1; then
        resolved="$(nslookup "${host}" 2>/dev/null | awk '/^Address: / {print $2; exit}')"
    fi
    if [[ -z "${resolved}" ]] && [[ "${host}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        resolved="${host}"
    fi

    if [[ -n "${resolved}" ]]; then
        echo "Resolved Address: ${resolved}"
    else
        echo "Resolved Address: could not resolve host"
        echo "Result          : FAILED"
        return 1
    fi

    if command -v ping >/dev/null 2>&1; then
        if ping -c 1 -W 2 "${host}" >/dev/null 2>&1; then
            echo "Ping            : SUCCESS"
            echo "Result          : OK"
            return 0
        else
            echo "Ping            : FAILED"
            echo "Result          : FAILED"
            return 1
        fi
    else
        echo "Ping            : unavailable (ping not installed)"
        echo "Result          : OK (resolved only)"
        return 0
    fi
}

cmd_check_port() {
    local host="${1:-}"
    local port="${2:-}"

    if [[ -z "${host}" ]]; then
        echo "Error: 'check-port' requires a host argument" >&2
        echo "Usage: ${PROG_NAME} check-port <host> <port>" >&2
        return 2
    fi

    if [[ -z "${port}" ]]; then
        echo "Error: 'check-port' requires a port argument" >&2
        echo "Usage: ${PROG_NAME} check-port <host> <port>" >&2
        return 2
    fi

    if ! [[ "${port}" =~ ^[0-9]+$ ]]; then
        echo "Error: port must be a number between 1 and 65535" >&2
        return 2
    fi

    if (( port < 1 || port > 65535 )); then
        echo "Error: port must be between 1 and 65535" >&2
        return 2
    fi

    echo "======================================"
    echo " Port Check: ${host}:${port}"
    echo "======================================"

    if timeout 3 bash -c "exec 3<>/dev/tcp/${host}/${port}" >/dev/null 2>&1; then
        echo "Port ${port}          : OPEN"
        return 0
    else
        echo "Port ${port}          : CLOSED or unreachable"
        return 1
    fi
}

main() {
    local command="${1:-}"

    if [[ -z "${command}" ]]; then
        echo "Error: no command supplied" >&2
        print_help >&2
        exit 2
    fi

    case "${command}" in
        system-info)
            cmd_system_info
            exit $?
            ;;
        check-host)
            shift
            cmd_check_host "${1:-}"
            exit $?
            ;;
        check-port)
            shift
            cmd_check_port "${1:-}" "${2:-}"
            exit $?
            ;;
        help|-h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Error: unknown command '${command}'" >&2
            print_help >&2
            exit 2
            ;;
    esac
}

main "$@"
