# Knowsee Quick Start

## 🚀 Get Running in 3 Steps

### 1. Get Google API Key (2 minutes)

Visit: **https://makersuite.google.com/app/apikey**
- Sign in with Google account
- Click "Create API Key"
- Copy the key

### 2. Configure Agent

```bash
cd apps/frontend/agent
```

Edit `.env` file:
```bash
GOOGLE_API_KEY=paste_your_actual_key_here
```

### 3. Start Development Server

```bash
cd apps/frontend
npm run dev
```

This starts BOTH:
- Frontend UI: http://localhost:3000
- Agent Backend: http://localhost:8000

---

## ✅ Test It

Open **http://localhost:3000** in your browser.

You should see:
- Purple background with "Knowsee" branding
- Chat sidebar on the right
- **No zoom issues** (if on mobile/Safari)

Try asking: "Write a proverb about data engineering"

---

## 🔧 Safari Zoom Issues Fixed

The following fixes prevent iOS Safari auto-zoom:

1. **Viewport**: `maximumScale: 1, userScalable: false` in layout.tsx
2. **Font-size**: All inputs forced to 16px minimum in globals.css
3. **Text-size-adjust**: Prevents automatic text resizing

---

## 📂 Project Structure

```
apps/frontend/
├── src/app/
│   ├── page.tsx          # Main UI (30 lines)
│   ├── layout.tsx        # Viewport config
│   └── globals.css       # Zoom fix CSS
├── agent/
│   ├── agent.py          # ADK agent logic
│   └── .env              # API key config
└── package.json
```

---

## 🎯 Next Steps

1. **Customize Agent**: Edit `apps/frontend/agent/agent.py`
2. **Add Tools**: Implement Google Drive search, etc.
3. **Update Branding**: Modify `src/app/page.tsx` colors/text
4. **Deploy**: See deployment docs when ready

---

## ⚠️ Troubleshooting

**"Missing key inputs argument" error:**
- Check `.env` file exists in `apps/frontend/agent/`
- Verify API key is correctly pasted (no extra spaces)
- Restart servers: `npm run dev`

**Zoom still happening:**
- Hard refresh browser (Cmd+Shift+R)
- Clear browser cache
- Check Safari settings → Accessibility → Zoom is off

**Port 8000 already in use:**
```bash
lsof -ti:8000 | xargs kill -9
npm run dev
```

---

## 📚 Documentation

- [CopilotKit Docs](https://docs.copilotkit.ai)
- [Google ADK Docs](https://google.github.io/adk-docs/)
- [Get API Key](https://makersuite.google.com/app/apikey)
