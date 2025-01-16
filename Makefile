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

BUILD_METADATA ?= '1~development~$(shell git rev-parse --short HEAD)'
BUILD_ROOT_RELDIR ?= dist/rpmbuild
NAME ?= bos-reporter
PIP_INSTALL_ARGS ?= --trusted-host arti.hpc.amslabs.hpecorp.net --trusted-host artifactory.algol60.net --index-url https://arti.hpc.amslabs.hpecorp.net:443/artifactory/api/pypi/pypi-remote/simple --extra-index-url http://artifactory.algol60.net/artifactory/csm-python-modules/simple -c constraints.txt
PY_VERSION ?= none
RPM_ARCH ?= noarch
RPM_OS ?= noos
SLE_VERSION ?= none
RPM_NAME ?= python3-bos-reporter
RPM_VERSION ?= $(shell head -1 .version)

PY_PATH ?= /usr/bin/python$(PY_VERSION)
PY_BASENAME := $(shell basename $(PY_PATH))

PYLINT_VENV ?= pylint-$(PY_VERSION)
PYLINT_VENV_PYBIN ?= $(PYLINT_VENV)/bin/python3
SPEC_FILE ?= python-$(NAME).spec
META_SPEC_FILE := $(NAME).spec

BUILD_RELDIR ?= $(BUILD_ROOT_RELDIR)/$(RPM_ARCH)/$(RPM_OS)/$(RPM_NAME)

TMPDIR := $(shell mktemp -d $(PWD)/.tmp.$(RPM_ARCH).$(PY_VERSION).$(SLE_VERSION).XXX)

BUILD_DIR ?= $(TMPDIR)/$(BUILD_RELDIR)

SOURCE_NAME ?= ${RPM_NAME}-${RPM_VERSION}
SOURCE_BASENAME := ${SOURCE_NAME}.tar.bz2
SOURCE_PATH := $(BUILD_DIR)/SOURCES/${SOURCE_BASENAME}

python_rpm: rpm_prepare rpm_python_package_source rpm_python_build_source rpm_build rpm_post_clean
meta_rpm: rpm_prepare rpm_meta_build_source rpm_build rpm_post_clean
pymod: pymod_build pymod_pylint_setup pymod_pylint_errors pymod_pylint_full

runbuildprep:
		./cms_meta_tools/scripts/runBuildPrep.sh

lint:
		./cms_meta_tools/scripts/runLint.sh

rpm_pre_clean:
		rm -rf $(BUILD_ROOT_RELDIR)

rpm_prepare:
		mkdir -pv $(PWD)/$(BUILD_RELDIR)/RPMS/$(RPM_ARCH) $(PWD)/$(BUILD_RELDIR)/SRPMS
		mkdir -pv $(BUILD_DIR)/SPECS $(BUILD_DIR)/SOURCES
		cp -v $(SPEC_FILE) $(BUILD_DIR)/SPECS/

rpm_python_package_source:
		touch $(SOURCE_PATH)
		tar --transform 'flags=r;s,^,/$(SOURCE_NAME)/,' \
			--exclude '.git*' \
			--exclude './.tmp.*' \
			--exclude ./bos_reporter.egg-info \
			--exclude ./build \
			--exclude ./cms_meta_tools \
			--exclude ./dist \
			--exclude $(SOURCE_BASENAME) \
			--exclude './pylint-*' \
			--exclude ./$(META_SPEC_FILE) \
			-cvjf $(SOURCE_PATH) .

rpm_meta_build_source:
		uname -a
		cp -v .version .rpm_release $(SPEC_FILE) $(TMPDIR)
		cd '$(TMPDIR)' && \
		BUILD_METADATA='$(BUILD_METADATA)' \
		PIP_INSTALL_ARGS='$(PIP_INSTALL_ARGS)' \
		PYTHON_BIN=$(PY_BASENAME) \
		RPM_ARCH=$(RPM_ARCH) \
		RPM_NAME=$(RPM_NAME) \
		SOURCE_BASENAME='$(SOURCE_BASENAME)' \
		rpmbuild -bs $(SPEC_FILE) --target $(RPM_ARCH) --define '_topdir $(BUILD_DIR)'
		cp -v $(BUILD_DIR)/SRPMS/*.rpm $(PWD)/$(BUILD_RELDIR)/SRPMS

rpm_python_build_source:
		uname -a
		tar -C '$(TMPDIR)' --transform 'flags=r;s,^/$(SOURCE_NAME)/,,' -xvf '$(SOURCE_PATH)'
		cd '$(TMPDIR)' && \
		BUILD_METADATA='$(BUILD_METADATA)' \
		PIP_INSTALL_ARGS='$(PIP_INSTALL_ARGS)' \
		PYTHON_BIN=$(PY_BASENAME) \
		RPM_ARCH=$(RPM_ARCH) \
		RPM_NAME=$(RPM_NAME) \
		SOURCE_BASENAME='$(SOURCE_BASENAME)' \
		rpmbuild -ts $(SOURCE_PATH) --target $(RPM_ARCH) --define '_topdir $(BUILD_DIR)'
		cp -v $(BUILD_DIR)/SRPMS/*.rpm $(PWD)/$(BUILD_RELDIR)/SRPMS

rpm_build:
		uname -a
		cd '$(TMPDIR)' && \
		BUILD_METADATA='$(BUILD_METADATA)' \
		PIP_INSTALL_ARGS='$(PIP_INSTALL_ARGS)' \
		PYTHON_BIN=$(PY_BASENAME) \
		RPM_ARCH=$(RPM_ARCH) \
		RPM_NAME=$(RPM_NAME) \
		SOURCE_BASENAME='$(SOURCE_BASENAME)' \
		rpmbuild -ba $(SPEC_FILE) --target $(RPM_ARCH) --define '_topdir $(BUILD_DIR)'
		cp -v $(BUILD_DIR)/RPMS/$(RPM_ARCH)/*.rpm $(PWD)/$(BUILD_RELDIR)/RPMS/$(RPM_ARCH)

rpm_post_clean:
		rm -rvf '$(TMPDIR)'

rpm_get_build_reldir:
		echo -n '$(BUILD_RELDIR)'

pymod_build:
		$(PY_PATH) --version
		$(PY_PATH) -m pip install --upgrade --user $(PIP_INSTALL_ARGS) pip build setuptools wheel
		$(PY_PATH) -m pip list --format freeze
		$(PY_PATH) -m build --wheel
		cp ./dist/bos_reporter*.whl .

pymod_pylint_setup:
		$(PY_PATH) -m venv $(PYLINT_VENV)
		$(PYLINT_VENV_PYBIN) -m pip install --upgrade $(PIP_INSTALL_ARGS) pip --no-cache
		$(PYLINT_VENV_PYBIN) -m pip install --disable-pip-version-check $(PIP_INSTALL_ARGS) pylint bos_reporter*.whl
		$(PYLINT_VENV_PYBIN) -m pip list --format freeze

pymod_pylint_errors:
		$(PYLINT_VENV_PYBIN) -m pylint --errors-only bos_reporter

pymod_pylint_full:
		$(PYLINT_VENV_PYBIN) -m pylint --fail-under 9 bos_reporter
