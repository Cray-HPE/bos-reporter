#
# MIT License
#
# (C) Copyright 2024-2025 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# If you wish to perform a local build, you will need to clone or copy the contents of the
# cms-meta-tools repo to ./cms_meta_tools

NAME ?= bos-reporter
RPM_ARCH ?= noarch
PY_VERSION ?= 3.6
RPM_NAME ?= python3-bos-reporter
BUILD_ROOT_RELDIR ?= dist/rpmbuild
BUILD_METADATA ?= "1~development~$(shell git rev-parse --short HEAD)"
PIP_INSTALL_ARGS ?= --trusted-host arti.hpc.amslabs.hpecorp.net --trusted-host artifactory.algol60.net --index-url https://arti.hpc.amslabs.hpecorp.net:443/artifactory/api/pypi/pypi-remote/simple --extra-index-url http://artifactory.algol60.net/artifactory/csm-python-modules/simple -c constraints.txt
RPM_VERSION ?= $(shell head -1 .version)

SPEC_FILE ?= python-$(NAME).spec
PYTHON_BIN := python$(PY_VERSION)
PY_BIN ?= /usr/bin/$(PYTHON_BIN)
PYLINT_VENV ?= pylint-$(PY_VERSION)
PYLINT_VENV_PYBIN ?= $(PYLINT_VENV)/bin/python3

SOURCE_NAME ?= ${RPM_NAME}-${RPM_VERSION}
SOURCE_BASENAME := ${SOURCE_NAME}.tar.bz2
SOURCE_BUILD_RELDIR := $(BUILD_ROOT_RELDIR)/noarch/$(RPM_NAME)
SOURCE_BUILD_DIR := $(PWD)/$(SOURCE_BUILD_RELDIR)
SOURCE_PATH := $(SOURCE_BUILD_DIR)/SOURCES/${SOURCE_BASENAME}

BUILD_BASE_RELDIR ?= $(BUILD_ROOT_RELDIR)/$(RPM_ARCH)
BUILD_RELDIR ?= $(BUILD_BASE_RELDIR)/$(RPM_NAME)
BUILD_DIR ?= $(PWD)/$(BUILD_RELDIR)

python_rpm_source: rpm_source_prepare rpm_package_source rpm_build_source
python_rpm_main: rpm_prepare rpm_copy_source rpm_build
meta_rpm: rpm_source_prepare rpm_build_source rpm_prepare rpm_build
pymod: pymod_build pymod_pylint_setup pymod_pylint_errors pymod_pylint_full

runbuildprep:
		./cms_meta_tools/scripts/runBuildPrep.sh

lint:
		./cms_meta_tools/scripts/runLint.sh

rpm_pre_clean:
		rm -rf $(BUILD_ROOT_RELDIR)

rpm_source_prepare:
		mkdir -p $(SOURCE_BUILD_DIR)/SPECS $(SOURCE_BUILD_DIR)/SOURCES
		cp $(SPEC_FILE) $(SOURCE_BUILD_DIR)/SPECS/

rpm_package_source:
		touch $(SOURCE_PATH)
		tar --transform 'flags=r;s,^,/$(SOURCE_NAME)/,' \
			--exclude '.git*' \
			--exclude ./bos_reporter.egg-info \
			--exclude ./build \
			--exclude ./cms_meta_tools \
			--exclude ./dist \
			--exclude $(SOURCE_BASENAME) \
			--exclude './pylint-*' \
			--exclude ./$(META_SPEC_FILE) \
			-cvjf $(SOURCE_PATH) .

rpm_build_source:
		RPM_NAME=$(RPM_NAME) \
		PIP_INSTALL_ARGS="$(PIP_INSTALL_ARGS)" \
		PYTHON_BIN=$(PYTHON_BIN) \
		BUILD_METADATA="$(BUILD_METADATA)" \
		rpmbuild -bs $(SPEC_FILE) --target noarch --define "_topdir $(SOURCE_BUILD_DIR)"

rpm_prepare:
		mkdir -p $(BUILD_DIR)/SPECS $(BUILD_DIR)/SOURCES
		cp $(SPEC_FILE) $(BUILD_DIR)/SPECS/

rpm_copy_source:
		cp $(SOURCE_PATH) $(BUILD_DIR)/SOURCES

rpm_build:
		RPM_NAME=$(RPM_NAME) \
		PIP_INSTALL_ARGS="$(PIP_INSTALL_ARGS)" \
		PYTHON_BIN=$(PYTHON_BIN) \
		BUILD_METADATA="$(BUILD_METADATA)" \
		SOURCE_BASENAME="$(SOURCE_BASENAME)" \
		rpmbuild -ba $(SPEC_FILE) --target $(RPM_ARCH) --define "_topdir $(BUILD_DIR)"

pymod_build:
		$(PY_BIN) --version
		$(PY_BIN) -m pip install --upgrade --user $(PIP_INSTALL_ARGS) pip build setuptools wheel
		$(PY_BIN) -m pip list --format freeze
		$(PY_BIN) -m build --wheel
		cp ./dist/bos_reporter*.whl .

pymod_pylint_setup:
		$(PY_BIN) -m venv $(PYLINT_VENV)
		$(PYLINT_VENV_PYBIN) -m pip install --upgrade $(PIP_INSTALL_ARGS) pip --no-cache
		$(PYLINT_VENV_PYBIN) -m pip install --disable-pip-version-check $(PIP_INSTALL_ARGS) pylint bos_reporter*.whl
		$(PYLINT_VENV_PYBIN) -m pip list --format freeze

pymod_pylint_errors:
		$(PYLINT_VENV_PYBIN) -m pylint --errors-only bos_reporter

pymod_pylint_full:
		$(PYLINT_VENV_PYBIN) -m pylint --fail-under 9 bos_reporter
