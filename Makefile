KSP_MAIN_DIR := ~/Library/Application\ Support/Steam/steamapps/common/Kerbal\ Space\ Program
KSP_SCRIPT_DIR := ${KSP_MAIN_DIR}/Ships/Script

KOS_SCRIPT_BASEDIR := ~/Projects/kos-scripts
KOS_SOURCE_DIR := ${KOS_SCRIPT_BASEDIR}/source
KOS_MINIFY_DIR := ${KOS_SCRIPT_BASEDIR}/minified
KOS_SCRIPT_DIR := ${KOS_MINIFY_DIR}

PYTHON := python3

telnet:
	@telnet localhost 5410

minify-all:
	@echo "Minifying all source files..."
	@${PYTHON} ksmin.py --nuke --all-files

	@echo "Before minification..."
	@wc -c source/**/*.ks

	@echo "\n----\n"

	@echo "After minification..."
	@wc -c minified/**/*.ks

	@make link

minify-all-safe:
	@echo "Minifying all source files safely..."
	@${PYTHON} ksmin.py --nuke --safe --all-files

	@echo "Before minification..."
	@wc -c source/**/*.ks

	@echo "\n----\n"

	@echo "After minification..."
	@wc -c minified/**/*.ks

	@make link

minify-single-file: guard-FILE
	@${PYTHON} ksmin.py --nuke
	@echo "Copying all source files as is to minified..."
	@cp -r ${KOS_SOURCE_DIR}/* ${KOS_MINIFY_DIR}

	@echo "Minifying only ${FILE}..."
	@${PYTHON} ksmin.py --safe --single-file ./source/${FILE}

	@echo "Before minification..."
	@wc -c ./source/${FILE}

	@echo "\n----\n"

	@echo "After minification..."
	@wc -c ./minified/${FILE}

	@make link

link:
	@echo "Linking minified files into Ships/Script..."
	@ln -sf ${KOS_MINIFY_DIR}/boot ${KSP_SCRIPT_DIR}
	@ln -sf ${KOS_MINIFY_DIR}/actions ${KSP_SCRIPT_DIR}
	@ln -sf ${KOS_MINIFY_DIR}/lib ${KSP_SCRIPT_DIR}
	@ln -sf ${KOS_MINIFY_DIR}/kslib ${KSP_SCRIPT_DIR}

push-action: guard-ACTION guard-TARGET
	@make link
	@echo "Pushing ${ACTION} to vessel(s) ${TARGET}..."
	@cp ${KOS_SCRIPT_DIR}/actions/${ACTION}.ks ${KSP_SCRIPT_DIR}/${TARGET}-update.ks

push-mission: guard-MISSION guard-TARGET
	@make link
	@echo "Pushing ${MISSION} to vessel(s) ${TARGET}..."
	@cp ${KOS_SCRIPT_DIR}/missions/${MISSION}.ks ${KSP_SCRIPT_DIR}/${TARGET}-update.ks

guard-%:
	@if [ "${${*}}" = "" ]; then \
		echo "Required environment variable $* not set"; \
		exit 1; \
	fi
