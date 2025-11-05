# How to Import Onyx Mindmap into MIRO or Excalidraw

This guide shows you how to import the Onyx architecture mindmap into visual collaboration tools.

## Files Created

1. **`ONYX-COMPLETE-MINDMAP.md`** - Original Mermaid mindmap (best for GitHub viewing)
2. **`ONYX-MINDMAP-FOR-MIRO.csv`** - CSV format for MIRO import
3. **`ONYX-MINDMAP-HIERARCHICAL.txt`** - Human-readable hierarchical text format

---

## Option 1: Import to MIRO

### Method A: CSV Import (Recommended)

1. **Open MIRO** and create a new board or open an existing one

2. **Import CSV**:
   - Click **"..."** (More) in the left toolbar
   - Select **"Import"** → **"Mind map from CSV"**
   - Upload `ONYX-MINDMAP-FOR-MIRO.csv`

3. **Configure Import**:
   - **Topic Column**: `Topic`
   - **Parent Topic Column**: `Parent Topic`
   - **Description Column**: `Description` (optional)
   - Click **"Import"**

4. **Result**: MIRO will create an interactive mind map with all 300+ nodes organized hierarchically

### Method B: Manual Creation (More Control)

1. **Copy Hierarchical Format**:
   - Open `ONYX-MINDMAP-HIERARCHICAL.txt`
   - Copy the entire structure

2. **Create Mind Map**:
   - In MIRO, click **"Mind map"** tool in left toolbar
   - Create root node: **"ONYX Enterprise AI Search"**

3. **Paste Structure**:
   - Right-click on root node → **"Add child nodes from text"**
   - Paste the hierarchical structure
   - MIRO will parse the indentation and create nodes

4. **Customize**:
   - Color-code branches (Auth=Red, Connectors=Blue, etc.)
   - Add icons to major categories
   - Add sticky notes with extraction guidance

---

## Option 2: Import to Excalidraw

Excalidraw doesn't have direct CSV import, but you can create an interactive diagram:

### Method A: Manual Recreation (Best Visual Result)

