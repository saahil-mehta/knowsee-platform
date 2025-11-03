# GCP Production Architecture

**Purpose**: Replace Docker Compose with proper GCP managed services for production scalability and reliability.

**Problem Statement**: Current Docker Compose setup bundles databases, caching, and application services together, which violates modularity principles and won't scale in production.

**Last Updated**: 2025-11-03

---

## Current Docker Architecture Issues

### What's Wrong with the Current Setup

```yaml
# Current docker-compose.yml structure
services:
  api_server:        # FastAPI backend
  background:        # Celery workers (8 types!)
  web_server:        # Next.js frontend
  relational_db:     # PostgreSQL 🚨 STATEFUL IN CONTAINER
  index:             # Vespa vector DB 🚨 STATEFUL IN CONTAINER
  cache:             # Redis 🚨 STATEFUL IN CONTAINER
  minio:             # S3-compatible storage 🚨 STATEFUL IN CONTAINER
  inference_model_server:  # ML model server
  indexing_model_server:   # Another ML model server
  nginx:             # Reverse proxy
```

### Specific Problems

**1. Stateful Services in Docker**
- PostgreSQL, Redis, Vespa, MinIO all run in containers
- Data persistence relies on Docker volumes
- No automatic backups
- No high availability
- No automatic failover
- Container restarts risk data corruption

**2. Lack of Modularity**
- All services bundled in one compose file
- Can't scale services independently
- Can't update one service without affecting others
- Dev and prod use same architecture (bad practice)

**3. Scalability Issues**
- Can't horizontally scale PostgreSQL (single container)
- Redis has no clustering
- Vespa running on single node
- All services on one host (or manual multi-host setup)

**4. Operational Fragility**
- No monitoring/alerting built-in
- No automatic recovery
- Manual backup management
- Upgrade process requires downtime
- Port management is complex

**5. Resource Management**
- All services compete for resources on same host
- No resource limits per service
- Can't allocate more memory to just database
- No auto-scaling

---

## Recommended GCP Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     USER / DEVELOPER                            │
│                   (Web Browser / API Client)                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTPS
                             ▼
                   ┌─────────────────────┐
                   │   Cloud Load        │
                   │   Balancer (HTTPS)  │
                   │   + Cloud Armor     │
                   └──────────┬──────────┘
                              │
                 ┌────────────┴────────────┐
                 │                         │
                 ▼                         ▼
        ┌─────────────────┐      ┌─────────────────┐
        │  Cloud Run      │      │  Cloud Run      │
        │  (Web Server)   │      │  (API Server)   │
        │  Next.js        │      │  FastAPI        │
        └────────┬────────┘      └────────┬────────┘
                 │                         │
                 └────────────┬────────────┘
                              │
              ┌───────────────┼───────────────┬──────────────────┐
              │               │               │                  │
              ▼               ▼               ▼                  ▼
    ┌──────────────┐  ┌─────────────┐  ┌────────────┐  ┌──────────────┐
    │  Cloud SQL   │  │ Memorystore │  │  GKE Pod   │  │ Cloud Storage│
    │ (PostgreSQL) │  │   (Redis)   │  │  (Vespa)   │  │  (S3-compat) │
    └──────────────┘  └─────────────┘  └────────────┘  └──────────────┘
                                              │
                                              ▼
                                      ┌─────────────┐
                                      │  GKE Pods   │
                                      │  (Celery    │
                                      │   Workers)  │
                                      └─────────────┘
                                              │
                                              ▼
                                      ┌─────────────┐
                                      │  GKE Pods   │
                                      │ (ML Model   │
                                      │  Servers)   │
                                      └─────────────┘
