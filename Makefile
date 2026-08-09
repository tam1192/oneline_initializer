TARGET := oli.sh
CHECKER := shellcheck
CHECKER_ARGS := -s sh 
STATE := .make

.PHONY: check

${STATE}:
	@mkdir -p $@

${STATE}/checkd: ${TARGET} | ${STATE}
	${CHECKER} ${CHECKER_ARGS} ${TARGET}
	@touch $@

check: ${STATE}/checkd
