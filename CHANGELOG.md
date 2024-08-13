# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.22.0] 2024-05-28

### Changed

- Updated base to BigBang 2.27.0

## [1.21.0] 2024-04-09

### Changed

- Updated base to BigBang 2.24.0

## [1.20.0] 2024-04-05

### Changed

- Updated RKE2 to v1.29.3+rke2r1

## [1.19.0] 2024-03-25

### Changed

- Updated base to BigBang 2.23.0

## [1.18.0] 2024-03-11

### Changed

- Updated base to BigBang 2.22.0
- Fix typo & error in README

## [1.17.0] 2024-01-02

### Changed

- Updated base to BigBang 2.17.0

## [1.16.0] 2023-12-12

### Changed

- Updated base to BigBang 2.16.0

## [1.15.0] 2023-11-08

### Changed

- Updated base to BigBang 2.14.0

## [1.14.0] 2023-06-07

### Changed

- Updated base to BigBang 2.5.0

## [1.13.1] 2022-09-06

### Changed

- Updated base to BigBang 1.41.0
- Updated RKE2 to v1.23.10+rke2r1
- Increased control plane nodes to 3. ([Reference](https://etcd.io/docs/v3.5/faq/#why-an-odd-number-of-cluster-members))

## [1.13.0] 2022-08-18

### Added

- Added terraform for IAM Role and Policy
- Added terraform OS sysctl config for `fs.inotify`

### Changed

- Updated base to BigBang 1.39.0
- Converted default storage class to GP3 and updated documentation
- Updated RKE2 version to `1.23.9+rke2r1`
- Reduced terraform availability zones to 2
- Reduced RKE2 server and agent nodes to 2
- Converted terraform image to variable

### Removed

- Removed `GitRepository` patch for Big Bang version

## [1.12.0]

### Changed

- Updated base to BigBang 1.33.0
- Update Flux source API versions to `v1beta2`

## [1.11.0]

### Changed

- Changed from declaring an AMI to dynamically finding the latest ami id for CIS Amazon Linux 2 STIG
- Updated init_script in env.yaml to apply needed node configurations for the CIS STIG image
- Enabled rke2 download on node startup to allow for using CIS STIG image

## [1.10.0]

### Changed

- Updated base to BigBang release 1.31.0
- Updated all `dsop.io` references to `dso.mil`
- Corrected nodeport ingress instructions
- Updated aws elb command in terraform readme
- Updated RKE2 to latest terraform, which supports Terraform 4.x and Kubernetes 1.22

## [1.9.0]

### Changed

- Updated base to BigBang release 1.29.0
- Adjusted persistent size, memory, and cpu settings for dev overrides

## [1.8.0]

### Changed

- Updated base to BigBang release 1.27.1

## [1.7.0]

### Changed

- Updated base to BigBang release 1.26.0
- Updated all `Kustomization`s to API Version `v1beta2`

## [1.6.0]

### Changed

- Updated base to BigBang release 1.25.1
- Updated to latest dev cert

## [1.5.0]

### Changed

- Updated base to BigBang release 1.17.0
- `hostname` value to `domain` change

## [1.4.1]

### Changed

- Updated istio cert

## [1.4.0]

### Changed

- Updated base to BigBang release 1.15.2

## [1.3.0]

### Changed

- Updated default BigBang release to 1.12.0 in kustomization.
- Updated values for istio cert within `bigbang-dev-cert.yaml`

## [1.2.2]

### Added

- Added cSpell workspace configuration.
- Added Table of Contents

### Changed

- Formatted Terraform configurations to canonical format.
- Updated CONTRIBUTING to reflect forking process.
- Updated link to Kubernetes cluster prerequisites.
- Updated spelling and markdown formatting.
- Updates CODEOWNERS

## [1.2.1]

### Changed

- Moved TLS cert back out of configmap.yaml
- Updated documentation on how to add and update TLS certificates to encrypted secret.
- Fixed Big Bang version mismatch using semver in kustomization
- Fixed flux install instructions to use version rather than master.  New versions of flux may not be backwards compatible.
- Cleaned up dev values.yaml

## [1.2.0]

### Changed

- Fix namespace error (istio-system) when deploying wildcard-cert
- Updated expired certificate for *.dev.bigbang.mil
- Added default values for `istio.ingress.tls.*` to workaround Helm error on `nil` values.
- Updated [README.md](./README.md) for TLS cert
- Updated [README.md](./README.md) for sops key creation (Issue #8)
- Updated default BigBang release to 1.12.0 in kustomization.

## [1.1.1]

### Changed

- Security groups between internet facing network load balancer and agent's node ports updated to fix ingress

## [1.1.0]

### Added

- Upload of private SSH to encrypted S3 bucket
- Rename of `default` Kubernetes profile to environment name
- Change permissions of local Kubernetes config file to read/write of owner only

### Changed

- Migrated terraform classic load balancer to regular load balancer

## [1.0.1]

### Changed

- Terraform cache S3 bucket created off of name in environment

## [1.0.0]

### Added

- Base/shared configuration with ...
  - Big Bang version
  - Location of Big Bang base/chart
  - Iron Bank pull credentials placeholder
- Dev configuration with ...
  - Reduced polling interval
  - Minimized replicas for Gatekeeper
  - Minimized disk, cpu, and memory resources
  - Anonymous authorization for Kiali
  - Secrets placeholder
- Prod configuration with ...
  - Hostname placeholder
  - Secrets placeholder
- Basic documentation
  - [README.md](README.md)
  - [CHANGELOG.md](CHANGELOG.md)
  - [CODEOWNERS](CODEOWNERS)
  - [CONTRIBUTING.md](CONTRIBUTING.md)
- Terraform template for AWS with...
  - Multi-environment support
  - High-availability (cross-zone) and auto-scaling
  - Private and public subnets
  - Load balancer
  - Bastion server