```

### Service Mapping

| Docker Service | GCP Managed Service | Why? |
|---------------|-------------------|------|
| **relational_db** (PostgreSQL) | **Cloud SQL** | Automatic backups, HA, read replicas, auto-scaling storage |
| **cache** (Redis) | **Memorystore for Redis** | HA, automatic failover, no ops overhead |
| **minio** (S3) | **Cloud Storage** | Unlimited scalability, 11 9's durability, CDN integration |
| **api_server** | **Cloud Run** | Auto-scaling, pay-per-use, zero ops |
| **web_server** | **Cloud Run** | Auto-scaling, pay-per-use, global deployment |
| **background** (Celery) | **GKE Autopilot** | Multiple worker types, resource control, scaling |
| **inference/indexing_model_server** | **GKE Autopilot** (with GPU) | GPU support, batch processing, scaling |
| **index** (Vespa) | **GKE Autopilot** (StatefulSet) | Needs custom deployment, state management |
| **nginx** | **Cloud Load Balancer** | SSL termination, DDoS protection, global LB |

---

## Detailed Component Design

### 1. Cloud SQL (PostgreSQL)

**Configuration**:
```hcl
# terraform/modules/database/main.tf
resource "google_sql_database_instance" "knowsee_postgres" {
  name             = "knowsee-db-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-custom-4-16384"  # 4 vCPU, 16GB RAM (adjust as needed)

    availability_type = "REGIONAL"  # High availability

    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
    }

    ip_configuration {
      ipv4_enabled    = false  # Use private IP only
      private_network = google_compute_network.vpc.id

      authorized_networks {
        name  = "cloud-run-access"
        value = "0.0.0.0/0"  # Managed via VPC
      }
    }

    database_flags {
      name  = "max_connections"
      value = "250"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
    }
  }

  deletion_protection = true
}
```

**Connection from Cloud Run**:
```python
# backend/onyx/db/engine.py
import sqlalchemy
from google.cloud.sql.connector import Connector

def get_cloud_sql_engine():
    connector = Connector()

    def getconn():
        return connector.connect(
            f"{PROJECT_ID}:{REGION}:{INSTANCE_NAME}",
            "pg8000",
            user="knowsee-app",
            password=SECRET_MANAGER_PASSWORD,
            db="knowsee_db",
        )

    return sqlalchemy.create_engine(
        "postgresql+pg8000://",
        creator=getconn,
        pool_size=5,
        max_overflow=10,
    )
