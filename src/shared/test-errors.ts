import { AppError } from "./errors.js";

try {
  throw new AppError(
    "Customer not found",
    404,
    "CUSTOMER_NOT_FOUND",
  );
} catch (error) {
  if (error instanceof AppError) {
    console.log("Message:", error.message);
    console.log("Status:", error.statusCode);
    console.log("Code:", error.code);
    console.log("Operational:", error.isOperational);
  }
}