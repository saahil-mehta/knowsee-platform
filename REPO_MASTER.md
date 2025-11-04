REPO MASTER MINDMAP

                      ┌──────────────────────────────────────────────────┐
                      │                    knowsee-platform              │
                     └──────────────────────────────────────────────────┘
                                    │
             ┌──────────────────────┼──────────────────────┐
             │                      │                      │
         Backend               Frontend                Deployment / Infra
             │                      │                      │
             │                      │                      │
     ┌───────┴────────┐             │                      │
     │                │             │                      │
 Alembic        Alembic_Tenants     …                      …
 (shared DB)    (tenant DBs)
     │                │
     │                ├─────────────┐
     │                │             │
     │        Schema Translator  ←──┘
     │        (`get_session_with_tenant`
     │        applies schema map from
     │        CURRENT_TENANT_ID_CONTEXTVAR)
     │
     ├─────> SQLAlchemy Models
     │       (`backend/onyx/db/models.py`
     │        define tables migrations sync)
     │
     ├─────> Alembic CLI (`alembic upgrade head`)
     │
     ├─────> Migration History
     │       (timestamped `versions/*.py` kept forever)
     │
     └─────> Sync Tool Metadata
             (`<!-- ONYX_METADATA=... -->` comments flag
              upstream source for doc sync)

Deployment / Infra Branch
├── Model Server Deployment (K8s / Cloud Run)
│   ├── Runs FastAPI `backend/model_server` service.
│   ├── Exposed via Service (ClusterIP / LB) at port 9000.
│   └── Backend points via env (`MODEL_SERVER_HOST` / `INDEXING_MODEL_SERVER_HOST`).
└── Autoscaling
    ├── Separate Deployment per service (API, model-server, workers).
    ├── HPA on CPU / custom metrics for embedding load.
    ├── Optional GPU attachment (`nvidia.com/gpu`) for model pods.
    └── Metrics Server / Prometheus feed autoscale logic on GKE.

Legend:
- “─┤” branches form the hierarchical map.
- “───>” arrows mark directional dependencies or data flow.
- Ellipses (…) reserve space for future branches as new components are explored.
