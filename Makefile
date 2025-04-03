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

GENERIC_PY_RPM_SOURCE_TAR ?= python-bos-reporter-source.tar
BUILD_ROOT_RELDIR ?= dist/rpmbuild
NAME ?= bos-reporter
RPM_NAME ?= python3-$(NAME)
META_RPM_NAME ?= $(NAME)

RPM_VERSION ?= $(shell head -1 .version)
RPM_RELEASE ?= $(shell head -1 .rpm_release)

PIP_INSTALL_ARGS ?= --trusted-host arti.hpc.amslabs.hpecorp.net --trusted-host artifactory.algol60.net --index-url https://arti.hpc.amslabs.hpecorp.net:443/artifactory/api/pypi/pypi-remote/simple --extra-index-url http://artifactory.algol60.net/artifactory/csm-python-modules/simple -c constraints.txt --no-cache
PY_VERSION ?= 3.13
RPM_ARCH ?= x86_64
RPM_OS ?= sle15-sp6
SLE_VERSION ?= 15.6

SPEC_FILE ?= python-$(NAME).spec
META_RPM_SPEC_FILE ?= $(NAME).spec
META_RPM_OS = "noos"
META_RPM_ARCH = "noarch"

PY_PATH ?= /usr/bin/python$(PY_VERSION)
PY_BASENAME := $(shell basename $(PY_PATH))

PYLINT_VENV ?= pylint-$(PY_VERSION)
PYLINT_VENV_PYBIN ?= $(PYLINT_VENV)/bin/python3

META_BUILD_RELDIR ?= $(BUILD_ROOT_RELDIR)/$(META_RPM_ARCH)/$(META_RPM_OS)/$(META_RPM_NAME)
TMPDIR := $(shell mktemp -d $(PWD)/.tmp.$(RPM_ARCH).$(PY_VERSION).$(SLE_VERSION).XXX)
META_BUILD_DIR ?= $(TMPDIR)/$(META_BUILD_RELDIR)

meta_rpm: meta_rpm_prepare meta_rpm_build_source meta_rpm_build meta_rpm_post_clean
pymod_pylint: pymod_pylint_setup pymod_pylint_errors pymod_pylint_full
pymod: pymod_build pymod_pylint

runbuildprep:
		./cms_meta_tools/scripts/runBuildPrep.sh

lint:
		./cms_meta_tools/scripts/runLint.sh

pre_clean:
		rm -rf dist $(GENERIC_PY_RPM_SOURCE_TAR)

python_rpms_prepare:
		tar \
			--exclude '.git*' \
			--exclude './.tmp.*' \
			--exclude ./bos_reporter.egg-info \
			--exclude ./build \
			--exclude ./cms_meta_tools \
			--exclude ./dist \
            --exclude ./$(BUILD_ROOT_RELDIR) \
			--exclude $(GENERIC_PY_RPM_SOURCE_TAR) \
			--exclude './pylint-*' \
			--exclude ./$(META_RPM_SPEC_FILE) \
			-cvf $(GENERIC_PY_RPM_SOURCE_TAR) .

python_rpm_build:
		RPM_NAME='$(RPM_NAME)' \
		RPM_VERSION='$(RPM_VERSION)' \
		RPM_RELEASE='$(RPM_RELEASE)' \
		RPM_ARCH='$(RPM_ARCH)' \
		RPM_OS='$(RPM_OS)' \
		PY_VERSION='$(PY_VERSION)' \
		PIP_INSTALL_ARGS='$(PIP_INSTALL_ARGS)' \
		./cms_meta_tools/resources/build_rpm.sh \
			--arch '$(RPM_ARCH)' \
			'$(BUILD_RELDIR)' '$(RPM_NAME)' '$(RPM_VERSION)]' '$(GENERIC_PY_RPM_SOURCE_TAR)' '$(SPEC_FILE)'

meta_rpm_prepare:
		mkdir -pv \
			$(PWD)/$(META_BUILD_RELDIR)/RPMS/$(META_RPM_ARCH) \
			$(PWD)/$(META_BUILD_RELDIR)/SRPMS \
			$(META_BUILD_DIR)/SPECS \
			$(META_BUILD_DIR)/SOURCES
		cp -v $(META_RPM_SPEC_FILE) $(META_BUILD_DIR)/SPECS/

meta_rpm_build_source:
		uname -a
		cp -v $(META_RPM_SPEC_FILE) $(TMPDIR)
		cd '$(TMPDIR)' && \
		RPM_VERSION='$(RPM_VERSION)' \
		RPM_RELEASE='$(RPM_RELEASE)' \
		META_RPM_ARCH=$(META_RPM_ARCH) \
		META_RPM_NAME=$(META_RPM_NAME) \
		rpmbuild -bs $(META_RPM_SPEC_FILE) --target $(META_RPM_ARCH) --define '_topdir $(META_BUILD_DIR)'
		cp -v $(META_BUILD_DIR)/SRPMS/*.rpm $(PWD)/$(META_BUILD_RELDIR)/SRPMS

meta_rpm_build:
		uname -a
		cd '$(TMPDIR)' && \
		RPM_VERSION='$(RPM_VERSION)' \
		RPM_RELEASE='$(RPM_RELEASE)' \
		META_RPM_ARCH=$(META_RPM_ARCH) \
		META_RPM_NAME=$(META_RPM_NAME) \
		rpmbuild -ba $(META_RPM_SPEC_FILE) --target $(META_RPM_ARCH) --define '_topdir $(META_BUILD_DIR)'
		cp -v $(META_BUILD_DIR)/RPMS/$(META_RPM_ARCH)/*.rpm $(PWD)/$(META_BUILD_RELDIR)/RPMS/$(META_RPM_ARCH)

meta_rpm_post_clean:
		rm -rvf '$(TMPDIR)'

pymod_build:
		$(PY_PATH) --version
		$(PY_PATH) -m pip install --upgrade --user $(PIP_INSTALL_ARGS) pip build setuptools wheel
		$(PY_PATH) -m pip list --format freeze
		$(PY_PATH) -m build --wheel
		cp ./dist/bos_reporter*.whl .

pymod_pylint_setup:
		$(PY_PATH) -m venv $(PYLINT_VENV)
		$(PYLINT_VENV_PYBIN) -m pip install --upgrade $(PIP_INSTALL_ARGS) pip
		$(PYLINT_VENV_PYBIN) -m pip install --disable-pip-version-check $(PIP_INSTALL_ARGS) pylint bos_reporter*.whl
		$(PYLINT_VENV_PYBIN) -m pip list --format freeze

pymod_pylint_errors:
		$(PYLINT_VENV_PYBIN) -m pylint --errors-only bos_reporter

pymod_pylint_full:
		$(PYLINT_VENV_PYBIN) -m pylint --fail-under 9 bos_reporter