1. **Open Excalidraw** (https://excalidraw.com/)

2. **Create Root Node**:
   - Draw an ellipse in the center
   - Label it: **"ONYX Enterprise AI Search"**

3. **Add Major Branches**:
   Use `ONYX-MINDMAP-HIERARCHICAL.txt` as reference:
   - Draw 10 rectangles around the root (one for each major category)
   - Label them with emojis:
     - 🔐 AUTH & ACCESS
     - 🔌 CONNECTORS (50+)
     - 📄 DOCUMENT PROCESSING
     - 🔍 VECTOR SEARCH
     - 💬 CHAT & LLM
     - ⚙️ BACKGROUND JOBS
     - 🗄️ DATABASE
     - 🌐 API SERVER
     - 📊 EE FEATURES
     - 🎨 FRONTEND
     - 🛠️ INFRASTRUCTURE

4. **Add Sub-branches**:
   - For each major branch, create sub-rectangles
   - Connect with arrows
   - Use different colors for each major branch

5. **Add Details**:
   - Add text boxes with file paths
   - Add sticky notes for extraction guidance
   - Group related components

6. **Export**:
   - File → Export image → SVG/PNG
   - Or: File → Save to → Save as Excalidraw JSON

### Method B: Import from Text

1. **Open Excalidraw**

2. **Use TTM Plugin** (Text-to-Mind-map):
   - Install TTM library extension if available
   - Or manually paste hierarchical structure into text tool
   - Excalidraw will auto-layout based on indentation

3. **Refine Layout**:
   - Drag nodes to organize
   - Add colors and icons
   - Group related elements

---

## Option 3: Other Tools

### Obsidian Canvas

1. Create new canvas in Obsidian
2. Copy `ONYX-MINDMAP-HIERARCHICAL.txt`
3. Paste as markdown notes
4. Manually link nodes

### Figma / FigJam

1. Import `ONYX-MINDMAP-FOR-MIRO.csv`
2. Use FigJam's mind map plugin
3. Auto-generate from CSV

### XMind / MindMeister

1. Import CSV directly
2. These tools natively support CSV mind map import
3. Export as image or interactive HTML

---

## Tips for Best Results

### Color Coding Recommendations

Use these colors to distinguish major branches:

- **🔐 Auth**: Red (#FF6B6B)
- **🔌 Connectors**: Blue (#4ECDC4)
- **📄 Doc Processing**: Orange (#FFA500)
- **🔍 Vector Search**: Purple (#9B59B6)
- **💬 Chat & LLM**: Green (#2ECC71)
- **⚙️ Background Jobs**: Yellow (#F1C40F)
- **🗄️ Database**: Brown (#8B4513)
- **🌐 API Server**: Cyan (#3498DB)
- **📊 EE Features**: Gold (#FFD700)
- **🎨 Frontend**: Pink (#E91E63)
- **🛠️ Infrastructure**: Gray (#95A5A6)

### Highlighting High-Value Components

Mark these with ⭐ or bright colors (for Knowsee extraction):

- **User Groups** (EE) - Essential for agency multi-client setup
- **Standard Answers** (EE) - FAQ automation
- **Query History & Analytics** (EE) - Client usage tracking
- **Token Rate Limiting** (EE) - Cost control per client
- **DLT Integration** - Your main goal (marketing connectors)

### Layout Suggestions

**Radial Layout** (recommended for MIRO):
- Root in center
- 11 major branches radiating outward
- Sub-branches extending from each

**Hierarchical Layout** (recommended for Excalidraw):
- Root at top
- Major branches in second tier
- Sub-branches flowing downward
- Left-to-right reading order

**Freeform Layout** (for detailed exploration):
- Group related components spatially
- Use colors to show relationships
- Add annotations for extraction guidance

---

## Using the Mindmap for Knowsee Extraction

### Step 1: Mark What to Extract (Green)
- Connector framework (~300 LOC)
- OAuth flow (~150 LOC)
- User groups [EE] (~500 LOC)
- Standard answers [EE] (~300 LOC)
- Query history [EE] (~200 LOC)

### Step 2: Mark What to Replace (Yellow)
- Vespa → Pinecone
- Custom chunking → LangChain
- 9 Celery workers → 1 worker
- FastAPI-Users → NextAuth.js

### Step 3: Mark What to Skip (Red)
- Multi-tenancy (10,000 LOC)
- External permission sync (4,000 LOC)
- Federated search (2,000 LOC)
- SlackBot (3,000 LOC)

### Step 4: Add Extraction Paths
For each green component, add a note with:
- File paths to copy
- Dependencies required
- Estimated LOC
- Knowsee integration point

---

## Collaboration Tips

### For MIRO

1. **Share Board** with team members
2. **Add Comments** on specific nodes for questions
3. **Create Frames** around related components
4. **Use Sticky Notes** for extraction tasks
5. **Tag Team Members** for assignments

### For Excalidraw

1. **Export as JSON** for version control
2. **Share Link** with team (excalidraw.com supports real-time collab)
3. **Add Text Annotations** with `@username` tags
4. **Group Elements** with color-coded rectangles
5. **Use Libraries** to create reusable components

---

## Next Steps After Import

1. **Review the Mindmap**: Understand the complete Onyx architecture
2. **Identify Dependencies**: Map out which components depend on others
3. **Plan Extraction Order**: Use the 7-day plan from `EXTRACTION-BLUEPRINT.md`
4. **Create Task Breakdown**: Assign components to team members
5. **Track Progress**: Move completed extractions to "Done" section

---

## Troubleshooting

### CSV Import Fails in MIRO

- **Issue**: MIRO doesn't recognize CSV format
- **Fix**: Save CSV as UTF-8, ensure no special characters in first row
- **Alternative**: Use Method B (Manual Creation)

### Excalidraw Layout Looks Messy

- **Issue**: Too many nodes overlap
- **Fix**: Start with major branches only, add sub-branches gradually
- **Tip**: Use **Arrange → Auto-layout** if available

### Text Too Small to Read

- **Issue**: 300+ nodes make text tiny
- **Fix**: Create separate boards/canvases for each major branch
- **Tip**: Use zoom feature extensively

### Want Interactive Features

- **MIRO**: Use frames, sticky notes, and mind map connectors
- **Excalidraw**: Use links and embeds for interactivity
- **Alternative**: Consider Obsidian Canvas for markdown-based approach

---

## Additional Resources

- **Original Mermaid**: View on GitHub for reference
- **Extraction Blueprint**: See `EXTRACTION-BLUEPRINT.md` for detailed extraction guide
- **Decision Framework**: See `DECISION-FRAMEWORK.md` for build vs extract analysis
- **Quick Start**: See `QUICK-START.md` for running Onyx locally

---

## Questions?

If you need help importing or customizing the mindmap, refer to:
- MIRO Help: https://help.miro.com/
- Excalidraw Docs: https://docs.excalidraw.com/
- Mermaid Live Editor: https://mermaid.live/ (for testing Mermaid syntax)