```

**Benefits**:
- ✅ Automatic daily backups
- ✅ Point-in-time recovery (7 days)
- ✅ High availability (regional failover)
- ✅ Read replicas for scaling reads
- ✅ Automatic storage scaling
- ✅ Query insights for debugging
- ✅ No manual maintenance

---

### 2. Memorystore for Redis

**Configuration**:
```hcl
# terraform/modules/cache/main.tf
resource "google_redis_instance" "knowsee_redis" {
  name           = "knowsee-cache-${var.environment}"
  tier           = "STANDARD_HA"  # High availability
  memory_size_gb = 5
  region         = var.region

  redis_version     = "REDIS_7_0"
  display_name      = "Knowsee Cache & Celery Broker"

  authorized_network = google_compute_network.vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_configs = {
    maxmemory-policy = "allkeys-lru"
  }

  persistence_config {
    persistence_mode    = "RDB"
    rdb_snapshot_period = "ONE_HOUR"
  }
}
```

**Benefits**:
- ✅ Automatic failover (< 60 seconds)
- ✅ RDB persistence (hourly snapshots)
- ✅ Read replicas for scaling
- ✅ No ops overhead
- ✅ Monitoring built-in

---

### 3. Cloud Storage (S3 Replacement)

**Configuration**:
```hcl
# terraform/modules/storage/main.tf
resource "google_storage_bucket" "knowsee_files" {
  name          = "knowsee-files-${var.environment}"
  location      = "US"  # Multi-region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365  # Delete old versions after 1 year
      with_state = "ARCHIVED"
    }
  }

  cors {
    origin          = ["https://your-domain.com"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}
```

**Benefits**:
- ✅ Unlimited storage
- ✅ 99.999999999% durability
- ✅ Versioning built-in
- ✅ Lifecycle management
- ✅ No maintenance

---

### 4. Cloud Run (API & Web Servers)

**Why Cloud Run Over Cloud Run Jobs**:
- Jobs are for **batch processing** (one-off tasks)
- Services are for **always-on HTTP servers** (your use case)
- Cloud Run Services auto-scale 0 → N based on traffic
- Pay only for actual request time

**API Server Configuration**:
```hcl
# terraform/modules/api/main.tf
resource "google_cloud_run_v2_service" "api" {
  name     = "knowsee-api-${var.environment}"
  location = var.region

  template {
    scaling {
      min_instance_count = 1   # Always 1 instance ready
      max_instance_count = 100  # Scale up to 100
    }

    containers {
      image = "gcr.io/${var.project_id}/knowsee-backend:${var.image_tag}"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "4Gi"
        }
      }

      env {
        name  = "POSTGRES_HOST"
        value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
      }

      env {
        name = "POSTGRES_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.id
            version = "latest"
          }
        }
      }

      env {
        name  = "REDIS_HOST"
        value = google_redis_instance.cache.host
      }

      env {
        name  = "VESPA_HOST"
        value = "vespa-service.default.svc.cluster.local"  # GKE internal DNS
      }

      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 10
        period_seconds        = 3
        failure_threshold     = 5
      }

      liveness_probe {
        http_get {
          path = "/health"
        }
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}
```

**Web Server Configuration**: Similar to API, but with Next.js image.

**Benefits**:
- ✅ Auto-scales 0 → 100 instances based on load
- ✅ Pay only for actual CPU/memory used during requests
- ✅ Built-in HTTPS
- ✅ Blue-green deployments
- ✅ No server management

---

### 5. GKE Autopilot (Celery Workers + Vespa)

**Why GKE for Workers**:
- Celery has 8+ worker types with different resource needs
- Need long-running processes (not request-based)
- Need GPU for model servers
- Vespa needs StatefulSet with persistent storage

**Celery Worker Deployment**:
```yaml
# k8s/celery-docprocessing-worker.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: celery-docprocessing-worker
spec:
  replicas: 3  # Can use HPA for auto-scaling
  selector:
    matchLabels:
      app: celery-docprocessing
  template:
    metadata:
      labels:
        app: celery-docprocessing
    spec:
      containers:
      - name: worker
        image: gcr.io/PROJECT_ID/knowsee-backend:TAG
        command: ["celery", "-A", "background.celery.celery_app", "worker"]
        args:
          - "--pool=threads"
          - "--concurrency=4"
          - "-Q docprocessing"
          - "--loglevel=info"
        resources:
          requests:
            cpu: "2"
            memory: "4Gi"
          limits:
            cpu: "4"
            memory: "8Gi"
        env:
        - name: POSTGRES_HOST
          value: "10.x.x.x"  # Cloud SQL private IP
        - name: REDIS_HOST
          value: "10.x.x.x"  # Memorystore private IP
        - name: VESPA_HOST
          value: "vespa-service.default.svc.cluster.local"
```

**Vespa StatefulSet**:
```yaml
# k8s/vespa-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: vespa
spec:
  serviceName: vespa-service
  replicas: 3  # 3-node Vespa cluster
  selector:
    matchLabels:
      app: vespa
  template:
    metadata:
      labels:
        app: vespa
    spec:
      containers:
      - name: vespa
        image: vespaengine/vespa:8.526.15
        ports:
        - containerPort: 8080
        - containerPort: 19071
        resources:
          requests:
            cpu: "4"
            memory: "16Gi"
          limits:
            cpu: "8"
            memory: "32Gi"
        volumeMounts:
        - name: vespa-data
          mountPath: /opt/vespa/var
  volumeClaimTemplates:
  - metadata:
      name: vespa-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "standard-rwo"
      resources:
        requests:
          storage: 500Gi  # SSD storage
```

**Model Server with GPU**:
```yaml
# k8s/model-server-gpu.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inference-model-server
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: model-server
        image: gcr.io/PROJECT_ID/knowsee-model-server:TAG
        resources:
          limits:
            nvidia.com/gpu: 1  # Request 1 GPU
            cpu: "8"
            memory: "32Gi"
      nodeSelector:
        cloud.google.com/gke-accelerator: nvidia-tesla-t4
