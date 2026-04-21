.PHONY: install update clean check dry-run

install:
	@bash bin/install.sh $(INCLUDE) $(if $(EXCLUDE),$(foreach e,$(EXCLUDE),--exclude $(e)))

update:
	@bash bin/install.sh --update $(INCLUDE) $(if $(EXCLUDE),$(foreach e,$(EXCLUDE),--exclude $(e)))

dry-run:
	@bash bin/install.sh --dry-run $(INCLUDE) $(if $(EXCLUDE),$(foreach e,$(EXCLUDE),--exclude $(e)))

check:
	@bash -n bin/install.sh
	@for f in src/pkgs/*/install.sh; do bash -n "$$f" || exit 1; done
	@echo "Syntax check passed for all scripts."
