.PHONY: install clean check

install:
	@bash bin/install.sh

check:
	@bash -n bin/install.sh
	@echo "Syntax check passed."
