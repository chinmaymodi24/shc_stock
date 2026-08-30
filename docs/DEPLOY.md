# SHC Stock — Free Deployment (Render + Neon)

Existing Firebase site `https://shc-stock.web.app` ne **kai touch nથી karvanu**.
Live app navo Render URL par aavse.

## 1. Neon — Database (free, kayam)

1. https://neon.tech par Google thi signup → **New Project** (region: `aws-ap-south-1` / Singapore).
2. Dashboard → **Connection string** ma be URL male:
   - **Pooled** (host ma `-pooler`) → aa `DATABASE_URL`
   - **Direct** (એ j, `-pooler` vagar) → aa `DIRECT_URL`
   Bંne ma `?sslmode=require` hovu joie.

## 2. GitHub

Repo GitHub par hovu joie (private chalse). `render.yaml` repo root ma chhe.

## 3. Render — API + Web

1. https://render.com par signup → **New → Blueprint** → GitHub repo select karo.
2. Render `render.yaml` vanchi ne **2 service** banavse: `shc-stock-api`, `shc-stock-web`.
3. `shc-stock-api` na env ma paste karo:
   - `DATABASE_URL` = Neon pooled URL
   - `DIRECT_URL` = Neon direct URL
4. Deploy thava do. `npm run build` → `prisma migrate deploy` DB ma tables banavse.

### First deploy pachhi (URL fix)

Render `shc-stock-api` ne real URL aape chhe, jem `https://shc-stock-api-xxxx.onrender.com`.

1. `shc-stock-web` → Environment → build command / `API_URL` ma aa real URL mukо
   (athva `render.yaml` ma badline push karo).
2. `shc-stock-api` → `CORS_ORIGINS` ma `shc-stock-web` no URL umeרo:
   `https://shc-stock-web-xxxx.onrender.com,https://shc-stock.web.app`
3. Bંne service **Manual Deploy → Clear build cache & deploy**.

## 4. Seed data (ek vaar)

Render `shc-stock-api` → **Shell** tab:

```
npm run seed
```

(admin user + products + base data). Clients/transactions mate `node prisma/seedClients.js` etc. jem joie tem.

## 5. Cold start (free tier)

15 min idle pachhi API sleep → pehli request ~40s slow.
Fix: https://cron-job.org (free) → dar 10 min `https://shc-stock-api-xxxx.onrender.com/health` GET.

## 6. File uploads note

Render disk ephemeral chhe — deploy/restart e `uploads/` ni images gum. Kayam rakhva
mate pachhi Cloudinary par move karvu (alag task).

## Local dev

Kai badlayu nથી. `backend/.env` ma `DIRECT_URL` add karyu (DATABASE_URL jevu j).
`flutter run` API_URL vagar → localhost:4000 vापરે jem pehla.
