# Usage:
# make                  # run setup
# make venv             # generate virtual env
# make deps             # Install necessary dependecies
# make precommit        # configure git precommit
# make clean            # delete virtual env

.PHONY: deps clean

ENV=venv
PYTHON=python3
IN_ENV=. ${ENV}/bin/activate
LOG_PREFIX=MAKE ->

default: .git deps ansibledeps

${ENV}:
	@$(info $(LOG_PREFIX) Creating Python virtual env...)
	@${PYTHON} -m venv ${ENV}
	@$(info $(LOG_PREFIX) Adding ${ENV} to .gitignore)
	@grep -qxF "${ENV}/" .gitignore || echo "${ENV}/" >> .gitignore
	@$(info $(LOG_PREFIX) Updating pip...)
	@${IN_ENV} ; pip3 install -U pip wheel

deps: ${ENV}
	@if [ -f requirements.txt ]; then echo "Installing role requirements..."; ${IN_ENV} ; ${PYTHON} -m pip install -r requirements.txt; fi

ansibledeps: ${ENV}
	@if [ -f ansible_requirements.yml ]; then echo "Installing required collections..."; ${IN_ENV} ; ansible-galaxy collection install -r ansible_requirements.yml; fi

.git:
	@git init

clean:
	@$(info $(LOG_PREFIX) Removing virtual env $(ENV))
	@rm -rf ${ENV}
