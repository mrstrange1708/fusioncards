# 💰 Smart Expense Tracker with Insights

A mobile application built with **Flutter** (frontend) and **Node.js/Express** (backend) that allows users to track their expenses and view smart spending insights.

---

## 📐 Architecture

```
FusionCard/
├── backend/                  # Node.js REST API
│   ├── server.js             # Express entry point
│   ├── config/
│   │   ├── db.js             # PostgreSQL connection pool
│   │   └── initDb.js         # Database initialization script
│   ├── controllers/
│   │   └── expenseController.js   # CRUD + aggregation logic
│   ├── services/
│   │   └── insightService.js      # Smart insight engine
│   ├── routes/
│   │   └── expenses.js            # API route definitions
│   ├── package.json
│   └── .env                       # Environment variables
│
├── frontend/                 # Flutter mobile app
│   └── lib/
│       ├── main.dart               # App entry + navigation
│       ├── models/expense.dart     # Data models
│       ├── services/api_service.dart   # HTTP API client
│       ├── providers/expense_provider.dart  # State management
│       └── screens/
│           ├── add_expense_screen.dart     # Add expense form
│           ├── expense_list_screen.dart    # Grouped expense list
│           └── insights_screen.dart       # Analytics dashboard
│
└── README.md
```

## 🧠 Approach

### Backend
- **Node.js + Express** REST API with clean MVC architecture
- **PostgreSQL** (hosted on Neon) for persistent storage
- Raw SQL queries via `pg` library for optimal performance
- Auto-creates database tables and indexes on server startup
- 5 smart insight algorithms powered by PostgreSQL window functions and aggregations

### Frontend
- **Flutter** with Material 3 dark theme
- **Provider** for lightweight state management
- **fl_chart** for interactive pie charts
- Clean separation: Models → Services → Providers → Screens
- Responsive design with smooth animations

---

## 🔌 Backend Choice: Node.js + PostgreSQL

| Decision | Reasoning |
|----------|-----------|
| **Express.js** | Lightweight, widely-used, fast to prototype |
| **PostgreSQL** | Strong aggregation support (SUM, AVG, GROUP BY, window functions) ideal for analytics |
| **Neon** | Serverless PostgreSQL with free tier, zero infrastructure management |
| **Raw SQL** | Full control over complex analytical queries without ORM overhead |

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/health` | Health check |
| `POST` | `/api/expenses` | Add new expense |
| `GET` | `/api/expenses` | Fetch all expenses (supports `?category=`, `?startDate=`, `?endDate=`, `?groupBy=date\|category`) |
| `DELETE` | `/api/expenses/:id` | Delete expense |
| `GET` | `/api/expenses/aggregation` | Totals + category breakdown (`?period=week\|month`) |
| `GET` | `/api/expenses/insights` | Smart spending insights |

---

## 🧠 Smart Insights

The insight engine computes 5 types of analytics:

1. **Week-over-Week Comparison** — "You spent 40% more on Food this week compared to last week"
2. **Top Spending Category** — "Your biggest expense this month is Shopping (₹4,500)"
3. **Daily Average** — "You're spending ₹850/day this week"
4. **Spike Detection** — Flags categories where spending exceeds 1.5× the 4-week average
5. **Monthly Comparison** — "You've spent 25% more this month vs last month"

---

## 🚀 Setup & Running

### Backend

```bash
cd backend
npm install
node server.js
```

The server auto-creates the `expenses` table on startup.

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

> **Note:** Update the `baseUrl` in `lib/services/api_service.dart` to match your backend:
> - Android Emulator: `http://10.0.2.2:3000/api`
> - iOS Simulator: `http://localhost:3000/api`
> - Physical device: `http://<your-machine-ip>:3000/api`

---

## 📱 Screens

### 1. Add Expense
- Numeric amount input with ₹ prefix
- Category selection via animated chips (8 categories)
- Date picker (defaults to today)
- Optional note field
- Animated submit with haptic feedback

### 2. Expense List
- Toggle between **group by date** and **group by category**
- Pull-to-refresh
- Swipe-to-delete with confirmation dialog
- Running totals per group

### 3. Insights Dashboard
- Summary cards: Total spend, Transaction count, Daily average
- Interactive pie chart (category breakdown)
- Category progress bars with percentages
- Smart insight cards color-coded by severity

---

## ⚠️ Assumptions & Trade-offs

1. **No authentication** — Single-user app (hackathon scope)
2. **Currency** — ₹ (INR) hardcoded for display
3. **PostgreSQL on Neon** — Free tier, serverless, no infrastructure to manage
4. **No offline support** — Requires network connectivity to backend
5. **Provider** over Riverpod/Bloc — Simplest state management for this scope
6. **Raw SQL** over ORM — Better control for complex analytical queries

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x, Dart |
| State Management | Provider |
| Charts | fl_chart |
| Backend | Node.js, Express |
| Database | PostgreSQL (Neon) |
| HTTP Client | http (Dart) |
