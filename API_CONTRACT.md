# EaszyGoo Backend API Contract (Draft)

Base path: `/api`

Auth: JWT via `Authorization: Bearer <access>` unless otherwise noted.

## Authentication

### POST `/api/auth/login/`
Login (mock OTP).

- Auth: none
- Body (JSON):
  - `phone` (string)
  - `otp` (string)
- Success: `200 OK`
  - `user`: `{ id, name, phone, role, created_at }`
  - `access`: string (JWT)
  - `refresh`: string (JWT)
  - `otp_mode`: "mock"
  - `mock_otp`: "0000"
- Errors:
  - `400 Bad Request` for invalid payload / OTP

Example request:
```json
{ "phone": "9876543210", "otp": "0000" }
```

### POST `/api/auth/token/refresh/`
Refresh access token.

- Auth: none
- Body (JSON):
  - `refresh` (string)
- Success: `200 OK` with `access`

### GET `/api/auth/me/`
Get current user.

- Auth: required
- Success: `200 OK` → `{ id, name, phone, role, created_at }`

## Riders

All rider endpoints require:
- Auth: required
- Role: `rider`

### GET `/api/riders/me/`
Returns rider profile.

Success: `200 OK`
```json
{
  "user_id": "uuid",
  "name": "...",
  "phone": "...",
  "is_online": false,
  "kyc_status": "pending|approved|rejected",
  "current_lat": "12.971600",
  "current_lng": "77.594600"
}
```

### POST `/api/riders/toggle-online/`
Set online status.

- Body (JSON): `{ "is_online": true }`
- Success: `200 OK` → Rider profile (same as `/me`)

### POST `/api/riders/update-location/`
Update rider location.

- Body (JSON):
```json
{ "current_lat": 12.9716, "current_lng": 77.5946 }
```
- Success: `200 OK` → Rider profile

## Orders

All order endpoints require:
- Auth: required
- Role: `rider`

### GET `/api/orders/assigned-active/`
Return the currently assigned active order for the rider.

- Success: `200 OK` → Order
- Errors: `404 Not Found` → `{ "detail": "No active order" }`

### POST `/api/orders/{id}/accept/`
Accept a placed order.

- Success: `200 OK` → Order
- Errors: `400 Bad Request` with `{ "detail": "..." }`

### POST `/api/orders/{id}/picked/`
Mark order picked up.

- Success: `200 OK` → Order
- Errors: `400 Bad Request`

### POST `/api/orders/{id}/delivered/`
Mark order delivered.

- Success: `200 OK` → Order
- Errors: `400 Bad Request`

### GET `/api/orders/earnings-summary/`
Summary of delivered orders.

- Success: `200 OK`
```json
{ "delivered_orders": 0, "total_delivered_amount": "0.00" }
```

### Order shape
Returned by order endpoints:
```json
{
  "id": "uuid",
  "customer_id": "uuid",
  "vendor_id": 1,
  "vendor_name": "Shop Name",
  "rider_id": 1,
  "status": "placed|accepted|ready|picked|delivered|cancelled",
  "total_amount": "123.45",
  "created_at": "2026-02-04T00:00:00Z",
  "updated_at": "2026-02-04T00:00:00Z",
  "items": [
    { "product_id": "uuid", "product_name": "...", "quantity": 1, "price": "12.34" }
  ]
}
```

## KYC

All KYC endpoints require:
- Auth: required
- Role: `rider`

### GET `/api/kyc/status/`
Return whether KYC exists and its status.

- Success: `200 OK`
```json
{ "submitted": true, "status": "pending|approved|rejected" }
```
If not submitted:
```json
{ "submitted": false, "status": null }
```

### POST `/api/kyc/submit/`
Submit (or re-submit) rider KYC.

- Content-Type: `multipart/form-data`
- Fields:
  - `aadhaar_front` (image)
  - `aadhaar_back` (image)
  - `pan` (image)
  - `license` (image)
  - `rc` (image)
  - `selfie` (image)
  - `bank_account` (string)
  - `ifsc` (string)
- Success: `201 Created` → KYC record

### KYC record shape
Returned by submit:
```json
{
  "id": 1,
  "rider": 1,
  "aadhaar_front": "/media/kyc/...",
  "aadhaar_back": "/media/kyc/...",
  "pan": "/media/kyc/...",
  "license": "/media/kyc/...",
  "rc": "/media/kyc/...",
  "selfie": "/media/kyc/...",
  "bank_account": "...",
  "ifsc": "HDFC0001234",
  "status": "pending|approved|rejected",
  "created_at": "...",
  "updated_at": "..."
}
```

## Notes

- Default DRF permission is authenticated; only `/api/auth/login/` and `/api/auth/token/refresh/` are public.
- Media files are served only in `DEBUG=true` by Django URL config.
- OTP is currently mocked server-side (`0000`).