```

**Benefits**:
- ✅ Different resource profiles per worker type
- ✅ Auto-scaling per worker type (HPA)
- ✅ GPU support for ML models
- ✅ StatefulSets for Vespa persistence
- ✅ Rolling updates with zero downtime
- ✅ Resource quotas and limits

---

### 6. Cloud Load Balancer + Cloud Armor

**Configuration**:
```hcl
# terraform/modules/loadbalancer/main.tf
resource "google_compute_global_address" "default" {
  name = "knowsee-lb-ip-${var.environment}"
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = "knowsee-ssl-cert"

  managed {
    domains = [var.domain]  # your-domain.com
  }
}

resource "google_compute_backend_service" "api" {
  name        = "knowsee-api-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 300

  backend {
    group = google_compute_region_network_endpoint_group.api.id
  }

  health_checks = [google_compute_health_check.api.id]

  iap {  # Identity-Aware Proxy for extra security
    enabled = true
    oauth2_client_id     = var.iap_client_id
    oauth2_client_secret = var.iap_client_secret
  }
}

resource "google_compute_security_policy" "default" {
  name = "knowsee-security-policy"

  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["9.9.9.0/24"]  # Block malicious IPs
      }
    }
    description = "Block known bad actors"
  }

  rule {
    action   = "rate_based_ban"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"

      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }

      ban_duration_sec = 600
    }
    description = "Rate limit: 100 req/min per IP"
  }
}
```

**Benefits**:
- ✅ DDoS protection (Cloud Armor)
- ✅ Rate limiting per IP
- ✅ Automatic SSL certificate management
- ✅ Global load balancing
- ✅ Identity-Aware Proxy for admin routes

---

## Migration Strategy

### Phase 1: Parallel Infrastructure (Week 1-2)

**Goal**: Set up GCP services alongside Docker

1. **Create GCP Project**:
   ```bash
   gcloud projects create knowsee-prod-12345
   gcloud config set project knowsee-prod-12345
   ```

2. **Deploy Managed Services**:
   ```bash
   cd terraform/environments/prod
   terraform init
   terraform apply
   # Creates: Cloud SQL, Memorystore, Cloud Storage, VPC
   ```

3. **Test Connections**:
   - Connect to Cloud SQL from local machine
   - Test Redis connection
   - Upload test file to Cloud Storage

### Phase 2: Database Migration (Week 2-3)

**Goal**: Migrate PostgreSQL data to Cloud SQL

1. **Dump from Docker**:
   ```bash
   docker exec onyx-relational_db-1 pg_dump -U postgres -d postgres > backup.sql
   ```

2. **Import to Cloud SQL**:
   ```bash
   gcloud sql import sql knowsee-db-prod gs://knowsee-migration/backup.sql \
     --database=knowsee_db
   ```

3. **Verify**:
   ```bash
   gcloud sql connect knowsee-db-prod --user=postgres
   # Run SELECT queries to verify data
   ```

### Phase 3: Deploy Vespa to GKE (Week 3-4)

**Goal**: Move Vespa from Docker to GKE

1. **Create GKE Cluster**:
   ```bash
   gcloud container clusters create-auto knowsee-cluster \
     --region=us-central1 \
     --enable-private-nodes
   ```

2. **Deploy Vespa**:
   ```bash
   kubectl apply -f k8s/vespa-statefulset.yaml
   kubectl apply -f k8s/vespa-service.yaml
   ```

3. **Migrate Vespa Data**:
   ```bash
   # Export from Docker Vespa
   docker exec onyx-index-1 vespa-visit > vespa_backup.json

   # Import to GKE Vespa
   kubectl exec -it vespa-0 -- vespa-feeder vespa_backup.json
   ```

### Phase 4: Deploy Application Services (Week 4-5)

**Goal**: Deploy Cloud Run services

1. **Build Container Images**:
   ```bash
   # Backend
   gcloud builds submit backend/ \
     --tag gcr.io/knowsee-prod-12345/knowsee-backend:v1.0.0

   # Frontend
   gcloud builds submit web/ \
     --tag gcr.io/knowsee-prod-12345/knowsee-web:v1.0.0
   ```

2. **Deploy Cloud Run**:
   ```bash
   cd terraform/modules/cloudrun
   terraform apply
   ```

3. **Deploy Celery Workers**:
   ```bash
   kubectl apply -f k8s/celery/
   ```

### Phase 5: Traffic Cutover (Week 5)

**Goal**: Switch traffic to GCP

1. **DNS Update**:
   ```bash
   # Point your-domain.com to Cloud Load Balancer IP
   # Use Cloud DNS or your DNS provider
   ```

2. **Monitor**:
   - Check Cloud Run logs
   - Check Celery worker logs
   - Monitor Cloud SQL queries
   - Watch error rates

3. **Rollback Plan**:
   - Keep Docker Compose running for 1 week
   - Can quickly switch DNS back if issues

### Phase 6: Decommission Docker (Week 6)

**Goal**: Shut down Docker infrastructure

1. **Final Data Sync**:
   ```bash
   # Ensure all data is in GCP
   ```

2. **Stop Docker**:
   ```bash
   docker compose down
   ```

3. **Archive**:
   - Keep Docker volumes as backups for 30 days
   - Document the cutover

---

## Cost Estimates

### GCP Monthly Costs (Production, ~10K users)

| Service | Configuration | Monthly Cost (USD) |
|---------|--------------|-------------------|
| **Cloud SQL** | db-custom-4-16384, HA | ~$450 |
| **Memorystore Redis** | 5GB, Standard HA | ~$110 |
| **Cloud Storage** | 500GB storage + egress | ~$30 |
| **Cloud Run (API)** | 2vCPU, 4GB, 100 req/s avg | ~$200 |
| **Cloud Run (Web)** | 1vCPU, 2GB, 50 req/s avg | ~$100 |
| **GKE Autopilot** | 10 nodes avg (Celery + Vespa) | ~$800 |
| **Cloud Load Balancer** | 1TB egress | ~$150 |
| **Cloud Armor** | Security policies | ~$20 |
| **Networking** | VPC, NAT gateway | ~$50 |
| **Logging & Monitoring** | Cloud Logging, Metrics | ~$90 |
| **Total** | | **~$2,000/month** |

**Cost Optimization**:
- Use committed use discounts (30-50% off)
- Enable autoscaling to scale down during off-hours
- Use Cloud Storage Nearline for old data
- Use preemptible VMs for non-critical workers

**Comparison**:
- Docker on single VM: ~$200/month (but not scalable, not HA)
- GCP Managed: ~$2,000/month (but auto-scales, HA, zero ops)

---

## Monitoring & Operations

### Observability Stack

**Cloud Monitoring**:
```hcl
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "High CPU Usage"
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run API CPU > 80%"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}
```

**Cloud Logging**:
```python
# backend/onyx/utils/logger.py
import google.cloud.logging

