#!/usr/bin/env bash

# ==========================================================
# VANGUARD
# Web Security Assessment Toolkit
#
# Authorized security testing only
#
# Dependencies:
#   nmap
#   curl
#   dig
#   openssl
# ==========================================================

set -o pipefail

# ==========================================================
# COLORS
# ==========================================================

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

CYAN='\033[1;36m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'


# ==========================================================
# UTILITY FUNCTIONS
# ==========================================================

line() {
    echo -e "${DIM}────────────────────────────────────────────────────────${RESET}"
}

section() {
    echo
    echo -e "${CYAN}${BOLD}$1${RESET}"
    line
}

info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[ OK ]${RESET} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

error() {
    echo -e "${RED}[FAIL]${RESET} $1"
}


# ==========================================================
# STARTUP BANNER
# ==========================================================

show_banner() {

    clear

    local colors=(
        "$CYAN"
        "$BLUE"
        "$MAGENTA"
        "$CYAN"
    )

    for color in "${colors[@]}"; do

        clear

        echo
        echo -e "${color}${BOLD}"

        echo "██╗   ██╗ █████╗ ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗ "
        echo "██║   ██║██╔══██╗████╗  ██║██═════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗"
        echo "██║   ██║███████║██╔██╗ ██║██       ██║   ██║███████║██████╔╝██║  ██║"
        echo "╚██╗ ██╔╝██╔══██║██║╚██╗██║██       ╚██╗ ██╔╝██╔══██║██╔══██╗██║  ██║"
        echo " ╚████╔╝ ██║  ██║██║ ╚████║╚██████╗  ╚████╔╝ ██║  ██║██║  ██║██████╔╝"
        echo "  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ "

        echo -e "${RESET}"

        echo -e "${WHITE}${BOLD}"
        echo "              WEB SECURITY ASSESSMENT TOOLKIT"
        echo -e "${RESET}"

        sleep 0.18

    done

    echo
    echo -e "${CYAN}────────────────────────────────────────────────────────${RESET}"
    echo -e "${WHITE}          AUTHORIZED SECURITY TESTING ONLY${RESET}"
    echo -e "${CYAN}────────────────────────────────────────────────────────${RESET}"
    echo

    sleep 0.5
}


# ==========================================================
# DEPENDENCY CHECK
# ==========================================================

check_dependencies() {

    section "ENVIRONMENT CHECK"

    local missing=0

    for tool in nmap curl dig openssl; do

        if command -v "$tool" >/dev/null 2>&1; then
            success "$tool detected"
        else
            error "$tool is not installed"
            missing=1
        fi

    done

    if [[ "$missing" -eq 1 ]]; then

        echo
        warning "Install the missing dependencies before running VANGUARD."
        echo

        read -rp "Press ENTER to close..."
        exit 1

    fi
}


# ==========================================================
# TARGET CONFIGURATION
# ==========================================================

get_target() {

    section "TARGET CONFIGURATION"

    read -rp "Target domain/IP: " TARGET

    # Remove protocol
    TARGET=$(echo "$TARGET" | sed -E 's#^https?://##')

    # Remove path
    TARGET=$(echo "$TARGET" | cut -d '/' -f1)

    # Remove whitespace
    TARGET=$(echo "$TARGET" | xargs)

    if [[ -z "$TARGET" ]]; then

        error "No target supplied."
        echo

        read -rp "Press ENTER to close..."
        exit 1

    fi

    echo
    info "Target: ${BOLD}$TARGET${RESET}"
}


# ==========================================================
# CREATE REPORT WORKSPACE
# ==========================================================

create_workspace() {

    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

    REPORT_DIR="reports/${TARGET}_${TIMESTAMP}"

    mkdir -p "$REPORT_DIR"

    MAIN_REPORT="$REPORT_DIR/assessment_report.txt"
    NMAP_REPORT="$REPORT_DIR/nmap.txt"
    DNS_REPORT="$REPORT_DIR/dns.txt"
    HTTP_REPORT="$REPORT_DIR/http.txt"
    TLS_REPORT="$REPORT_DIR/tls.txt"
    HEADER_REPORT="$REPORT_DIR/security_headers.txt"

    touch "$MAIN_REPORT"

    {
        echo "VANGUARD SECURITY ASSESSMENT"
        echo "=============================================="
        echo
        echo "Target    : $TARGET"
        echo "Started   : $(date)"
        echo
    } > "$MAIN_REPORT"

    success "Assessment workspace created"
}


# ==========================================================
# DNS ANALYSIS
# ==========================================================

dns_analysis() {

    section "01 | DNS ANALYSIS"

    info "Collecting DNS records..."

    {
        echo "DNS INFORMATION"
        echo "==============="
        echo
        echo "Target: $TARGET"
        echo

        echo "[A RECORDS]"
        dig +short A "$TARGET"

        echo
        echo "[AAAA RECORDS]"
        dig +short AAAA "$TARGET"

        echo
        echo "[MX RECORDS]"
        dig +short MX "$TARGET"

        echo
        echo "[NS RECORDS]"
        dig +short NS "$TARGET"

        echo
        echo "[TXT RECORDS]"
        dig +short TXT "$TARGET"

    } | tee "$DNS_REPORT"

    echo
    success "DNS analysis completed"

    {
        echo
        cat "$DNS_REPORT"
    } >> "$MAIN_REPORT"
}


