# Component 1: EL Agent Architecture Design — Extensive Detail

## Critical Questions Analysis

Before proceeding with architecture implementation:

- **Hidden State Risk:** Archived code contains discovery methods and storage patterns that could conflict with new design
- **Workflow Assumptions:** 10-step linear flow may need parallel execution paths for efficiency
- **Critical Validation:** Schema discovery (Component 5) is the most failure-prone validation point
- **Implementation Priority:** Source discovery provides immediate user value and tests core patterns

## EL Agent System Architecture — Comprehensive Design

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EL AGENT SYSTEM ARCHITECTURE                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                             CORE ORCHESTRATOR                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │  EL Agent Controller (el_agent.py)                                     ││
│  │  • Session Management • State Persistence • Error Recovery             ││
│  │  • Component Orchestration • User Input Flow • Progress Tracking       ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
┌───────────────────▼───────────────────▼───────────────────▼─────────────────┐
│                         COMPONENT LAYER                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  C1: SOURCE DISCOVERY     │  C2: API ENUMERATION    │  C3: REQUIREMENTS    │
│  ┌─────────────────────┐  │  ┌─────────────────────┐ │  ┌──────────────────┐ │
│  │ • Fuzzy matching    │  │  │ • OpenAPI discovery │ │  │ • POC vs Prod    │ │
│  │ • Auto-complete     │  │  │ • Endpoint mapping  │ │  │ • Storage config │ │
│  │ • Source selection  │  │  │ • Rate limit detect │ │  │ • Schedule setup │ │
│  │ • Confidence score  │  │  │ • Auth discovery    │ │  │ • SLA definition │ │
│  └─────────────────────┘  │  └─────────────────────┘ │  └──────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│  C4: API KEY GUIDANCE     │  C5: SCHEMA DISCOVERY   │  C6: PIPELINE DESIGN │
│  ┌─────────────────────┐  │  ┌─────────────────────┐ │  ┌──────────────────┐ │
│  │ • Doc retrieval     │  │  │ • Sample data fetch │ │  │ • Pattern select │ │
│  │ • Step generation   │  │  │ • Type inference    │ │  │ • Error strategy │ │
│  │ • Key validation    │  │  │ • Column selection  │ │  │ • Rate limiting  │ │
│  │ • Test connection   │  │  │ • Schema validation │ │  │ • Monitoring     │ │
│  └─────────────────────┘  │  └─────────────────────┘ │  └──────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│  C7: CODE GENERATION      │  C8: CONTAINER TESTING  │  C9: FULL EXECUTION  │
│  ┌─────────────────────┐  │  ┌─────────────────────┐ │  ┌──────────────────┐ │
│  │ • Auth modules      │  │  │ • Docker isolation  │ │  │ • Live monitoring│ │
│  │ • Extraction logic  │  │  │ • Connection test   │ │  │ • Progress track │ │
│  │ • Transform code    │  │  │ • Schema validate   │ │  │ • Error handling │ │
│  │ • Validation rules  │  │  │ • Dry-run execute   │ │  │ • Recovery logic │ │
│  └─────────────────────┘  │  └─────────────────────┘ │  └──────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│  C10: RECIPE CREATION                                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │ • Pipeline serialisation • Version control • Sharing system          │ │
│  │ • Execution history • Cross-user learning • Template generation       │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                           EXECUTION ENGINE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────┐  ┌───────────────────────┐  ┌──────────────────┐ │
│  │   DOCKER RUNTIME      │  │   MONITORING SYSTEM   │  │   ERROR HANDLER  │ │
│  │ • Container mgmt      │  │ • Real-time metrics   │  │ • Retry logic    │ │
│  │ • Resource isolation  │  │ • Progress tracking   │  │ • Fallback modes │ │
│  │ • Security sandbox    │  │ • Performance stats   │  │ • User notif     │ │
│  └───────────────────────┘  └───────────────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────────────────────────┐
│                            STORAGE LAYER                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────┐  ┌───────────────────────┐  ┌──────────────────┐ │
│  │   DUCKDB (Local)      │  │   RECIPE STORAGE      │  │   CONFIG STORE   │ │
│  │ • Session state       │  │ • Pipeline configs    │  │ • Source defs    │ │
│  │ • Execution history   │  │ • Version history     │  │ • User settings  │ │
│  │ • User selections     │  │ • Shared templates    │  │ • Auth tokens    │ │
│  └───────────────────────┘  └───────────────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Architecture Details

