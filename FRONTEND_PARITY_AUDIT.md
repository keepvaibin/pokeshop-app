# Frontend Parity Audit

This file tracks the mobile app parity pass against the Next.js storefront/admin frontend and Django API.

## Storefront navigation

- Frontend source: `pokeshop-frontend/app/components/Navbar.tsx`
- Mobile implementation:
  - Standard users land on the storefront home route `/`.
  - Admin users land on `/admin` and get a separate admin bottom navigation.
  - Cart is a top app-bar action with badge state from the local cart controller.
  - Shop is a real bottom navigation destination for admins and standard users.

## Auth

- Frontend sources: `pokeshop-frontend/app/login/page.tsx`, `pokeshop-backend/users/views.py`
- API calls:
  - `POST /api/auth/login/` with `{ email, password }`
  - `POST /api/auth/google/` with `{ token }`
  - `GET /api/auth/user/`
- Mobile status:
  - Email login matches the backend payload.
  - Google sign-in sends the web/server client ID as `serverClientId`.
  - Android/iOS OAuth registration still depends on Google Cloud client setup outside the app.

## Shop/search

- Frontend source: `pokeshop-frontend/app/components/ShopLayout.tsx`
- API calls:
  - `GET /api/inventory/items/`
  - `GET /api/inventory/categories/`
- Matched query params:
  - `q`
  - `category`
  - `sort`
  - `in_stock=1`
  - `page`
- Mobile status:
  - Search now uses `q` instead of the older app-only `search` key.
  - Category chips use live category data.
  - Sort options use backend/frontend values: `featured`, `newest`, `price-low`, `price-high`, `name`, `stock-low`.
  - In-stock filtering uses `in_stock=1`.
  - Product stock now reads the backend `stock` field, fixing the all-sold-out display.

## Product cards/details

- Frontend sources: `ShopLayout.tsx`, product quick view/detail components.
- API calls:
  - `GET /api/inventory/items/<slug>/`
- Mobile status:
  - Product cards and detail screens now receive correct stock values from `stock`.
  - Cart access is available from the top bar on shop/product surfaces.

## Cart/checkout

- Frontend source: `pokeshop-frontend/app/cart/page.tsx`
- API calls:
  - `GET /api/orders/cart/`
  - `POST /api/orders/cart/sync/`
  - `POST /api/orders/checkout/`
  - `GET /api/orders/active-timeslots/`
  - `POST /api/orders/validate-coupon/`
- Mobile status:
  - Cart remains backed by local state plus backend-compatible checkout payloads.
  - Cart is no longer a primary bottom tab; it is a top action to match app ergonomics.

## Standard order history

- Frontend/backend sources: user order views and receipt endpoint.
- API calls:
  - `GET /api/orders/my-orders/`
  - `GET /api/orders/receipt/<order_id>/`
- Mobile status:
  - Standard users keep a standard Orders destination.
  - Shared order parsing now supports `items_summary`, `customer_email`, `user_email`, `discord_handle`, and `coupon_code` for richer order cards.

## Admin dashboard

- Frontend source: `pokeshop-frontend/app/components/AdminDashboard.tsx`
- Backend source: `pokeshop-backend/orders/views.py::AdminDashboardView`
- API calls:
  - `GET /api/orders/admin-dashboard/`
  - Optional/best-effort: `GET /api/orders/admin-metrics/`, `GET /api/orders/dispatch/`
- Mobile status:
  - Admin users default to `/admin`.
  - Dashboard reads `kpis`, `dispatch_queue`, and `promotions` from the real backend response.
  - Quick actions route to working mobile screens instead of no-op buttons.

## Admin order history

- Frontend source: `pokeshop-frontend/app/admin/orders/page.tsx`
- Backend source: `pokeshop-backend/orders/views.py::AdminOrderHistoryView`
- API calls:
  - `GET /api/orders/admin-history/`
- Mobile status:
  - Added a mobile-first Admin Orders screen at `/admin/orders`.
  - Supports local search across order id, customer email, Discord handle, coupon, item summary, and line titles.
  - Supports status filtering for all/current/pending/trade review/counteroffer/balance due/fulfilled/cancelled.

## Full frontend route checklist

Legend: `[x]` native mobile equivalent exists, `[~]` partial/mobile foundation exists, `[ ]` still needs a dedicated mobile implementation.

### Customer routes

