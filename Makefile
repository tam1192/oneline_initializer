TARGET := oli.sh
CHECKER := shellcheck
CHECKER_ARGS := -s sh 
FMT := shfmt
FMT_CHECK_ARGS := "-d"
FMT_ARGS := "-w"
STATE := .make

.PHONY: check

${STATE}:
	@mkdir -p $@

${STATE}/checkd: ${TARGET} | ${STATE}
	${CHECKER} ${CHECKER_ARGS} ${TARGET}
	@touch $@

${STATE}/fmt_checkd: ${TARGET} | ${STATE}
	${FMT} ${FMT_CHECK_ARGS} ${TARGET}
	@touch $@

check: ${STATE}/checkd ${STATE}/fmt_checkd

${STATE}/fmted: ${TARGET} | ${STATE}
	${FMT} ${FMT_ARGS} ${TARGET}
	@touch $@

fmt: ${STATE}/fmted
