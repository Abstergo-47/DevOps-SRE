<div align="center">

# 🔐 DevSecOps & SRE Pipeline

**Secure CI/CD · GitOps delivery · Full-stack observability for a deliberately leaky microservice**

![Docker](https://img.shields.io/badge/Docker-Alpine-2496ED?logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)
![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?logo=argo&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Minikube-326CE5?logo=kubernetes&logoColor=white)
![Grafana](https://img.shields.io/badge/Observability-Prometheus_·_Grafana_·_Loki-F46800?logo=grafana&logoColor=white)

</div>

---

## 📖 What is this?

A small Python service that **leaks memory on purpose**. It starts near 100 MB and grows to about 500 MB in two
minutes, while writing normal application logs and serving `/healthcheck` on port 8080. It exists to prove that the
platform around it can ship, run, watch and alert on a misbehaving workload, using only free, local tooling.

```
 Pull Request ─► CI gates ─► merge ─► build & push 3 images ─► update image tags in Git
                                                                        │
                       ┌────────────────────────────────────────────────┘
                       ▼
                    ArgoCD ──► Kubernetes (Minikube) ──► v1 · v2 · v3 ──► shared Service
                                        │
                            Prometheus · Loki ──► Grafana ──► alerts
```

## ✨ Highlights

### 🛡️ Secure pipeline (GitHub Actions)

| Stage                 | Gate                                                                                                          |
| --------------------- | ------------------------------------------------------------------------------------------------------------- |
| **Pull request**      | flake8 lint · CodeQL SAST · pytest · image build + **Trivy** vulnerability scan for every image               |
| **Merge**             | Builds and pushes the three images to GHCR, then commits the new image tags back to Git                       |
| **Branch protection** | No direct pushes; the required checks must pass before a PR can merge ([guide](.github/branch-protection.md)) |

The `Dockerfile` uses a minimal Alpine base, runs as a **non-root user**, and strips pip/setuptools from the final
image (about 70–80 MB).

### 🚢 GitOps on Kubernetes

- **ArgoCD** watches `kubernetes/` and syncs automatically (prune + self-heal), so Git is the only way to change the cluster.
- **Three Deployments** (`v1`, `v2`, `v3` = Python 3.12 / 3.13 / 3.14) run side by side behind **one Service** that spreads traffic across them.
- Pods request `128Mi` and are limited to **`400Mi`**, so the leak ends in an `OOMKilled` restart long before it can hurt the node.
- Readiness and liveness probes use `/healthcheck`.
- Guard rails: a dedicated `app` **namespace**, default-deny **NetworkPolicies**, and a **ResourceQuota**.

### 📊 Observability and alerting

- **Prometheus + Grafana** (Helm) for metrics, **Loki + Alloy** for centralized logs.
- A custom **SRE dashboard** with node CPU / memory / disk, per-pod CPU and memory against the 400Mi limit, restarts and OOM counts, plus live application logs.
- **Grafana alerts**, provisioned as code:

| Alert                   | Fires when                                                                |
| ----------------------- | ------------------------------------------------------------------------- |
| `AppPodNotReady`        | a pod in `app` stays unready for 1 minute (failing health check)          |
| `AppContainerOOMKilled` | a container restarts after being killed by the OOM killer (exit code 137) |

## 🗂️ Repository layout

```
.
├── app/                 Python service (intentional memory leak)
├── test/                pytest unit tests
├── Dockerfile           minimal, non-root image
├── .github/workflows/   pull_request.yml (gates) · release.yml (build, push, tag update)
├── kubernetes/          namespace, 3 Deployments, Service, NetworkPolicies, ResourceQuota
├── argocd/              ArgoCD Application
└── observability/       Helm values (Prometheus/Grafana, Loki, Alloy) + Grafana dashboard
```

## 🚀 Quick start

Requires `docker`, `minikube`, `kubectl` and `helm`.

```bash
minikube start -p sre --cpus=6 --memory=7168 --cni=calico   # Calico enforces NetworkPolicies
```

Then install the observability stack, ArgoCD and the app by following **[SETUP.md](SETUP.md)**, which has the
copy-paste steps. Once everything is up:

```bash
kubectl -n monitoring port-forward svc/kps-grafana 3000:80   # http://localhost:3000  (admin / admin)
kubectl -n app get pods -w                                   # watch the pods get OOMKilled and restart
```

## 🧪 What to expect

About 90 seconds after a pod starts, it reaches the 400Mi limit and is `OOMKilled`. Kubernetes restarts it, the
`AppContainerOOMKilled` alert fires in Grafana, and the dashboard's memory panel shows the leak as a sawtooth line.
If the pod stays down long enough, `AppPodNotReady` fires as well.

---

<div align="center"><sub>Built with free and open-source tools only. No cloud accounts required.</sub></div>