- [x] `/` - mobile home uses live settings, homepage sections, all products, and new arrivals.
- [~] `/access` - mobile register validates access codes and creates accounts, but the web two-step access page copy/Discord onboarding is not fully mirrored.
- [x] `/cart` - mobile cart supports images, stock-clamped quantities, remove, totals, and checkout entry.
- [x] `/category/[slug]` - route opens the native shop with the slug preselected as the category filter.
- [~] `/checkout` - mobile checkout uses real checkout, active timeslots, coupons, trade cards, payment toggles, wallet credit, and merge-aware payloads; first-time explainer and every web edge-state still need parity review.
- [x] `/checkout/success` - mobile checkout navigates to order/receipt flows rather than a separate success page.
- [x] `/delivery-info` - native pickup/payment information page uses the shared live recurring timeslot selector.
- [x] `/login` - mobile email and Google auth use the real backend endpoints.
- [x] `/new-releases` - route opens the native shop with newest sorting.
- [x] `/orders` - mobile order history has responsive cards, thumbnails, pickup labels, totals, refresh, and receipt navigation.
- [x] `/orders/[orderId]` - mobile receipt has item images, pickup/payment, payment summary, counteroffer message, print invoice, and admin cancel/item-cancel controls on admin routes.
- [x] `/product/[itemSlug]` - mobile product detail uses real product API, local cart, stock-aware add, and image fallback.
- [x] `/products` - route aliases to the native shop product grid.
- [x] `/search` - mobile search uses the real shop query path.
- [x] `/settings` - profile details, bundled Pokémon profile picture popup, Discord connect/disconnect, invite link, and logout.
- [x] `/tcg`, `/tcg/accessories`, `/tcg/boxes`, `/tcg/cards` - routes open native shop surfaces with matching category filters.
- [~] `/trade-details/[id]` - mobile trade-in detail coverage is limited compared with web.
- [x] `/trade-in` - mobile standalone trade-in submission exists.
- [~] `/trade-in/history` and `/trade-in/[id]` - mobile has wallet/history surfaces, but detail parity needs review.

### Admin routes

- [x] `/admin/access-codes` - native CRUD for code, limit, expiry, active state, notes, usage display, and deletion.
- [~] `/admin/cards` - native searchable catalog and edit surface for stock/state/TCG metadata via admin cards + item APIs; bulk sync job controls remain web-deeper than mobile.
- [~] `/admin/categories` - native tabbed category/subcategory CRUD; tag editing remains web-deeper than mobile.
- [~] `/admin/coupons` - native CRUD for code, flat/percent discounts, usage limits, expiry, min total, active state, and cash-only; product/category targeting picker remains web-deeper than mobile.
- [~] `/admin/dispatch` - native dispatch exists with fixed counted tabs, overdue separation, fulfillment/trade/standalone trade queues, receipt links, cancel/fulfill/basic trade actions, and ASAP scheduling. Still needs full per-card partial review, counteroffer text flow, item-level cancel, reschedule sheet, and standalone trade funding actions.
- [~] `/admin/inventory` - native item CRUD/editing for title, descriptions, price, stock, image path, category/subcategory ids, limits, TCG metadata, release visibility, and active flags; image upload/order and TCG import workflow remain web-deeper than mobile.
- [x] `/admin/metrics` - native metrics page supports 7/30/90/all ranges, KPI cards, daily chart, top products, category revenue, payment methods, and status counts.
- [~] `/admin/orders` - native order history exists with search/status filters, receipt navigation, and admin receipt adjustment controls for full-order/item-level cancellation. Calculator and server-side pagination remain web-deeper than mobile.
- [x] `/admin/pos` - native POS supports user search, active inventory search, cart quantities, payment/delivery selection, scheduled pickup selector, Discord/admin notes, and admin order creation.
- [~] `/admin/promos` - native promo banner CRUD supports title/subtitle, image URL, link URL, size, order, active state, and deletion; image file upload/live preview remain web-deeper than mobile.
- [x] `/admin/settings` - native store settings now covers store config, payment/order/trade toggles, recurring pickup slots, admin profile/Discord linking, and signpost to customer profile preview.
- [x] `/admin/strikes` - native strike management supports user search, issue strike, list users with strikes, inspect strikes, and delete strikes.
- [x] `/admin/trade-ins` - native trade-in queue supports status filtering, card-level accept/reject review with overrides/counteroffers, approve, complete/fund, and reject.
- [x] `/admin/users` - native users page supports paginated search, profile cards with Pokémon icons, wallet/strike/order counts, detail sheet, current/recent orders, strikes, credit ledger, and admin credit grants.
- [~] `/admin/wanted` - native wanted-card CRUD supports name, description, estimated value, TCG product/variant link fields, active state, and deletion; full TCG search picker remains web-deeper than mobile.

### Shared frontend components that still need native parity checks

- [~] `Navbar` - mobile has route-aware shell, client centered Shop action, admin/client preview switch, and admin menu; dropdown category parity is partial.
- [~] `PokemonIconPicker` - mobile now uses bundled icon assets in a searchable popup and PATCHes the real profile icon id.
- [~] `PickupTimeslotSelector` - mobile checkout uses recurring slots; admin reschedule and all web validation copy still need parity.
- [x] `AdminOrderAdjustModal` - represented by native admin receipt adjustments for full-order cancellation and item-level cancellation.
- [~] `ProductPickerModal` - represented in native POS inventory search and admin resource search surfaces; coupon targeting picker remains web-deeper than mobile.
- [x] `AdminTradeInQueue` - represented by `/admin/trade-ins` plus Dispatch trade queues with review, approve, complete, and reject actions.

## Verification

- `flutter analyze`: clean
- `flutter test`: passing
- `flutter build apk --debug --no-pub`: passing
- Live API spot check confirmed product payloads use `stock`.
- Debug APK installed on `R3GL10M8GEX` and launched via Android SDK `adb`.
