TARGET = oli.sh
CHECKER = shellcheck
STATE = .make

.PHONY: check

${STATE}:
	@mkdir -p $@

${STATE}/checkd: ${TARGET} | ${STATE}
	${CHECKER} -s sh $^

check: ${STATE}/checkd
