# homelab-openbao

[Homelab Docs](https://github.com/mattjmorrison/homelab/blob/main/docs/INDEX.md)

---

OpenBao secrets manager deployed via ArgoCD. This README covers the full secrets architecture for the homelab.

---

## How Secrets Work

```
OpenBao (openbao.morrisons.site)
  └── KV secrets engine mounted at: kv/
        └── homelab/alertmanager  (key: DISCORD_WEBHOOK_URL)

External Secrets Operator (external-secrets namespace)
  └── Watches for ExternalSecret resources in the cluster
  └── Authenticates with OpenBao using Kubernetes auth
  └── Fetches secrets and creates Kubernetes Secrets

App (e.g. Alertmanager in monitoring namespace)
  └── SecretStore — tells ESO how to connect to OpenBao
  └── ExternalSecret — tells ESO which secret to fetch
  └── Kubernetes Secret (auto-created by ESO) — used by the pod
```

**Flow:** App manifests define what secrets they need → ESO fetches them from OpenBao → ESO creates a Kubernetes Secret → the pod reads the Kubernetes Secret as an env var or volume.

---

## What Lives Where

| Repo | What it contains |
|---|---|
| `homelab-openbao` | OpenBao deployment (Helm values) |
| `homelab-external-secrets` | External Secrets Operator deployment (Helm values) |
| `homelab-external-secrets-crds` | SecretStore and ClusterSecretStore CRDs (too large for normal Helm install) |
| `homelab-apps` | ArgoCD Application manifests for all of the above |
| `homelab-<app>` | SecretStore, ExternalSecret, and ServiceAccount manifests for that app |

Secrets themselves are stored **only in OpenBao** — never in git.

---

## Adding a Secret for a New App

1. **Store the secret in OpenBao** — UI → Secrets → kv → create at path `homelab/<appname>`
2. **Create a policy in OpenBao** — Policies → Create ACL policy:
   ```
   path "kv/data/homelab/<appname>" {
     capabilities = ["read"]
   }
   ```
3. **Create a role in OpenBao** — Access → Auth Methods → kubernetes → Create role:
   - Name: `<appname>`
   - Bound service account names: `<appname>`
   - Bound service account namespaces: `<namespace>`
   - Tokens section → Generated Token's Policies: `<appname>`
4. **Add to the app's repo** (`homelab-<appname>/manifests/`):
   - `serviceaccount.yaml` — ServiceAccount for the app
   - `secret-store.yaml` — SecretStore pointing at OpenBao
   - `external-secret.yaml` — ExternalSecret mapping OpenBao secret → Kubernetes Secret
5. **Reference the Kubernetes Secret** in the app's Deployment/StatefulSet as an env var or volume

---

## First-Time Initialization

After first deploy, the pod will be running but not ready. Navigate to `openbao.morrisons.site` to initialize.

1. Choose 1 key share and 1 key threshold (sufficient for a home lab)
2. Save the unseal key and root token somewhere safe (password manager)
3. Unseal using the unseal key
4. Log in with the root token

## After Every Pod Restart

OpenBao seals itself on restart. Navigate to `openbao.morrisons.site` and enter your unseal key to unseal it.

---

## One-Time Configuration (Manual)

These steps only need to be done once after initialization.

### Enable KV Secrets Engine

1. Go to **Secrets → Enable new engine**
2. Choose **KV**
3. Leave version as **2** (default), set path to `kv`
4. Click **Enable Engine**

### Enable Kubernetes Auth Method

1. Go to **Access → Auth Methods → Enable new method**
2. Choose **Kubernetes**
3. Leave path as `kubernetes`, click **Enable Method**
4. Set Kubernetes host: `https://kubernetes.default.svc`
5. Click **Save**

---

## Current Secrets

| Path in OpenBao | Key | Used by | Kubernetes Secret name |
|---|---|---|---|
| `kv/homelab/alertmanager` | `DISCORD_WEBHOOK_URL` | Alertmanager | `alertmanager-discord` |
| `kv/homelab/argocd-notifications` | `DISCORD_WEBHOOK_URL` | ArgoCD Notifications | `argocd-notifications-secret` |

---

## Current Policies and Roles

| Policy | Path | Role | Service Account | Namespace |
|---|---|---|---|---|
| `alertmanager` | `kv/data/homelab/alertmanager` | `alertmanager` | `alertmanager` | `monitoring` |
| `argocd-notifications` | `kv/data/homelab/argocd-notifications` | `argocd-notifications` | `argocd-notifications-controller` | `argocd` |
