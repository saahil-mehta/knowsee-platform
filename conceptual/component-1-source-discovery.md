# Component 1: Source Discovery - Conceptual Design

## Scope Definition

**What Component 1 Does:**
- User types partial input (e.g., "S", "str", "stripe")
- System provides auto-complete suggestions
- User selects from suggestions
- System confirms selection

**What Component 1 Does NOT Do:**
- API enumeration (that's Component 2)
- Schema discovery (that's Component 5) 
- Any pipeline generation
- Any data processing

## Input/Output Specification

**Input:**
```
User types: "str"
```

**Output:**
```
Auto-complete suggestions:
1. Stripe (Payment processing)
2. Strapi (Headless CMS)
3. Streamlit (Data apps)

User selects: 1
```

**Final Output:**
```
Selected source: Stripe
Description: Payment processing
API type: REST
```

## Technical Requirements

**Must Have:**
- Fuzzy string matching for auto-complete
- Configurable source database (not hardcoded)
- Fast response time (< 200ms for suggestions)
- Handle typos and partial matches

**Must NOT Have:**
- API calls to external services
- Complex LLM reasoning (keep simple)
- Database connections (file-based config)
- More than 50 lines of code

## Data Source Strategy

**Question 1:** Where do source definitions come from?
- Option A: YAML config file (sources.yaml)
- Option B: JSON config file (sources.json) 
- Option C: Python module (sources.py)
- Option D: Built-in dictionary (minimal for prototype)

**Question 2:** What information per source?
```yaml
# Minimal example
- name: "Stripe"
  description: "Payment processing"
  api_type: "REST"
  category: "Payments"
```

**Question 3:** How many sources for initial testing?
- Option A: 5 sources (minimal viable)
- Option B: 10 sources (reasonable variety)
- Option C: 20+ sources (comprehensive)

## User Experience Flow

```
Step 1: User Input
├─ Terminal: "Enter data source: "
├─ User types: "s"
└─ System shows: "Loading suggestions..."

Step 2: Auto-complete Display  
├─ "1. Salesforce (CRM platform)"
├─ "2. Stripe (Payment processing)"
├─ "3. Shopify (E-commerce platform)"
└─ "4. Slack (Team communication)"

Step 3: User Selection
├─ Terminal: "Select option (1-4): "
├─ User types: "2"
└─ System confirms: "Selected: Stripe"

Step 4: Output
└─ Return structured data for next component
```

## Technical Architecture

**File Structure:**
```
src/
├─ components/
│  └─ source_discovery.py      # Main component (< 50 lines)
├─ config/
│  └─ sources.yaml             # Source definitions
└─ utils/
   └─ fuzzy_matcher.py         # String matching utility
```

**Core Function:**
```python
def discover_source(user_input: str) -> dict:
    """
    Args:
        user_input: Partial string from user
    
    Returns:
        {
            "name": "Stripe",
            "description": "Payment processing", 
            "api_type": "REST",
            "confidence": 0.95
        }
    """
```

## Implementation Questions

**For User Decision:**

1. **Data Source:** YAML config file or built-in dictionary for prototype?

2. **Matching Algorithm:** Simple startswith() or fuzzy matching library?

3. **User Interface:** Command line prompts or function calls only?

4. **Error Handling:** What happens if no matches found?

5. **Testing:** What test cases should we cover?

## Success Criteria

**Component 1 is complete when:**
- User can get auto-complete suggestions for partial input
- Selection mechanism works reliably  
- Code is under 50 lines total
- No hardcoded source lists (configurable)
- Battle tested with edge cases:
  - No matches found
  - Single character input
  - Typos and misspellings
  - Empty input
  - Special characters

**Approval Gate:**
User must approve the conceptual design before any implementation begins.