### 1. Core Orchestrator Layer

**EL Agent Controller** (`src/core/el_agent.py`)
```python
class ELAgent:
    def __init__(self, session_id: str, storage: StorageInterface)
    def execute_workflow(self, start_step: int = 1) -> WorkflowResult
    def handle_interruption(self, signal: str) -> InterruptionResponse
    def persist_session(self) -> None
    def recover_session(self, session_id: str) -> bool
```

**State Management** (`src/core/session_manager.py`)
```python
class SessionManager:
    def create_session(self) -> Session
    def save_checkpoint(self, session: Session, component: str) -> None
    def load_checkpoint(self, session_id: str) -> Optional[Session]
    def list_sessions(self) -> List[Session]
```

### 2. Component Interface Standard

**Base Component** (`src/components/base.py`)
```python
class BaseComponent:
    def execute(self, input_data: ComponentInput) -> ComponentOutput
    def validate_input(self, data: Any) -> ValidationResult  
    def can_interrupt(self) -> bool
    def get_progress(self) -> Progress
    def cleanup(self) -> None
```

### 3. Data Flow Architecture

**Pipeline State**
```python
@dataclass
class PipelineState:
    session_id: str
    current_step: int
    component_outputs: Dict[str, Any]
    user_selections: Dict[str, Any]
    error_history: List[Error]
    configuration: PipelineConfig
```

**Component Communication**
```python
class ComponentBus:
    def publish(self, event: ComponentEvent) -> None
    def subscribe(self, component: str, handler: Callable) -> None
    def get_shared_state(self, key: str) -> Any
    def set_shared_state(self, key: str, value: Any) -> None
```

## Configuration Management Architecture

**Settings Hierarchy** (`src/config/`)
```
conf/
├── default.yaml           # Safe defaults (non-operational)
├── sources.yaml          # Source definitions  
├── templates/            # Pipeline templates
└── user/                 # User-specific configs
    ├── auth_tokens.yaml  # Encrypted tokens
    └── preferences.yaml  # UI/UX settings
```

**Environment Variables**
```bash
PURELINK_ENV=local|staging|prod
PURELINK_CONFIG_PATH=/path/to/conf
PURELINK_DB_PATH=/path/to/storage
PURELINK_DOCKER_MODE=enabled|disabled
```

## Error Handling & Recovery Architecture

**Error Classification**
```python
class ErrorType(Enum):
    USER_INPUT = "user_input"          # Retry with correction
    CONFIGURATION = "configuration"    # Fix config, resume
    NETWORK = "network"               # Exponential backoff
    AUTHENTICATION = "auth"           # Re-auth required
    RESOURCE = "resource"            # Scale or defer
    FATAL = "fatal"                  # Manual intervention
```

**Recovery Strategies**
```python
class RecoveryManager:
    def handle_error(self, error: ComponentError) -> RecoveryAction
    def create_checkpoint(self, state: PipelineState) -> Checkpoint
    def rollback_to_checkpoint(self, checkpoint_id: str) -> bool
    def suggest_fixes(self, error: ComponentError) -> List[Fix]
```

## Implementation Plan — Smallest Incremental Steps

### Phase 1: Foundation (Week 1)
1. **Core Infrastructure Setup**
   - Configuration management system
   - Base component interface
   - Session management skeleton
   - Docker execution framework

2. **Component 1 Implementation** (Source Discovery)
   - Fuzzy matching utility
   - Source configuration loader  
   - Auto-complete engine
   - User selection interface

### Phase 2: Data Flow (Week 2)
3. **Storage Integration**
   - Extend DuckDB schema for EL Agent
   - Component state persistence
   - Session recovery mechanism

