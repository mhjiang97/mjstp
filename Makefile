.PHONY: install update clean check

install:
	@bash bin/install.sh

update:
	@bash bin/install.sh --update

check:
	@bash -n bin/install.sh
	@echo "Syntax check passed."