# ==========================================================
# PORT & SERVICE DISCOVERY
# ==========================================================

port_scan() {

    section "02 | PORT & SERVICE DISCOVERY"

    info "Scanning common TCP services..."
    echo

    nmap \
        -sV \
        --top-ports 1000 \
        "$TARGET" \
        -oN "$NMAP_REPORT"

    echo

    if [[ -s "$NMAP_REPORT" ]]; then
        success "Service discovery completed"
    else
        warning "No Nmap results were produced"
    fi

    {
        echo
        echo "PORT & SERVICE DISCOVERY"
        echo "========================"
        cat "$NMAP_REPORT"
    } >> "$MAIN_REPORT"
}


# ==========================================================
# HTTP ANALYSIS
# ==========================================================

http_analysis() {

    section "03 | HTTP ANALYSIS"

    info "Analyzing HTTPS response..."

    HTTP_URL="https://$TARGET"

    HTTP_HEADERS=$(curl \
        -k \
        -sS \
        -D - \
        -o /dev/null \
        --connect-timeout 8 \
        --max-time 15 \
        "$HTTP_URL" 2>/dev/null)

    # Fall back to HTTP
    if [[ -z "$HTTP_HEADERS" ]]; then

        warning "HTTPS unavailable. Trying HTTP..."

        HTTP_URL="http://$TARGET"

        HTTP_HEADERS=$(curl \
            -sS \
            -D - \
            -o /dev/null \
            --connect-timeout 8 \
            --max-time 15 \
            "$HTTP_URL" 2>/dev/null)

    fi

    if [[ -n "$HTTP_HEADERS" ]]; then

        echo "$HTTP_HEADERS" > "$HTTP_REPORT"

        echo
        echo -e "${DIM}Response headers:${RESET}"
        echo "$HTTP_HEADERS"

        success "HTTP analysis completed"

    else

        warning "No HTTP response received."

        : > "$HTTP_REPORT"

    fi

    {
        echo
        echo "HTTP ANALYSIS"
        echo "============="
        cat "$HTTP_REPORT"
    } >> "$MAIN_REPORT"
}


# ==========================================================
# SECURITY HEADER ANALYSIS
# ==========================================================

security_headers() {

    section "04 | SECURITY HEADER REVIEW"

    local headers
    headers=$(cat "$HTTP_REPORT")

    declare -A header_names

    header_names["Strict-Transport-Security"]="HSTS"
    header_names["Content-Security-Policy"]="Content-Security-Policy"
    header_names["X-Frame-Options"]="X-Frame-Options"
    header_names["X-Content-Type-Options"]="X-Content-Type-Options"
    header_names["Referrer-Policy"]="Referrer-Policy"
    header_names["Permissions-Policy"]="Permissions-Policy"

    : > "$HEADER_REPORT"

    echo "SECURITY HEADER REVIEW" >> "$HEADER_REPORT"
    echo "======================" >> "$HEADER_REPORT"
    echo >> "$HEADER_REPORT"

    for header in "${!header_names[@]}"; do

        name="${header_names[$header]}"

        if echo "$headers" | grep -qi "^${header}:"; then

            value=$(echo "$headers" |
                grep -i "^${header}:" |
                head -n 1 |
                sed 's/^[^:]*:[[:space:]]*//')

            echo -e "${GREEN}[PRESENT]${RESET} $name"

            echo "[$name] PRESENT: $value" \
                >> "$HEADER_REPORT"

        else

            echo -e "${YELLOW}[MISSING ]${RESET} $name"

            echo "[$name] NOT PRESENT" \
                >> "$HEADER_REPORT"

        fi

    done

    {
        echo
        cat "$HEADER_REPORT"
    } >> "$MAIN_REPORT"
}


# ==========================================================
# TECHNOLOGY INFORMATION
# ==========================================================

technology_detection() {

    section "05 | TECHNOLOGY INDICATORS"

    info "Inspecting HTTP response indicators..."

    SERVER=$(grep -i '^server:' "$HTTP_REPORT" |
        head -n 1 |
        cut -d ':' -f2- |
        xargs)

    POWERED=$(grep -i '^x-powered-by:' "$HTTP_REPORT" |
        head -n 1 |
        cut -d ':' -f2- |
        xargs)

    echo

    if [[ -n "$SERVER" ]]; then
        echo -e "${WHITE}Server       : ${CYAN}$SERVER${RESET}"
    else
        echo -e "${WHITE}Server       : ${DIM}Not disclosed${RESET}"
    fi

    if [[ -n "$POWERED" ]]; then
        echo -e "${WHITE}Powered By   : ${CYAN}$POWERED${RESET}"
    else
        echo -e "${WHITE}Powered By   : ${DIM}Not disclosed${RESET}"
    fi

    {
        echo
        echo "TECHNOLOGY INDICATORS"
        echo "====================="
        echo "Server     : ${SERVER:-Not disclosed}"
        echo "Powered By : ${POWERED:-Not disclosed}"
    } >> "$MAIN_REPORT"

    success "Technology analysis completed"
}


