# 🚀 UniKrew DevOps Internship — Hands-on Lab Series (Tasks 01 → 07)

## 📘 Internship Overview

This repository documents my **DevOps Internship Journey at UniKrew Solutions**, showcasing an end-to-end progression through **automation, containerization, CI/CD, orchestration, ingress, storage, database replication, and communication systems**.

Each lab environment is automated using **Vagrant + Bash**, simulating **real-world enterprise setups** — from **air-gapped infrastructures** to **multi-node Kubernetes clusters**, **API gateways**, and **secure Jitsi deployments**.

---


## 💡 Practical Experience Gained
- Designing **air-gapped infrastructures** for secure offline image management.
- Building **CI/CD pipelines** integrating Jenkins, GitLab, and artifact repositories.
- Deploying **multi-node Kubernetes clusters** with Calico CNI + Ingress controllers.
- Managing clusters via **Rancher UI** and exposing services through **Kong Gateway**.
- Configuring **object storage (MinIO + S3 compatibility)**.
- Implementing **MongoDB Replica Sets** for high availability and resilience.
- Hosting **Jitsi Meet video-conferencing stack** using Docker Compose automation.
---

## 🧱 Architecture Summary
| 🧩 Task | 🎯 Focus Area | 🛠️ Core Technologies | 📁 Repo / Folder |
|----------|---------------|----------------------|------------------|
| Task-01 | Containerd Air-Gap Lab | Vagrant • Containerd • Offline Image Sync • Systemd | unikrew-task01-containerd-airgap |
| Task-02 | Jenkins + GitLab Integration | Multi-VM CI/CD • Maven Build • SCM Trigger • Artifacts | unikrew-task02-jenkins-gitlab |
| Task-03 | Kubernetes + NGINX Ingress | Kubeadm Cluster • Calico CNI • Ingress Controller | unikrew-task03-kubernetes-nginx |
| Task-04 | Rancher + Kong Gateway | K3s Cluster • Rancher UI • Kong API Gateway (DB-less) | unikrew-task04-rancher-kong |
| Task-05 | MinIO Object Storage | S3 Storage • Persistence • mc Client Automation | unikrew-task05-minio-storage |
| Task-06 | MongoDB Replica Air-Gap Setup | MongoDB 6.x • Replica Set • KeyFile Auth • Hybrid Sync | unikrew-task06-mongodb-replica-airgap |
| Task-07 | Jitsi Meet Video Conferencing | Docker Compose • Vagrant Provisioning • Prosody • Jicofo • JVB • Web UI | unikrew-task07-jitsi-meet-dockerized |

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


### 6️⃣ MongoDB Hybrid Air-Gap Replica Set

- Built a **3-node MongoDB Replica Set** across air-gapped VMs.
- Implemented **secure keyFile authentication** and admin user control.
- Automated replication and fail-over via **Bash scripts**.

### 🧱 Architecture
```
mongo-1 (Primary) → mongo-2 (Secondary) → mongo-3 (Secondary)
Network: 192.168.56.0/24
Replica Set Name: rs0
```

### ⚙️ Provisioning Highlights
- **Phase 1:** Standalone Air-Gap Install (.deb cache + local APT)
- **Phase 2:** Replica Automation → `rs.initiate()` + `db.createUser()`
- **Verification:** via `rs.status()` and authenticated logins


### 7️⃣ Jitsi Meet Dockerized Deployment
- Automated **self-hosted Jitsi Meet** stack with **Vagrant + Docker Compose**.
- Deployed **Prosody (XMPP)**, **Jicofo (Focus)**, **JVB (Video Bridge)**, and **Web UI** containers.
- Accessed secure conference via **https://192.168.56.80:8443**.
- Validated **real-time media flow (UDP 10000)** and **container integration**.

### 🧱 Architecture Overview
```
Client ↔ Web (8443 HTTPS)
      ↕
Prosody (XMPP 5222/5347) ←→ Jicofo ←→ JVB (UDP 10000)
                             
                         Ubuntu VM (192.168.56.80)
```


---


# 🆕 Additional Learning & Responsibilities

These items represent additional systems, tools, and concepts explored during the UniKrew Solutions DevOps Internship. Some were theoretical learnings used widely in fintech systems, while others involved hands-on troubleshooting and operational exposure.


