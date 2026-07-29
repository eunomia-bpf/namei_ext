SHELL := /bin/bash
.SHELLFLAGS := -e -o pipefail -c

PAPER := main
LATEXMK ?= latexmk
ROOT_DIR := $(abspath ../..)
OUT_DIR ?= $(ROOT_DIR)/.build/paper
PDF := $(OUT_DIR)/$(PAPER).pdf
SNAPSHOT_PDF := $(CURDIR)/namei_ext.pdf

.PHONY: all paper snapshot check clean

all: paper

paper: $(PDF)

snapshot: $(SNAPSHOT_PDF)

$(OUT_DIR):
	install -d "$@"

$(PDF): $(PAPER).tex refs.bib $(wildcard sections/*.tex) | $(OUT_DIR)
	$(LATEXMK) -xelatex -interaction=nonstopmode -halt-on-error -outdir="$(OUT_DIR)" -auxdir="$(OUT_DIR)" "$(PAPER).tex"

$(SNAPSHOT_PDF): $(PDF)
	install -m 0644 "$<" "$@"

check:
	test -f "$(PAPER).tex"
	test -f "refs.bib"
	test -d "sections"
	test -f "sections/01-introduction.tex"
	test -f "sections/05-evaluation.tex"
	test -f "sections/06-related-work.tex"
	! grep -R --line-number 'TODO write' "$(PAPER).tex" sections refs.bib
	! grep -R --line-number 'operation_weighted_alias_hit_rate' "$(PAPER).tex" sections refs.bib
	! grep -R --line-number 'weak accept' "$(PAPER).tex" sections refs.bib

clean:
	rm -rf "$(OUT_DIR)"