4. **Component 2 Implementation** (API Enumeration)
   - OpenAPI discovery engine
   - Endpoint mapping logic
   - Rate limit detection

### Phase 3: User Experience (Week 3)  
5. **Error Handling Framework**
   - Error classification system
   - Recovery strategies
   - User interruption handling

6. **Component 3 Implementation** (Requirements Gathering)
   - Interactive requirement capture
   - Configuration validation
   - Storage target selection

### Phase 4: Execution Engine (Week 4)
7. **Docker Integration**
   - Container management
   - Isolated execution environment
   - Resource monitoring

8. **Components 4-6 Implementation**
   - API key guidance system
   - Schema discovery engine
   - Pipeline design logic

### Phase 5: Production Readiness (Week 5)
9. **Components 7-10 Implementation**
   - Code generation engine
   - Container testing framework
   - Full execution monitoring
   - Recipe creation system

10. **Integration & Testing**
    - End-to-end workflow testing
    - Error scenario validation
    - Performance optimisation

## First Implementation — Detailed Proposals

### Planned Files/Paths
- `src/core/config_manager.py` — Configuration loading and validation
- `src/components/base.py` — Base component interface
- `src/components/source_discovery.py` — Component 1 implementation
- `src/utils/fuzzy_matcher.py` — String matching utility
- `conf/sources.yaml` — Source definitions configuration
- `conf/default.yaml` — System defaults
- `.env.example` — Environment variables template
- `tests/test_source_discovery.py` — Component 1 tests

### Function/Class/Module Names
- `ConfigManager.load_config(path: str) -> Dict`
- `ConfigManager.get_setting(key: str, default: Any) -> Any`
- `BaseComponent.execute(input_data: ComponentInput) -> ComponentOutput`
- `SourceDiscovery.find_sources(query: str) -> List[SourceMatch]`
- `SourceDiscovery.select_source(selection: int) -> SourceResult`
- `FuzzyMatcher.match(query: str, candidates: List[str]) -> List[Match]`

### CLI/ENV/Config Keys
- `PURELINK_CONFIG_PATH` (ENV, default: `./conf`)
- `PURELINK_DB_PATH` (ENV, default: `./data/purelink.duckdb`)
- `sources.enabled` (config, default: True)
- `sources.min_confidence` (config, default: 0.3)
- `fuzzy.algorithm` (config, default: "rapidfuzz")
- `--source` (CLI arg, existing, for source hints)

### Execution Plan
1. Create configuration management system (non-destructive, file-based)
2. Implement base component interface (abstract class)
3. Build source discovery component with YAML-based source definitions
4. Add fuzzy matching utility with confidence scoring
5. Create minimal test suite covering edge cases
6. Test via Docker container (isolated, read-only initially)

## Critical Decisions Needed

1. **Fuzzy Matching:** rapidfuzz vs difflib for string matching?
2. **Initial Sources:** 5, 10, or 20 sources in sources.yaml?
3. **Confidence Threshold:** What score triggers "no matches found"?
4. **Multi-language:** Support source names in multiple languages?
5. **Storage Integration:** Extend existing DuckDB schema or create new tables?

## Success Criteria — Component 1

Component 1 implementation is complete when:
- User can get auto-complete suggestions for partial input (< 200ms response)
- Selection mechanism works reliably with 1-based indexing
- Code is under 50 lines per module (config, base, discovery, matcher)
- No hardcoded source lists (YAML-based configuration)
- Battle tested with edge cases:
  - No matches found (confidence < threshold)
  - Single character input ("s", "a")
  - Typos and misspellings ("stipe" → "Stripe")
  - Empty input ("")
  - Special characters ("api@service.com")
- Container execution works in isolated mode
- Test coverage > 85% for source discovery component

## Pre-Change Compliance Checklist

- [x] Loaded root and folder-level CLAUDE.md rules
- [x] Drafted proposals (names, files, config keys, commands) awaiting authorisation
- [x] Critical Questions presented for this step  
- [x] Will execute in container; non-destructive mode
- [ ] Tests exist or will be added/updated
- [ ] Observability hooks will be present