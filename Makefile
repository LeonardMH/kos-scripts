KSP_MAIN_DIR := ~/Library/Application\ Support/Steam/steamapps/common/Kerbal\ Space\ Program
KSP_SCRIPT_DIR := ${KSP_MAIN_DIR}/Ships/Script

KOS_SCRIPT_BASEDIR := ~/Projects/kos-scripts
KOS_SOURCE_DIR := ${KOS_SCRIPT_BASEDIR}/source
KOS_MINIFY_DIR := ${KOS_SCRIPT_BASEDIR}/minified
KOS_SCRIPT_DIR := ${KOS_MINIFY_DIR}

PYTHON := python3

telnet:
	@telnet localhost 5410

clean:
	@cd minified && git clean -fxdq

report-size:
	@echo "Before minification..."
	@wc -c source/**/*.{ks,ksx}
	@echo "\n----\n"
	@echo "After minification..."
	@wc -c minified/**/*.ks

report-size-single-file: guard-FILE
	@echo "Before minification..."
	@wc -c ./source/${FILE}
	@echo "\n----\n"
	@echo "After minification..."
	@wc -c ./minified/${FILE}

transpile-only-all:
	@echo "Transpiling all source files, no optimizations..."
	@${PYTHON} ksx.py --nuke --transpile-only --all-files

	@make report-size
	@make link

compile-all:
	@echo "Compiling all source files..."
	@${PYTHON} ksx.py --nuke --all-files

	@make report-size
	@make link

compile-all-safe:
	@echo "Compiling all source files safely..."
	@${PYTHON} ksx.py --nuke --safe --all-files

	@make report-size
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
