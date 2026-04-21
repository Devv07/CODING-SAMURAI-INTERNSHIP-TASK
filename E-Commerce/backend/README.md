# Maison E-Commerce Backend API

A RESTful Node.js backend service powering the Maison e-commerce application. This API handles authentication, product management, orders, and shopping cart functionality. It is designed to work seamlessly with a Flutter frontend using Firebase Authentication.

---

## Tech Stack

* **Node.js** — Runtime environment
* **Express.js** — Web framework
* **Firebase Authentication** — User authentication
* **MongoDB / Database** — Data persistence
* **JWT (Firebase ID Token)** — Secure API authorization

---

## Getting Started

Follow these steps to run the backend locally.

```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

The server will start in development mode with hot reloading enabled.

---

## Environment Variables

Create a `.env` file in the `backend` directory and configure the following variables:

```env
PORT=5000
MONGO_URI=your_database_connection_string
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email
```

> **Note:** Never commit your `.env` file to version control.

---

## Base URL

```
http://localhost:5000
```

---

## Authentication

Protected routes require a valid Firebase ID token in the request header.

```http
Authorization: Bearer <Firebase ID Token>
```

---

## API Endpoints

### Health Check

| Method | Endpoint  | Auth Required | Description                           |
| ------ | --------- | ------------- | ------------------------------------- |
| GET    | `/health` | No            | Verify that the API server is running |

---

## Authentication & User Profile

| Method | Endpoint    | Auth Required | Description                               |
| ------ | ----------- | ------------- | ----------------------------------------- |
| GET    | `/api/auth` | Yes           | Retrieve the authenticated user's profile |
| POST   | `/api/auth` | Yes           | Create or update the user profile         |
| DELETE | `/api/auth` | Yes           | Delete the user account permanently       |

---

## Products

| Method | Endpoint                   | Auth Required | Description                                                  |
| ------ | -------------------------- | ------------- | ------------------------------------------------------------ |
| GET    | `/api/products`            | No            | Retrieve a list of products (supports filtering and sorting) |
| GET    | `/api/products/categories` | No            | Retrieve all product categories                              |
| GET    | `/api/products/:id`        | No            | Retrieve details of a specific product                       |

---

## Orders

| Method | Endpoint                 | Auth Required | Description                                    |
| ------ | ------------------------ | ------------- | ---------------------------------------------- |
| GET    | `/api/orders`            | Yes           | Retrieve all orders for the authenticated user |
| POST   | `/api/orders`            | Yes           | Create a new order                             |
| GET    | `/api/orders/:id`        | Yes           | Retrieve details of a specific order           |
| PATCH  | `/api/orders/:id/cancel` | Yes           | Cancel an existing order                       |

---

## Cart

| Method | Endpoint         | Auth Required | Description                                     |
| ------ | ---------------- | ------------- | ----------------------------------------------- |
| GET    | `/api/cart`      | Yes           | Retrieve the user's shopping cart               |
| POST   | `/api/cart/sync` | Yes           | Synchronize cart data between client and server |
| DELETE | `/api/cart`      | Yes           | Remove all items from the cart                  |

---

## Request & Response Examples

### Example: Create Order

**Request**

```http
POST /api/orders
Authorization: Bearer <Firebase ID Token>
Content-Type: application/json
```

```json
{
  "items": [
    {
      "productId": "12345",
      "quantity": 2
    }
  ],
  "totalAmount": 199.99
}
```

**Response**

```json
{
  "success": true,
  "message": "Order placed successfully",
  "orderId": "ORD-001"
}
```

---

## Standard Response Format

All API responses follow a consistent structure.

```json
{
  "success": true,
  "data": {},
  "message": "Optional message"
}
```

---

## Error Handling

Common HTTP status codes returned by the API:

| Status Code | Meaning                                 |
| ----------- | --------------------------------------- |
| 200         | Success                                 |
| 201         | Resource created successfully           |
| 400         | Bad request                             |
| 401         | Unauthorized (invalid or missing token) |
| 403         | Forbidden                               |
| 404         | Resource not found                      |
| 500         | Internal server error                   |

---

## Authentication Flow

```
Flutter App
     |
     v
Firebase Authentication (Login / Signup)
     |
     v
Firebase returns ID Token
     |
     v
Flutter sends token to Backend API
     |
     v
Backend verifies token and processes request
```

---

## Development Notes

* Use `npm run dev` for development
* Use `npm start` for production
* Ensure Firebase Admin SDK credentials are properly configured
* Keep environment variables secure

---

## Maintainer

**Maison E-Commerce Backend**
Node.js REST API for internship / production-ready e-commerce application.
