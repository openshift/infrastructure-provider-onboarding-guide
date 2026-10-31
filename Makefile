VENV ?= $(PWD)/.venv

.PHONY: venv
venv:
	test -d $(VENV) || python3 -m venv $(VENV)

.PHONY: install
install: venv
	source $(VENV)/bin/activate && ./hack/install-mkdocs.sh

.PHONY: build
build:
	$(VENV)/bin/mkdocs build

.PHONY: serve
serve:
	$(VENV)/bin/mkdocs serve

.PHONY: all
all: install build
