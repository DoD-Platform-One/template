# Big Bang Customer Template

> _This is a mirror of a government repo hosted on [Repo1](https://repo1.dso.mil/) by [DoD Platform One](http://p1.dso.mil/). Please direct all code changes, issues and comments to <https://repo1.dso.mil/platform-one/big-bang/customers/template>_

This repository provides a template for managing your Big Bang configurations using Kustomize and GitOps principles with FluxCD. It helps isolate your custom configuration from the core Big Bang product, allowing for easier upgrades and better change management.

If you are new to Big Bang, it is recommended you start with the [Big Bang Quickstart Guide](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/guides/deployment-scenarios/quickstart.md) before customizing this template.

## Prerequisites

Before using this template, ensure you have:

*   A Kubernetes cluster [ready for Big Bang](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/master/docs/guides/prerequisites).
*   `kubectl` installed and configured to access your cluster.
*   `git` installed.
*   `gpg` installed for SOPS encryption.
*   `sops` installed for managing secrets. See [SOPS Installation Guide](https://github.com/mozilla/sops#installation).
*   An account on [Repo1](https://repo1.dso.mil) with a Personal Access Token (PAT) with `read_repository` scope.
*   Credentials for [Iron Bank](https://registry1.dso.mil) (Username and PAT/CLI Secret).

## Core Concepts

*   **Kustomize:** This template uses Kustomize to manage Kubernetes configurations. It employs a base/overlay structure where common settings reside in `base/` and environment-specific configurations are placed in overlay directories (e.g., `dev/`, `prod/`).
*   **GitOps:** All configuration is stored in your Git repository. FluxCD runs in your cluster, monitors your repository, and automatically applies changes.
*   **Structure:**
    *   `base/`: Common Kustomize resources, configurations (`configmap.yaml`), and encrypted secrets (`secrets.enc.yaml`) shared across all environments.
    *   `package-strategy/` & `umbrella-strategy/`: Example environment overlays demonstrating different update strategies. You will copy one of these to create your own environment directory (e.g., `dev`).
*   **Update Strategies:** This template provides examples for two common strategies:
    *   **Package Strategy (`package-strategy/`):** Prioritizes updating individual applications as soon as new versions are released by Big Bang. This allows for faster adoption of patches and features but involves more frequent, smaller updates. Can be automated with tools like Renovate.
    *   **Umbrella Strategy (`umbrella-strategy/`):** Updates all applications based on new official Big Bang releases. This ensures applications are tested together by the Big Bang team but means updates are larger and less frequent.

### Git Repository Best Practices

- If you plan to deploy clusters to multiple impact levels, then you should follow these best practices:
  - Have at least one unique git repository for each impact level where a cluster will be deployed to.
  - Match the IL where the git repository will be hosted to the impact level where the corresponding cluster will be hosted.
    - Example:
      The git repository corresponding to an IL4 Cluster Deployment should be hosted on an IL4 approved hosting environment.
      The Infrastructure as code for an IL4 Cluster Deployment shouldn't be hosted on an IL2 git repository.
    - The reason for this is that:
      - Infrastructure as code secrets corresponding to a cluster deployed to IL4 (or IL5), would be considered CUI (Controlled Unclassified Information), and thus should be isolated from IL2.
      - Even though both IL2 and IL4 secrets would be encrypted, it's still best practice to keep them in separate repositories, because when server side git hooks are not in place, then it's possible for human error to result in a non-encrypted secrets being committed to a git repository.
      - Any encrypted infrastructure as code secrets added to /base, would get shared by all clusters, if multiple impact levels existed in the same repo, then secrets added to /base could accidentally end up being shared across impact levels.
- The intent of the /base folder is to allow configuration and in some cases secrets to be shared between clusters.
  - Examples of how to properly use /base to share a secret between clusters in the same impact level.
    - If you have several developer sandbox, development, and test clusters operating at IL2, you may wish to have some level of shared configuration between them.
    - If you have a production and acceptance environment for an IL4 cluster, you may wish for them to share an image pull secret between them.
- It's worth mentioning that while the above best practices are applicable to the majority of scenarios, Authorizing Officials(AOs) can always choose to make exceptions and accept risks if necessary to meet the needs of unique mission requirements, and the presence of a Cross Domain Solution could also result in nuances.

## Getting Started

Follow these steps to configure your own Big Bang environment using this template.

1.  **Create Your Repository:**
    *   **Fork** this template repository into your private Git provider (e.g., GitLab, GitHub). **Do not use this template directly.**
    *   Clone your forked repository locally:
        ```bash
        git clone <your-fork-repo-url>
        cd <your-repo-name>
        ```
    *   Create a working branch for your configuration changes:
        ```bash
        git checkout -b template-demo
        ```

2.  **Choose Strategy & Create Environment:**
    *   Decide whether you want to start with the `package-strategy` or `umbrella-strategy`.
    *   Copy the chosen strategy directory to create your first environment (e.g., `dev`):
        ```bash
        # Example using package-strategy for a 'dev' environment
        cp -r package-strategy/ dev
        ```
    *   Update the paths within the copied `dev/bigbang.yaml` file to reference `./dev` instead of the original strategy path. This tells Flux where to find the Kustomization root for this environment within your repository.
        ```bash
        # On Linux:
        sed -i 's|./package-strategy|./dev|g' dev/bigbang.yaml
        # On macOS (requires gsed, install via 'brew install gnu-sed'):
        # gsed -i 's|./package-strategy|./dev|g' dev/bigbang.yaml
        ```
    *   *(Repeat this step for other environments like `prod`, perhaps using `umbrella-strategy`)*

3.  **Configure Secrets (SOPS):**
    *   **Generate GPG Key:** If you don't have one, generate a GPG key pair. This key will be used by SOPS to encrypt your secrets. See [SOPS GPG Guide](https://fluxcd.io/flux/guides/mozilla-sops/#generating-a-gpg-key).
    *   **Update `.sops.yaml`:** Add your GPG key's fingerprint to the `.sops.yaml` file in the root of your repository. This tells SOPS which key to use for encryption/decryption.
        ```bash
        export GPG_FP="YOUR_KEY_FINGERPRINT" # Get this via 'gpg --list-keys'
        # On Linux:
        sed -i "s/pgp: FALSE_KEY_HERE/pgp: ${GPG_FP}/" .sops.yaml
        # On macOS:
        # gsed -i "s/pgp: FALSE_KEY_HERE/pgp: ${GPG_FP}/" .sops.yaml

        git add .sops.yaml
        git commit -m "chore: configure SOPS GPG key fingerprint"
        ```
    *   **Encrypt Initial Secrets:**
        *   This template includes a demo TLS certificate (`base/bigbang-dev-cert.yaml`) for the default domain `dev.bigbang.mil`. Encrypt this file into `base/secrets.enc.yaml`:
            ```bash
            sops --encrypt base/bigbang-dev-cert.yaml > base/secrets.enc.yaml
            ```
        *   **Add Your Secrets:** Edit the newly created `base/secrets.enc.yaml` to add essential secrets like your Iron Bank pull credentials. Use the `sops` command, which will open the file in your default editor:
            ```bash
            sops base/secrets.enc.yaml
            ```
        *   Inside the editor, add your secrets under the `stringData: "values.yaml"` key. Ensure the structure matches what Big Bang expects. The secret resource name should be `common-bb` for base secrets.
            ```yaml
            # Example structure within base/secrets.enc.yaml
            apiVersion: v1
            kind: Secret
            metadata:
              name: common-bb # Use 'environment-bb' for environment-specific secrets
            stringData:
              values.yaml: |-
                # Add your Iron Bank credentials here
                registryCredentials:
                - registry: registry1.dso.mil
                  username: your-iron-bank-username
                  password: your-iron-bank-pat-or-cli-secret

                # Add other required secret values below
                # Example: Istio CA certificates if not using cert-manager
                # istio:
                #   values:
                #     cacerts:
                #     - secretName: cacerts
                #       certFile: |
                #         -----BEGIN CERTIFICATE-----
                #         ...
                #         -----END CERTIFICATE-----
                #       keyFile: |
                #         -----BEGIN PRIVATE KEY-----
                #         ...
                #         -----END PRIVATE KEY-----
                #       rootFile: |
                #         -----BEGIN CERTIFICATE-----
                #         ...
                #         -----END CERTIFICATE-----

              # --- Existing content from bigbang-dev-cert.yaml below ---
              # (Ensure this section remains if you keep the demo cert initially)
              istio:
                gateways:
                  public:
                    tls:
                      key: |
                        -----BEGIN PRIVATE KEY-----
                        ... demo key ...
                        -----END PRIVATE KEY-----
                      cert: |
                        -----BEGIN CERTIFICATE-----
                        ... demo cert ...
                        -----END CERTIFICATE-----
            ```
        *   Save and close the editor. SOPS will automatically re-encrypt the file.
    *   **Commit Encrypted Secrets:**
        ```bash
        git add base/secrets.enc.yaml
        # Optional: Remove the unencrypted demo cert if you added your own TLS secrets
        # git rm base/bigbang-dev-cert.yaml
        git commit -m "feat: add initial encrypted secrets (Iron Bank creds, demo TLS)"
        ```
    *   **Important Security Note:** The demo TLS certificate (`base/bigbang-dev-cert.yaml`) and its private key are public. **Do not use it for production or sensitive environments.** Replace it with your own certificate/key (added to `base/secrets.enc.yaml` or an environment-specific `secrets.enc.yaml`) or configure `cert-manager` via `configmap.yaml` values.

4.  **Configure Git Repository Source (Flux):**
    *   Edit the `bigbang.yaml` file within your chosen environment directory (e.g., `dev/bigbang.yaml`).
    *   Update `spec.url` to your **forked repository's HTTPS URL**.
    *   Update `spec.ref.branch` to the name of the **working branch** you created (e.g., `template-demo`).
        ```yaml
        # Example snippet from dev/bigbang.yaml
        apiVersion: source.toolkit.fluxcd.io/v1
        kind: GitRepository
        metadata:
          name: environment-repo # Name for the Flux GitRepository object
          namespace: bigbang
        spec:
          interval: 1m
          url: https://your-private-repo-domain/your-org/your-repo-name.git # <-- UPDATE THIS
          ref:
            branch: template-demo # <-- UPDATE THIS
          secretRef:
            name: private-git # Matches the secret created during deployment
        ---
        apiVersion: kustomize.toolkit.fluxcd.io/v1
        kind: Kustomization
        metadata:
          name: environment # Name for the Flux Kustomization object
          namespace: bigbang
        spec:
          interval: 5m
          path: ./dev # <-- Path within your repo (should match the directory)
          prune: true
          sourceRef:
            kind: GitRepository
            name: environment-repo # Must match the GitRepository name above
          decryption:
            provider: sops
            secretRef:
              name: sops-gpg # Matches the secret containing the GPG private key
        ```
    *   Commit the change:
        ```bash
        git add dev/bigbang.yaml
        git commit -m "chore: configure flux git source for dev environment"
        git push --set-upstream origin template-demo
        ```

## Deployment

These steps deploy FluxCD to your cluster and configure it to manage your Big Bang environment based on your Git repository.

1.  **Prerequisites:** Ensure `kubectl` is configured to communicate with your target Kubernetes cluster.
2.  **Deploy Flux Controllers:**
    *   Apply the Flux manifests from the Big Bang repository. **Replace `X.Y.Z`** with the specific Big Bang version tag that matches the version referenced in your `base/kustomization.yaml`.
        ```bash
        # Find the version ref in base/kustomization.yaml (e.g., ?ref=2.50.0)
        BB_VERSION="X.Y.Z" # Example: BB_VERSION="2.50.0"
        kubectl apply -k "https://repo1.dso.mil/platform-one/big-bang/bigbang.git//base/flux?ref=${BB_VERSION}"
        ```
    *   Wait for the Flux controllers to become ready:
        ```bash
        kubectl wait deployment --all --for condition=Available -n flux-system --timeout=5m
        ```
3.  **Deploy Secrets to Cluster:**
    *   Create the `bigbang` namespace (Flux usually creates `flux-system`):
        ```bash
        kubectl create ns bigbang --dry-run=client -o yaml | kubectl apply -f -
        ```
    *   **SOPS GPG Private Key:** Flux needs your GPG private key to decrypt secrets from your Git repository.
        ```bash
        # Ensure GPG_FP is set to your key fingerprint
        export GPG_FP="YOUR_KEY_FINGERPRINT"
        gpg --export-secret-key --armor "${GPG_FP}" | kubectl create secret generic sops-gpg -n bigbang --from-file=bigbangkey.asc=/dev/stdin
        ```
    *   **Git Credentials:** Flux needs credentials to clone your private Git repository. Use your private git username and a PAT with `read_repository` scope.
        ```bash
         kubectl create secret generic private-git -n bigbang \
           --from-literal=username=<your-private-repo-username> \
           --from-literal=password=<your-private-repo-pat>
        ```
    *   **Image Pull Credentials (Flux):** Flux controllers need credentials to pull their own images from Iron Bank.
        ```bash
         kubectl create secret docker-registry private-registry -n flux-system \
           --docker-server=registry1.dso.mil \
           --docker-username=<your-iron-bank-username> \
           --docker-password=<your-iron-bank-pat-or-cli-secret>
        ```
    *   **Optional: Image Pull Credentials (Big Bang OCI Chart):** If you configure Big Bang to deploy from the OCI Helm chart instead of Git (see Advanced section), Flux needs credentials in the `bigbang` namespace too.
        ```bash
        # Only needed if using HelmRepository source for the main Big Bang chart
        # kubectl create secret docker-registry private-registry -n bigbang \
        #   --docker-server=registry1.dso.mil \
        #   --docker-username=<your-iron-bank-username> \
        #   --docker-password=<your-iron-bank-pat-or-cli-secret>
        ```

4.  **Deploy Big Bang Environment Configuration:**
    *   Apply the `bigbang.yaml` file corresponding to the environment you want to deploy (e.g., `dev`). This creates the Flux `GitRepository` and `Kustomization` resources in the cluster.
        ```bash
        kubectl apply -f dev/bigbang.yaml
        ```

5.  **Monitor Deployment:**
    *   Flux will now detect the `GitRepository` and `Kustomization` resources, clone your repository, decrypt secrets using the `sops-gpg` secret, run Kustomize build on the specified path (`./dev`), and apply the resulting manifests (including the main Big Bang HelmRelease).
    *   Check the status of Flux resources:
        ```bash
        # Check if Flux can clone your repo and process the kustomization
        kubectl get gitrepositories,kustomizations -n bigbang
        # Wait for the Kustomization to report Ready status
        kubectl wait kustomization/environment -n bigbang --for=condition=Ready --timeout=15m
        ```
    *   Check the status of the Big Bang HelmRelease and its deployed packages:
        ```bash
        kubectl get helmreleases -n bigbang
        # Look for errors or progress
        kubectl describe helmrelease bigbang -n bigbang
        # Check pods across relevant namespaces (bigbang, flux-system, istio-system, etc.)
        kubectl get pods -A -w
        ```
    *   Troubleshooting: Use `kubectl logs -n flux-system deploy/source-controller` or `kustomize-controller` for Flux issues. Use `kubectl describe` on failing HelmReleases or Pods.

## Customization (Kustomize Workflow)

Modify your Big Bang deployment by making changes in your Git repository. Flux will automatically apply them.

*   **Modify Values:** Edit the `configmap.yaml` file in your environment overlay (e.g., `dev/configmap.yaml`) to change non-secret configurations like the domain, resource limits, or package-specific settings. Commit the changes to Git.
*   **Modify Secrets:** Edit the encrypted `secrets.enc.yaml` files (in `base/` or your environment directory) using `sops <filename>`. Commit the changes. Environment secrets (`environment-bb`) typically override base secrets (`common-bb`) if keys conflict within the `values.yaml` structure.
*   **Enable/Disable Packages:** Most core Big Bang packages are enabled or disabled via boolean flags within the `values.yaml` structure in `configmap.yaml` (for non-secrets) or `secrets.enc.yaml` (if the package block contains secrets). For example, to enable Keycloak:
    ```yaml
    # In dev/configmap.yaml under stringData: "values.yaml":
    keycloak:
      enabled: true
    ```
    Refer to the Big Bang Package documentation for specific values.
*   **Add Custom Resources/Patches:**
    *   To add plain Kubernetes manifests (e.g., a ConfigMap, a Secret *not* managed by SOPS), add the YAML file to your environment directory (e.g., `dev/my-configmap.yaml`) and list it under the `resources:` section in your environment's `kustomization.yaml` (e.g., `dev/kustomization.yaml`).
    *   To apply Kustomize patches (e.g., modifying a resource deployed by Big Bang), define the patch in a file and add it to the `patchesStrategicMerge:` or `patches:` section in `dev/kustomization.yaml`.
*   **Update Big Bang Version:**
    1.  **Update Base Reference:** In `base/kustomization.yaml`, change the `?ref=X.Y.Z` tag in the `bases:` URL pointing to the Big Bang repository to the desired new version tag.
        ```yaml
        # In base/kustomization.yaml
        bases:
        # Update the tag here VVVVVVV
        - https://repo1.dso.mil/platform-one/big-bang/bigbang.git//base?ref=NEW_VERSION_TAG
        # ... other bases ...
        ```
    2.  **(If using OCI Source):** If you have configured Big Bang to deploy via OCI HelmRepository (see Advanced), update the `spec.chart.spec.version` in the HelmRelease patch within `base/kustomization.yaml`.
    3.  **Update Flux Controllers:** When upgrading Big Bang significantly, you might also need to update the Flux controllers themselves by re-running the `kubectl apply -k ...` command from the Deployment section, pointing to the new Big Bang version tag.
    4.  Commit changes to Git. Flux will apply the updated base and reconcile the HelmRelease.

## Advanced Configuration

*   **OCI Helm Chart Source & Cosign Verification:**
    Instead of referencing Big Bang's base manifests via Git in `base/kustomization.yaml`, you can configure Flux to pull the official Big Bang Helm chart directly from the OCI registry (`registry1.dso.mil`) and verify its signature using Cosign.
    1.  Add `helmrepo.yaml` and `cosignsecret.yaml` from the `base/` directory to the `resources:` list in `base/kustomization.yaml`. These define the `HelmRepository` source and the `Secret` containing the Cosign public key.
        ```yaml
        # In base/kustomization.yaml
        resources:
        - helmrepo.yaml
        - cosignsecret.yaml
        # ... other resources ...

        # Remove the Big Bang git base from the 'bases:' list if using OCI exclusively
        # bases:
        # - https://repo1.dso.mil/platform-one/big-bang/bigbang.git//base?ref=X.Y.Z # <-- REMOVE THIS LINE
        ```
    2.  Apply a patch in `base/kustomization.yaml` to modify the main `bigbang` HelmRelease to use the `HelmRepository` source and enable verification.
        ```yaml
        # In base/kustomization.yaml
        patchesStrategicMerge:
        # Enable this patch to use OCI HelmRepo with Cosign Verify
        - |-
          apiVersion: helm.toolkit.fluxcd.io/v2beta2
          kind: HelmRelease
          metadata:
            name: bigbang
            namespace: bigbang
          spec:
            chart:
              spec:
                # chart: bigbang # Chart name defined in HelmRepository
                version: X.Y.Z # <-- Set specific chart version
                sourceRef:
                  kind: HelmRepository
                  name: registry1 # Matches name in base/helmrepo.yaml
                  namespace: bigbang # HelmRepository is cluster-scoped, but Flux checks namespace
                verify:
                  provider: cosign
                  secretRef:
                    name: bigbang-cosign-pub # Matches name in base/cosignsecret.yaml
        ```
    3.  Ensure you create the `private-registry` secret in the `bigbang` namespace during deployment (Step 3 of Deployment) so Flux can pull the OCI chart.
    4.  You may need to adjust package `sourceType` values in your `configmap.yaml` if individual packages also need to switch source.

*   **Airgap/Self-Signed Git CA:**
    If your Git repository uses HTTPS with a certificate signed by a custom Certificate Authority (CA), you need to provide the CA certificate to Flux.
    1.  Create a secret containing the CA certificate (and optionally, Git credentials if not using the `private-git` secret). Example structure:
        ```yaml
        # Example: my-environment/git-ca-secret.yaml
        apiVersion: v1
        kind: Secret
        metadata:
          name: git-ca-certs
          namespace: bigbang # Must be in the same namespace as the GitRepository
        stringData:
          ca.crt: |
            -----BEGIN CERTIFICATE-----
            YOUR-CUSTOM-CA-CERT-PEM
            -----END CERTIFICATE-----
          # Optional: Add username/password if needed for this specific repo
          # username: git-user
          # password: git-password
        ```
    2.  Encrypt this secret using SOPS: `sops -e -i my-environment/git-ca-secret.yaml`
    3.  Add the encrypted file to your environment's `kustomization.yaml` resources list.
    4.  Modify the Flux `GitRepository` definition in `my-environment/bigbang.yaml` to reference this secret:
        ```yaml
        # In my-environment/bigbang.yaml
        apiVersion: source.toolkit.fluxcd.io/v1
        kind: GitRepository
        metadata:
          name: environment-repo
          namespace: bigbang
        spec:
          # ... url, ref ...
          secretRef:
            name: private-git # Still use this for standard auth if needed
          verify: # Add this section
            mode: tls
            secretRef:
              name: git-ca-certs # Reference the secret with the CA cert
        ```

## Multi-Environment Workflow

This template is designed to support multiple deployment environments (e.g., `dev`, `staging`, `prod`) from a single configuration repository.

*   **Shared Configuration:** Place common Kustomize resources, ConfigMaps (`base/configmap.yaml`), and SOPS-encrypted secrets (`base/secrets.enc.yaml`) in the `base/` directory. These are included by all environment overlays by default.
*   **Environment Overlays:** Create a separate directory for each environment (e.g., `dev`, `prod`). Copy a strategy template (`package-strategy` or `umbrella-strategy`) as a starting point.
    *   Each environment directory has its own `kustomization.yaml` that includes `../../base` and adds environment-specific resources, patches, or configurations.
    *   Each environment has its own `bigbang.yaml` file defining the Flux `GitRepository` and `Kustomization` resources specific to that environment (pointing to the correct path like `./dev` or `./prod`). Deploy the appropriate `bigbang.yaml` to the cluster to manage that environment.
*   **Environment-Specific Values:** Add a `configmap.yaml` and/or `secrets.enc.yaml` (use metadata name `environment-bb`) to the environment directory (e.g., `dev/configmap.yaml`) to provide or override values specific to that environment. Kustomize merges these with the base configurations.

## Adddional SOPS Notes and Advanced Configuration
- `Sops Note`: [Sops isn't guaranteed to preserve the yaml formatting of a file it encrypts](https://github.com/mozilla/sops/issues/864)
- `Sops Note`: sops is an abstraction layer that allows several secret backends to be used.
  - AGE and GPG (also known as PGP) are generic cloud agnostic options that have no dependencies. It's important to note that while [the sops repo recommends AGE over PGP](https://github.com/mozilla/sops#22encrypting-using-age), For DoD use cases it's preferable to use GPG, because GPG offers NIST approved crypto algorithms. (AGE is just as secure as GPG; however, AGE's crypto algorithms, X25519 and ChaCha20-Poly1305 are not NIST approved algorithms ([X25519](https://en.wikipedia.org/wiki/Curve25519) is used to generate asymmetric key pairs and [ChaCha20-Poly1305](https://en.wikipedia.org/wiki/ChaCha20-Poly1305) is a symmetric encryption algorithm. The example above has GPG leverage RSA 4096 and AES 256 which are both NIST approved)
  - GPG backed sops is shown as an example above, because it's generic and cloud agnostic.
  - If possible Cloud Service Provider based Key Management Service based solutions like AWS KMS, GCP KMS, and Azure Key Vault should be preferred over GPG, for the following reasons:
    - CSP KMS solutions are FIPS 140-2 approved
    - KMS solutions leverage identity based decryption, since the service never exposes the key and does encryption / decryption operations on behalf of users, the decryption key can't leak.
    - Identity based decryption means you can protect access to decryption rights using RBAC, and you can revoke access to the ability to decrypt data.
    - CSP KMS solutions have easy to satisfy dependencies
  - Hashicorp Vault is also a good option; however, it's worth pointing out that:
    - Using Vault means introducing Vault as a dependency, and standing up a production grade instance of Vault requires a good amount of work.
    - If a FIPS 140-2 compliant instance of Vault is needed, then Vault would need to be backed by an HSM, and that requires a Vault Enterprise License.
  - If you want to leverage a KMS based solution, you'll need to update `.sops.yaml` based on the following links:
    - [AWS KMS](https://github.com/mozilla/sops#27kms-aws-profiles)
    - [GCP KMS](https://github.com/mozilla/sops#23encrypting-using-gcp-kms)
    - [Azure Key Vault](https://github.com/mozilla/sops#24encrypting-using-azure-key-vault)
    - [Hashicorp Vault](https://github.com/mozilla/sops#25encrypting-using-hashicorp-vault)

## Renovate Bot

As documented in Big Bang, optimally the repository that maintains your GitOps state (this template) is being monitored by a tool such as Renovate to provide alerting and automation around updates for Big Bang and packages.

The [Renovate configuration](./renovate.json) in this repository provides an example that will target Repo1 git repositories for both individual packages as well the Big Bang umbrella chart and provide automated merge requests for updates. If following the `package-strategy` for consuming updates, Renovate will open pull/merge-requests on a per-package basis.

The [Renovate Deployment](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/guides/renovate/deployment.md) documentation supports deploying Renovate on a Big Bang cluster that can monitor both this template as well as dependencies in other repositories as a generic capability.

Once an environment directory has been created from a given strategy directory, the strategy directories can be omitted from renovate update by adding an `ignorePaths` option to the `renovate.json`:

```json
"ignorePaths": ["package-strategy/**", "umbrella-strategy"],
```

## Further Reading

*   [Big Bang Documentation](https://repo1.dso.mil/big-bang/bigbang/-/tree/master/docs)
*   [FluxCD Documentation](https://fluxcd.io/flux/)
*   [Kustomize Documentation](https://kustomize.io/)
*   [SOPS Documentation](https://github.com/mozilla/sops)
