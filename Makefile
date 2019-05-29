KSP_MAIN_DIR := ~/Library/Application\ Support/Steam/steamapps/common/Kerbal\ Space\ Program
KOS_SCRIPT_DIR := ~/Projects/kos-scripts/source
KSP_SCRIPT_DIR := ${KSP_MAIN_DIR}/Ships/Script

relink:
	@echo "Linking files into Ships/Script..."
	@ln -sf ${KOS_SCRIPT_DIR}/boot ${KSP_SCRIPT_DIR}
	@ln -sf ${KOS_SCRIPT_DIR}/leolib ${KSP_SCRIPT_DIR}
	@ln -sf ${KOS_SCRIPT_DIR}/kslib ${KSP_SCRIPT_DIR}

push: guard-ACTION guard-TARGET
	@make relink
	@echo "Pushing ${ACTION} to vessel(s) ${TARGET}..."
	@cp ${KOS_SCRIPT_DIR}/actions/${ACTION}.ks ${KSP_SCRIPT_DIR}/${TARGET}-update.ks

guard-%:
	@if [ "${${*}}" = "" ]; then \
		echo "Required environment variable $* not set"; \
		exit 1; \
	fi
