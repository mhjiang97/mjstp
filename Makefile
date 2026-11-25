.PHONY: install update check dry-run

install:
	@bash bin/install.sh $(INCLUDE) $(if $(EXCLUDE),$(foreach e,$(EXCLUDE),--exclude $(e)))

update:
	@bash bin/install.sh --update $(INCLUDE) $(if $(EXCLUDE),$(foreach e,$(EXCLUDE),--exclude $(e)))

dry-run:
	@bash bin/install.sh --dry-run $(INCLUDE) $(if $(EXCLUDE),$(foreach e,$(EXCLUDE),--exclude $(e)))

check:
	@bash -n bin/install.sh lib/utils.sh src/pkgs/sshfwd/sshfwd
	@for f in src/pkgs/*/install.sh; do \
		bash -n "$$f" || exit 1; \
		[ -x "$$f" ] || { echo "Error: $$f is not executable" >&2; exit 1; }; \
	done
	@[ -x bin/install.sh ] || { echo "Error: bin/install.sh is not executable" >&2; exit 1; }
	@echo "Syntax and permission checks passed for all scripts."
