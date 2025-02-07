# Copyright 2024-2025 Hewlett Packard Enterprise Development LP
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# (MIT License)

%define install_dir /usr/lib/bos-reporter/
%define install_python_dir %{install_dir}venv

# Define which Python flavors python-rpm-macros will use (this can be a list).
# https://github.com/openSUSE/python-rpm-macros#terminology
%define py_version %(echo ${PY_VERSION})
%define pythons python%{py_version}
%define py_minor_version %(echo ${PY_VERSION} | cut -d. -f2)

Name: %(echo ${RPM_NAME})
License: MIT
Summary: A system service which reports information about a booted node state
Group: System/Management
Version: %(echo ${RPM_VERSION})
Release: %(echo ${RPM_RELEASE})
Source: %(echo ${SOURCE_BASENAME})
BuildArch: %(echo ${RPM_ARCH})
Provides: python-bos-reporter == %{version}
# This replaces earlier versions of python-bos-reporter
Conflicts: python-bos-reporter < %{version}
Vendor: HPE
# Using or statements in spec files requires RPM and rpm-build >= 4.13
BuildRequires: rpm-build >= 4.13
Requires: rpm >= 4.13
BuildRequires: (python%{python_version_nodots}-base or python3-base >= %{py_version})
BuildRequires: python-rpm-generators
BuildRequires: python-rpm-macros
BuildRequires: systemd-rpm-macros
Requires: (python%{python_version_nodots}-base or python3-base >= %{py_version})
Requires: systemd
Requires: cray-auth-utils
Requires: spire-agent

# Add strategic obsoletes statements to nudge Zypper to install python-bos-reporter for the highest Python version on the system
%if %{py_minor_version} > 6
Obsoletes: python3-bos-reporter <= %{version}

%if %{py_minor_version} > 9
Obsoletes: python39-bos-reporter <= %{version}

%if %{py_minor_version} > 10
Obsoletes: python310-bos-reporter <= %{version}

%if %{py_minor_version} > 11
Obsoletes: python311-bos-reporter <= %{version}

%endif # %{py_minor_version} > 11
%endif # %{py_minor_version} > 10
%endif # %{py_minor_version} > 9
%endif # %{py_minor_version} > 6

# Death to Fascist build policies
%define _unpackaged_files_terminate_build 0
%define _systemdsvcdir /usr/lib/systemd/system
%define craydir /opt/cray

%description
Provides a systemd service and associated library that reports
BOS' Boot Artifact ID for a node throughout its booted life.

%prep
%setup
%build

%install
%python_exec --version
# Upgrade install tools
%python_exec -m pip install --upgrade --user pip build setuptools wheel %(echo ${PIP_INSTALL_ARGS})
# Create our virtualenv
%python_exec -m venv %{buildroot}%{install_python_dir}

%{buildroot}%{install_python_dir}/bin/python3 -m pip install --upgrade %(echo ${PIP_INSTALL_ARGS}) pip
%{buildroot}%{install_python_dir}/bin/python3 -m pip install %(echo ${PIP_INSTALL_ARGS}) bos_reporter*.whl --disable-pip-version-check
%{buildroot}%{install_python_dir}/bin/python3 -m pip list --format freeze

mkdir -p %{buildroot}%{_systemdsvcdir}
install -m 644 etc/bos-reporter.service %{buildroot}%{_systemdsvcdir}/bos-reporter.service

# Add symlink in /opt/cray/csm/scripts/bos
install -d -m 755 %{buildroot}/opt/cray/csm/scripts/bos
pushd %{buildroot}/opt/cray/csm/scripts/bos
ln -s ../../../../..%{install_python_dir}/bin/bos_reporter bos_reporter
popd

# Remove build tools to decrease the virtualenv size.
%{buildroot}%{install_python_dir}/bin/python3 -m pip uninstall -y pip setuptools wheel

# Remove __pycache__ directories  to decrease the virtualenv size.
find %{buildroot}%{install_python_dir} -type d -name __pycache__ -exec rm -rvf {} \; -prune

# Fix the virtualenv activation script, ensure VIRTUAL_ENV points to the installed location on the system.
find %{buildroot}%{install_python_dir}/bin -type f | xargs -t -i sed -i 's:%{buildroot}%{install_python_dir}:%{install_python_dir}:g' {}

find %{buildroot}%{install_dir} | sed 's:'%{buildroot}'::' | tee -a INSTALLED_FILES
echo /opt/cray/csm/scripts/bos/bos_reporter | tee -a INSTALLED_FILES
echo /opt/cray/csm/scripts/bos | tee -a INSTALLED_FILES
echo %{_systemdsvcdir}/bos-reporter.service | tee -a INSTALLED_FILES
cat INSTALLED_FILES | xargs -i sh -c 'test -L %{buildroot}{} -o -f %{buildroot}{} && echo {} || echo %dir {}' | sort -u > FILES

%clean
rm -rf %{buildroot}

%files -f FILES
%license LICENSE

%pre
%if 0%{?suse_version}
%service_add_pre bos-reporter.service
%endif

%post
ln -f /opt/cray/cray-spire/spire-agent /usr/bin/bos-reporter-spire-agent
%if 0%{?suse_version}
%service_add_post bos-reporter.service
%else
%systemd_post bos-reporter.service
%endif

%preun
%if 0%{?suse_version}
%service_del_preun bos-reporter.service
%else
%systemd_preun bos-reporter.service
%endif

%postun
if [ $1 -eq 0 ];then
  rm -f /usr/bin/bos-reporter-spire-agent
fi
%if 0%{?suse_version}
%service_del_postun bos-reporter.service
%else
%systemd_postun_with_restart bos-reporter.service
%endif

%changelog
