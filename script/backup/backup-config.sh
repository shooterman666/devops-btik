#!/bin/bash
#############################################################################
# backup-config.sh — Backup direktori konfigurasi ke VM infra via rsync
# Didesain buat dijalankan manual ATAU lewat cron di manager1/worker1/worker2
#############################################################################

set -uo pipefail

# ==================== KONFIGURASI ====================

# Direktori konfigurasi yang mau di-backup (sesuaikan sesuai VM)
BACKUP_DIRS=(
    "/etc/ssh"
    "/etc/ufw"
    "/etc/fail2ban"
    "/etc/netplan"
    "/etc/hosts"
    "/etc/hostname"
)

# Tujuan backup: VM infra
REMOTE_USER="nici"
REMOTE_HOST="infra"
REMOTE_BASE_DIR="/home/${REMOTE_USER}/backups/$(hostname)"

# Lokasi log lokal (di VM yang jalanin backup, bukan di infra)
LOG_DIR="/var/log/backup-config"
LOG_FILE="${LOG_DIR}/backup-$(date +%Y%m%d-%H%M%S).log"
LOG_RETENTION_DAYS=30

# ==================== HELPER ====================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${ts}] [${level}] ${msg}" >> "$LOG_FILE"

    case "$level" in
        INFO)    echo -e "${BLUE}[INFO]${NC} ${msg}" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} ${msg}" ;;
        WARNING) echo -e "${YELLOW}[WARNING]${NC} ${msg}" ;;
        ERROR)   echo -e "${RED}[ERROR]${NC} ${msg}" ;;
    esac
}

# ==================== PRA-SYARAT ====================

check_prerequisites() {
    command -v rsync &> /dev/null || { log ERROR "rsync tidak ditemukan. Install dengan: sudo apt install rsync"; exit 1; }

    mkdir -p "$LOG_DIR"

    log INFO "Cek koneksi SSH ke ${REMOTE_HOST}..."
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "${REMOTE_USER}@${REMOTE_HOST}" "exit" 2>> "$LOG_FILE"; then
        log ERROR "Gagal konek ke ${REMOTE_USER}@${REMOTE_HOST} via SSH key. Pastikan key sudah di-copy dan tidak pakai passphrase (buat cron unattended)."
        exit 1
    fi
    log SUCCESS "Koneksi SSH ke ${REMOTE_HOST} OK."

    ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_BASE_DIR}" 2>> "$LOG_FILE"
}

# ==================== BACKUP ====================

run_backup() {
    local total=0
    local success=0
    local failed=0
    local start_time
    start_time=$(date +%s)

    log INFO "=== Mulai backup dari $(hostname) ke ${REMOTE_HOST}:${REMOTE_BASE_DIR} ==="

    for dir in "${BACKUP_DIRS[@]}"; do
        ((total++))

        if [ ! -e "$dir" ]; then
            log WARNING "Skip: ${dir} tidak ditemukan di sistem ini."
            continue
        fi

        log INFO "Backup ${dir}..."

        # -a  : archive mode (preserve permission, owner, timestamp, symlink, dll)
        # -z  : compress saat transfer
        # -R  : preserve relative path (biar struktur /etc/ssh dst konsisten di sisi infra)
        # --delete : hapus file di tujuan yang sudah tidak ada di source (biar backup selalu mirror)
        if rsync -azR --delete "$dir" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BASE_DIR}/" >> "$LOG_FILE" 2>&1; then
            log SUCCESS "Backup ${dir} berhasil."
            ((success++))
        else
            log ERROR "Backup ${dir} GAGAL. Cek detail di ${LOG_FILE}."
            ((failed++))
        fi
    done

    local end_time duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    log INFO "=== Ringkasan: ${success}/${total} berhasil, ${failed} gagal, durasi ${duration}s ==="

    if [ "$failed" -gt 0 ]; then
        log ERROR "Backup selesai DENGAN error. Cek ${LOG_FILE}."
        return 1
    else
        log SUCCESS "Semua backup berhasil tanpa error."
        return 0
    fi
}

# ==================== CLEANUP LOG LAMA ====================

cleanup_old_logs() {
    find "$LOG_DIR" -name "backup-*.log" -mtime "+${LOG_RETENTION_DAYS}" -delete 2>/dev/null
    log INFO "Log lebih lama dari ${LOG_RETENTION_DAYS} hari sudah dibersihkan."
}

# ==================== MAIN ====================

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

check_prerequisites
run_backup
result=$?
cleanup_old_logs

exit $result
