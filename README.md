# homelab-openbao

OpenBao secrets manager deployed via ArgoCD.

## First-Time Initialization

After first deploy, the pod will be running but not ready. Navigate to `openbao.morrisons.site` to initialize.

1. Choose 1 key share and 1 key threshold (sufficient for a home lab)
2. Save the unseal key and root token somewhere safe (password manager)
3. Unseal using the unseal key
4. Log in with the root token

## After Every Pod Restart

OpenBao seals itself on restart. Navigate to `openbao.morrisons.site` and enter your unseal key to unseal it.

## One-Time Configuration (Manual)

These steps only need to be done once after initialization.

### Enable Kubernetes Auth Method

1. Go to **Access → Auth Methods → Enable new method**
2. Choose **Kubernetes**
3. Leave path as `kubernetes`, click **Enable Method**
4. Set Kubernetes host: `https://kubernetes.default.svc`
5. Click **Save**

### Create Alertmanager Policy

1. Go to **Policies → Create ACL policy**
2. Name: `alertmanager`
3. Policy:
```
path "homelab/data/alertmanager/*" {
  capabilities = ["read"]
}
```
4. Click **Create policy**

### Create Alertmanager Role

1. Go to **Access → Auth Methods → kubernetes → Create role**
2. Name: `alertmanager`
3. Bound service account names: `alertmanager`
4. Bound service account namespaces: `monitoring`
5. Expand the **Tokens** section → **Generated Token's Policies**: `alertmanager`
6. Click **Save**

## Secrets Structure

Secrets are stored under the `homelab` KV engine:

- `homelab/alertmanager/discord-webhook` — Discord webhook URL (key: `DISCORD_WEBHOOK_URL`)
