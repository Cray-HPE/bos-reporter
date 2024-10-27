#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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
RPM_VERSION ?= $(shell head -1 .version)
RPM_ARCH ?= noarch
RPM_OS ?= noos
BUILD_BASE_RELDIR ?= dist/rpmbuild/$(RPM_ARCH)
PY_VERSION ?= 3.6
RPM_NAME ?= python3-bos-reporter
BUILD_RELDIR ?= $(BUILD_BASE_RELDIR)/$(RPM_NAME)
SPEC_FILE ?= python-$(NAME).spec
BUILD_METADATA ?= "1~development~$(shell git rev-parse --short HEAD)"
SOURCE_NAME ?= ${RPM_NAME}-${RPM_VERSION}
SOURCE_BASENAME := ${SOURCE_NAME}.tar.bz2
BUILD_DIR ?= $(PWD)/$(BUILD_RELDIR)
SOURCE_PATH := ${BUILD_DIR}/SOURCES/${SOURCE_BASENAME}
PYTHON_BIN := python$(PY_VERSION)
PY_BIN ?= /usr/bin/$(PYTHON_BIN)
PIP_INSTALL_ARGS ?= --trusted-host arti.hpc.amslabs.hpecorp.net --trusted-host artifactory.algol60.net --index-url https://arti.hpc.amslabs.hpecorp.net:443/artifactory/api/pypi/pypi-remote/simple --extra-index-url http://artifactory.algol60.net/artifactory/csm-python-modules/simple -c constraints.txt
PYLINT_VENV ?= pylint-$(PY_VERSION)
PYLINT_VENV_PYBIN ?= $(PYLINT_VENV)/bin/python3

python_rpm: rpm_prepare rpm_package_source rpm_build_source rpm_build
meta_rpm: rpm_prepare rpm_build_source rpm_build
pymod: pymod_build pymod_pylint_setup pymod_pylint_errors pymod_pylint_full

runbuildprep:
		./cms_meta_tools/scripts/runBuildPrep.sh

lint:
		./cms_meta_tools/scripts/runLint.sh

rpm_prepare:
		rm -rf $(BUILD_DIR)
		mkdir -p $(BUILD_DIR)/SPECS $(BUILD_DIR)/SOURCES
		cp $(SPEC_FILE) $(BUILD_DIR)/SPECS/

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
		rpmbuild -bs $(SPEC_FILE) --target $(RPM_ARCH) --define "_topdir $(BUILD_DIR)"

rpm_build:
		RPM_NAME=$(RPM_NAME) \
		PIP_INSTALL_ARGS="$(PIP_INSTALL_ARGS)" \
		PYTHON_BIN=$(PYTHON_BIN) \
		BUILD_METADATA="$(BUILD_METADATA)" \
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