client = google.cloud.logging.Client()
client.setup_logging()

# All logs automatically sent to Cloud Logging
logger.info("Processing document", extra={"document_id": doc_id})
```

**Dashboards**:
- Cloud SQL: Query latency, connections, storage usage
- Memorystore: Memory usage, ops/sec, evictions
- Cloud Run: Request latency, instance count, error rate
- GKE: Pod health, resource utilization, HPA metrics
- Vespa: Index size, query latency, feed rate

### Backup Strategy

**Automated Backups**:
- Cloud SQL: Daily automatic backups + PITR (7 days)
- Memorystore: Hourly RDB snapshots
- Vespa: Daily snapshot to Cloud Storage
- Cloud Storage: Versioning enabled

**Disaster Recovery**:
- RPO (Recovery Point Objective): 1 hour
- RTO (Recovery Time Objective): 30 minutes
- Multi-region replication for critical data

---

## Security

### Network Security

**VPC Configuration**:
```
┌─────────────────────────────────────────────┐
│              Public Internet                │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
         ┌─────────────────┐
         │  Cloud Armor    │ ← DDoS protection
         │  + Load Balancer│
         └─────────┬───────┘
                   │
    ┌──────────────┴──────────────┐
    │    VPC (10.0.0.0/16)        │
    │                              │
    │  ┌────────────────────────┐ │
    │  │ Cloud Run Services     │ │
    │  │ (Serverless VPC Access)│ │
    │  └────────┬───────────────┘ │
    │           │                  │
    │  ┌────────┴───────────────┐ │
    │  │ Private Subnet         │ │
    │  │ Cloud SQL (10.0.1.0/24)│ │
    │  │ Memorystore (10.0.2.x) │ │
    │  └────────────────────────┘ │
    │                              │
    │  ┌────────────────────────┐ │
    │  │ GKE Cluster            │ │
    │  │ (10.0.10.0/24)         │ │
    │  └────────────────────────┘ │
    └──────────────────────────────┘
