.PHONY: install update clean check

install:
	@bash bin/install.sh $(INCLUDE) $(if $(EXCLUDE),$(foreach e,$(EXCLUDE),--exclude $(e)))

update:
	@bash bin/install.sh --update $(INCLUDE) $(if $(EXCLUDE),$(foreach e,$(EXCLUDE),--exclude $(e)))

check:
	@bash -n bin/install.sh
	@echo "Syntax check passed."
