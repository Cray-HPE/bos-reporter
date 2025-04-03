# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.3.3] - 2025/04/03

### Added

- Resume building RPMs for Python 3.6 and 3.9

### Changed

- Updated `pyproject.toml` to explicitly list Python 3.13 support
- Refactored Jenkinsfile to reduce size of main pipeline, to work around Jenkins limitation on its total size

### Dependencies

- Bump `dangoslen/dependabot-changelog-helper` from 3 to 4 ([#2](https://github.com/Cray-HPE/bos-reporter/pull/2))
- Bump `tj-actions/changed-files` from 45 to 46 ([#8](https://github.com/Cray-HPE/bos-reporter/pull/8))
- Bump `dangoslen/dependabot-changelog-helper` from 3 to 4 ([#2](https://github.com/Cray-HPE/bos-reporter/pull/2))

## [3.3.2] - 2025/03/06

### Added

- Build RPMs for SLES SP7
- Build RPMs for python 3.13

### Removed

- No longer build RPMs for Python 3.6 and 3.9

## [3.3.1] - 2025/02/07

### Changed

- Simplify RPM build process

## [3.3.0] - 2025/01/14

### Changed

- Build Python RPMs by SLES version

## [3.2.0] - 2025/01/13

### Changed

- Build RPMs for `x86_64` and `aarch64`
- Add Python 3.12

## [3.1.0] - 2024/11/01

### Changed

- Incorporated `bos-utils` package into `bos-reporter`.

## [3.0.0] - 2024/10/27

### Added

- Initial checkin; ported over from https://github.com/Cray-HPE/bos