```

**Firewall Rules**:
- Cloud SQL: Only accessible from Cloud Run + GKE (private IP)
- Memorystore: Only accessible from Cloud Run + GKE
- Vespa: Only accessible within GKE cluster
- Cloud Run: Only accessible via Load Balancer

### IAM & Secrets

**Service Accounts**:
```hcl
resource "google_service_account" "api_server" {
  account_id   = "knowsee-api-server"
  display_name = "Knowsee API Server"
}

resource "google_project_iam_member" "api_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.api_server.email}"
}

resource "google_secret_manager_secret_iam_member" "api_db_password" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.api_server.email}"
}
```

**Secret Management**:
- Database passwords: Secret Manager
- API keys: Secret Manager
- OAuth credentials: Secret Manager
- Environment-specific secrets per environment

---

## Advantages Over Docker Compose

| Aspect | Docker Compose | GCP Managed |
|--------|---------------|-------------|
| **Scalability** | Manual, limited | Auto-scales 0 → 1000s |
| **High Availability** | Single point of failure | Multi-zone automatic failover |
| **Backups** | Manual scripts | Automatic daily + PITR |
| **Monitoring** | Self-managed (Prometheus?) | Built-in Cloud Monitoring |
| **Security** | Self-managed | Cloud Armor, VPC, IAM |
| **Ops Overhead** | High (updates, patches, monitoring) | Near zero |
| **Cost (small)** | $50-200/month | $500-1000/month |
| **Cost (scale)** | Doesn't scale | $2000-5000/month |
| **Disaster Recovery** | Manual | Automated |
| **Compliance** | DIY | SOC 2, ISO 27001, HIPAA |

---

## Next Steps

1. **Review this architecture** with your team
2. **Create GCP project** and enable billing
3. **Set up Terraform** infrastructure as code
4. **Start with Phase 1** (parallel infrastructure)
5. **Test thoroughly** before cutover
6. **Plan cutover window** (low traffic time)
7. **Execute migration** phases sequentially
8. **Monitor closely** for first week
9. **Optimize costs** after stable

---

## Alternative: Hybrid Approach

If full GCP migration is too much initially:

**Quick Wins** (Replace just the stateful services):
1. Keep Docker Compose for application code
2. Use Cloud SQL instead of PostgreSQL container
3. Use Memorystore instead of Redis container
4. Use Cloud Storage instead of MinIO
5. Point Docker services to managed services

**docker-compose.hybrid.yml**:
```yaml
services:
  api_server:
    image: onyxdotapp/onyx-backend:latest
    environment:
      - POSTGRES_HOST=10.x.x.x  # Cloud SQL private IP
      - REDIS_HOST=10.x.x.x      # Memorystore IP
      - S3_ENDPOINT_URL=https://storage.googleapis.com
    # Remove: relational_db, cache, minio services
```

This gives you:
- ✅ Managed database (backups, HA)
- ✅ Managed cache
- ✅ Managed storage
- ⚠️ Still running app in Docker (but stateless now)
- Cost: ~$600/month (cheaper than full GCP)

---

**Questions or need help with specific migration steps? Let me know!**
