case "$-" in
    *i*) ;;
    *) return ;;
esac

if [ -z "${CLEARWATER_FASTFETCH_SHOWN:-}" ] && command -v fastfetch >/dev/null 2>&1; then
    export CLEARWATER_FASTFETCH_SHOWN=1
    fastfetch --config /etc/xdg/fastfetch/config.jsonc 2>/dev/null || true
fi
