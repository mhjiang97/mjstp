.PHONY: install update clean check

install:
	@bash bin/install.sh $(if $(EXCLUDE),$(foreach e,$(EXCLUDE),--exclude $(e)))

update:
	@bash bin/install.sh --update $(if $(EXCLUDE),$(foreach e,$(EXCLUDE),--exclude $(e)))

check:
	@bash -n bin/install.sh
	@echo "Syntax check passed."
