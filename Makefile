KSP_MAIN_DIR := ~/Library/Application\ Support/Steam/steamapps/common/Kerbal\ Space\ Program
KSP_SCRIPT_DIR := ${KSP_MAIN_DIR}/Ships/Script

relink:
	@echo "Linking files into Ships/Script..."
	@ln -sf ~/Projects/kos-scripts/source/* ${KSP_SCRIPT_DIR}

push: guard-FILE guard-TARGET
	@make relink
	@echo "Pushing ${FILE} to vessel(s) ${TARGET}..."
	@cp ${FILE} ${KSP_SCRIPT_DIR}/${TARGET}-update.ks

guard-%:
	@if [ "${${*}}" = "" ]; then \
		echo "Required environment variable $* not set"; \
		exit 1; \
	fi