## 📘 Additional Systems & Concepts Learned


- **VideoKYC Platform (Fintech Verification Flow)**  
  Learned how digital KYC calls work: WebRTC sessions, meeting lifecycle, agent/customer flows, and backend verification APIs used in fintech onboarding.

- **eKYC Identity Pipeline**  
  Understood CNIC OCR extraction, face match, liveness detection, document verification, and how multi-service evaluation pipelines work in financial institutions.

- **Jasper Reporting Server**  
  Studied how enterprise reporting engines generate dashboards, use datasets, depend on databases, and handle authentication/report caching.

- **Sentry Distributed Monitoring Architecture**  
  Understood the role of Relay, Snuba, Symbolicator, Kafka, and Redis in error ingestion and distributed monitoring workflows.

- **Rancher Enterprise Kubernetes Platform**  
  Gained conceptual understanding of multi-cluster management, node roles, workloads, UI-driven deployments, and cluster health monitoring.



## 🛠️ Troubleshooting & Operational Experience


During the internship, I assisted with real DevOps troubleshooting across UAT and production-like environments:

- **Disk & Storage Issues (UAT/Prod Exposure)**  
  Identified and cleaned large logs, old snapshots, and unnecessary backup data to recover servers with full `/` and `/var` partitions.

- **Docker & Container Recovery**  
  Cleaned oversized container logs, removed unused images, restarted failing services, and helped stabilize containerized applications.

- **Rancher & Kubernetes Assistance**  
  Checked pod states, analyzed failing workloads, reviewed logs, and assisted with fixing k3s snapshot issues and node disk pressure problems.

- **Application-Level Fixes**  
  Supported teams in resolving Java service crashes, port conflicts, and API connectivity failures; helped restore normal operations during UAT outages.

- **ACR Image Pull → Load → Push Workflow**  
  Pulled Docker images from Azure Container Registry, loaded them into offline environments, retagged them, and pushed them back into ACR or local registries as part of image migration/validation tasks.

- **Log Extraction & Preparation**  
  Extracted and processed `.log.gz` files, formatted logs for teams, and supported RCA investigations.

- **Cron & Backup Troubleshooting**  
  Helped diagnose failing backup scripts, incorrect environment variables, and encryption workflow issues.
- **Practical Scrum & Agile Exposure**  
  Attended daily standups, understood sprint goals, task estimation, backlog refinement, and how DevOps activities integrate into Scrum cycles within a fintech engineering team.



👉 *These troubleshooting tasks strengthened my ability to work in production-like environments, improving service stability, debugging skills, and overall operational awareness.*

---
## 🧠 Skills and Technologies Demonstrated
| Category | Stack / Concepts |
|-----------|------------------|
| Provisioning & Automation | Vagrant • Bash Scripting • IaC Concepts |
| CI/CD & DevOps Tools | Jenkins • GitLab CI/CD |
| Containers & Orchestration | Containerd • Docker • Kubernetes • K3s |
| Networking & Ingress | Calico • Traefik • Kong Gateway • NGINX Ingress |
| Storage & Data Management | MinIO • S3 API • Persistent Volumes • MongoDB Replica |
| Collaboration Platform | Jitsi Meet • Docker Compose • Media Bridges |
| Management & Monitoring | Rancher • kubectl • Systemd Units |

---


## ⚙️ General Setup Workflow
```bash
# 1️⃣ Clone the desired task repo
git clone https://github.com/MaazK111/unikrew-task06-mongodb-replica-airgap.git
cd unikrew-task06-mongodb-replica-airgap

# 2️⃣ Start the lab environment
vagrant up

# 3️⃣ Verify components
systemctl status mongod
kubectl get nodes
docker ps

# 4️⃣ Cleanup when done
vagrant destroy -f
```

---

## 🧾 Reflection
This internship reinforced my ability to **design, automate, and secure complex DevOps ecosystems** — covering runtime, CI/CD, networking, storage, replication, and communication infrastructure.  
Each task was built as a **mini production lab** with reproducible scripts and detailed documentation.

> 🏆 “Automation without clarity is chaos — these labs proved the power of structured DevOps.”
