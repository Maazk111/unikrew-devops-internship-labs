# 🚀 UniKrew DevOps Internship — Hands-on Lab Series (Tasks 01 → 05)

## 📘 Internship Overview

This repository documents my **DevOps Internship Journey** at UniKrew Solutions, showcasing a complete, end-to-end progression through **automation, containerization, CI/CD, orchestration, ingress, and cloud-native storage**.

Each lab environment was fully automated using **Vagrant + Bash provisioning**, simulating real-world enterprise setups — from **air-gapped runtime environments** to **multi-node Kubernetes clusters**, **Rancher management**, and **Kong API gateway integration**.

Through this internship, I gained practical experience in:

- Designing **air-gapped infrastructures** for secure offline image management.
- Building **CI/CD pipelines** integrating Jenkins, GitLab, and artifact repositories.
- Deploying **multi-node Kubernetes clusters** with **Calico CNI** and **Ingress controllers**.
- Managing clusters with **Rancher UI**, and exposing services through **Kong Gateway**.
- Configuring **object storage solutions** like MinIO with persistent volumes.

> 🧠 This experience strengthened my expertise in **infrastructure automation, container networking, declarative provisioning, and real-world DevOps workflows**.

---

## 🧱 Architecture Summary

| 🧩 Task | 🎯 Focus Area                | 🛠️ Core Technologies                                              | 📁 Repo / Folder                 |
| ------- | ---------------------------- | ----------------------------------------------------------------- | -------------------------------- |
| Task-01 | Containerd Air-Gap Lab       | Vagrant • Containerd • Offline Image Sync • Systemd Automation    | unikrew-task01-containerd-airgap |
| Task-02 | Jenkins + GitLab Integration | Multi-VM CI/CD • Maven Build • SCM Trigger • Artifacts            | unikrew-task02-jenkins-gitlab    |
| Task-03 | Kubernetes + NGINX Ingress   | Kubeadm Cluster • Calico CNI • Ingress Controller • ConfigMap     | unikrew-task03-kubernetes-nginx  |
| Task-04 | Rancher + Kong Gateway       | K3s Cluster • Rancher Mgmt • Traefik • Kong API Gateway (DB-less) | unikrew-task04-rancher-kong      |
| Task-05 | MinIO Object Storage         | S3-Compatible Storage • Persistence • mc Client Automation        | unikrew-task05-minio-storage     |

---

## 🧩 Task Highlights

### 1️⃣ Containerd Air-Gap Environment

- Designed a **two-node lab** to simulate **offline image transfer** using `ctr import/export`.
- Focused on secure container lifecycle in **restricted or isolated networks**.
- Automated the entire process via Vagrant provisioning.

### 2️⃣ Jenkins + GitLab Integration

- Configured **multi-VM CI/CD pipeline** using Jenkins and GitLab.
- Implemented **SCM webhooks** and automated **Maven builds** on code push.
- Generated build artifacts and integrated with notification stages.

### 3️⃣ Kubernetes + NGINX Ingress

- Built a **two-node Kubernetes cluster** via `kubeadm`.
- Deployed **Calico CNI** for networking and **Ingress Controller** for routing.
- Served a static NGINX page via domain `nginx.local`.

### 4️⃣ Rancher + Kong Gateway Integration

- Provisioned a **3-node K3s cluster** with **Rancher UI (TLS enabled)**.
- Added a **dedicated Kong Gateway VM (DB-less mode)** connected via private network.
- Implemented **DNS-based routing** and **Rancher UI exposure** through Kong.
- Combined cluster management (Rancher) with API management (Kong).

### 5️⃣ MinIO Object Storage

- Automated deployment of **MinIO server + client** on Ubuntu 22.04.
- Configured persistent volume (`/mnt/data`) and predefined `mc` alias.
- Created test bucket **devops-lab** and verified uploads via CLI and web console.

---

## 🧠 Skills and Technologies Demonstrated

| Category                    | Stack / Concepts                                  |
| --------------------------- | ------------------------------------------------- |
| Provisioning & Automation   | Vagrant • Bash Scripting • IaC Concepts           |
| CI/CD & DevOps Tools        | Jenkins • GitLab CI/CD                            |
| Containers & Orchestration  | Docker • Containerd • Kubernetes • K3s            |
| Networking & Ingress        | Calico • Traefik • Ingress Routing • Kong Gateway |
| Storage & Cloud Integration | MinIO • S3 API • Persistent Volumes               |
| Management & Monitoring     | Rancher • kubectl • Systemd Units                 |

---

## ⚙️ General Setup Workflow

```bash
# 1️⃣ Clone specific task repository
git clone https://github.com/MaazK111/unikrew-task03-kubernetes-nginx.git
cd unikrew-task03-kubernetes-nginx

# 2️⃣ Start lab environment
vagrant up

# 3️⃣ Verify services
kubectl get nodes
docker ps

# 4️⃣ Destroy after testing
vagrant destroy -f
```

---

## 🧾 Reflection

This internship reinforced my ability to **design, automate, and manage DevOps pipelines from scratch** — covering build, deploy, orchestration, and storage layers.  
Each task was developed as a **mini production lab** with repeatable Vagrant provisioning scripts and comprehensive documentation.

> 🏆 **“Automation without clarity is chaos — this internship proved the power of structured DevOps.”**