# ==========================================================
# TLS CERTIFICATE ANALYSIS
# ==========================================================

tls_analysis() {

    section "06 | TLS CERTIFICATE ANALYSIS"

    info "Inspecting TLS certificate..."

    TLS_OUTPUT=$(echo |
        openssl s_client \
            -connect "${TARGET}:443" \
            -servername "$TARGET" \
            2>/dev/null |
        openssl x509 \
            -noout \
            -subject \
            -issuer \
            -dates \
            -serial \
            -fingerprint 2>/dev/null)

    if [[ -n "$TLS_OUTPUT" ]]; then

        echo "$TLS_OUTPUT" > "$TLS_REPORT"

        echo
        echo "$TLS_OUTPUT"

        success "TLS certificate information collected"

    else

        warning "TLS certificate information unavailable"

        echo "TLS information unavailable." > "$TLS_REPORT"

    fi

    {
        echo
        echo "TLS CERTIFICATE ANALYSIS"
        echo "========================"
        cat "$TLS_REPORT"
    } >> "$MAIN_REPORT"
}


# ==========================================================
# WEB METADATA
# ==========================================================

web_metadata() {

    section "07 | WEB METADATA"

    info "Checking robots.txt..."

    ROBOTS_STATUS=$(curl \
        -k \
        -L \
        -s \
        -o /dev/null \
        -w "%{http_code}" \
        --connect-timeout 8 \
        --max-time 15 \
        "https://$TARGET/robots.txt")

    echo -e "${WHITE}robots.txt  : ${CYAN}$ROBOTS_STATUS${RESET}"

    info "Checking sitemap.xml..."

    SITEMAP_STATUS=$(curl \
        -k \
        -L \
        -s \
        -o /dev/null \
        -w "%{http_code}" \
        --connect-timeout 8 \
        --max-time 15 \
        "https://$TARGET/sitemap.xml")

    echo -e "${WHITE}sitemap.xml : ${CYAN}$SITEMAP_STATUS${RESET}"

    {
        echo
        echo "WEB METADATA"
        echo "============"
        echo "robots.txt  : $ROBOTS_STATUS"
        echo "sitemap.xml : $SITEMAP_STATUS"
    } >> "$MAIN_REPORT"

    success "Web metadata checks completed"
}


# ==========================================================
# FINAL SUMMARY
# ==========================================================

summary() {

    section "ASSESSMENT SUMMARY"

    echo

    echo -e "${WHITE}Target        : ${CYAN}$TARGET${RESET}"
    echo -e "${WHITE}Completed     : ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${RESET}"

    echo
    echo -e "${WHITE}Report files:${RESET}"

    echo -e "  ${GREEN}├──${RESET} assessment_report.txt"
    echo -e "  ${GREEN}├──${RESET} nmap.txt"
    echo -e "  ${GREEN}├──${RESET} dns.txt"
    echo -e "  ${GREEN}├──${RESET} http.txt"
    echo -e "  ${GREEN}├──${RESET} security_headers.txt"
    echo -e "  ${GREEN}└──${RESET} tls.txt"

    echo
    echo -e "${WHITE}Report directory:${RESET}"
    echo -e "${YELLOW}$REPORT_DIR${RESET}"

    {
        echo
        echo "=============================================="
        echo "ASSESSMENT COMPLETED"
        echo "=============================================="
        echo "Completed: $(date)"
    } >> "$MAIN_REPORT"
}


# ==========================================================
# MAIN PROGRAM
# ==========================================================

show_banner

check_dependencies

get_target

create_workspace

dns_analysis

port_scan

http_analysis

security_headers

technology_detection

tls_analysis

web_metadata

summary


# ==========================================================
# FINAL SCREEN
#
# IMPORTANT:
#   No clear
#   No exit animation
#   No automatic exit
# ==========================================================

echo
echo -e "${GREEN}${BOLD}"
echo "========================================================"
echo "             VANGUARD ASSESSMENT COMPLETE"
echo "========================================================"
echo -e "${RESET}"

echo
echo -e "${WHITE}Target        : ${CYAN}$TARGET${RESET}"
echo -e "${WHITE}Report        : ${YELLOW}$REPORT_DIR${RESET}"

echo
echo -e "${GREEN}${BOLD}"
echo "Results have been preserved for review."
echo -e "${RESET}"

echo
echo -e "${DIM}The program will remain open.${RESET}"
echo -e "${DIM}Press ENTER only when you want to close it.${RESET}"

echo

# ==========================================================
# KEEP TERMINAL OPEN
# ==========================================================

read -r
