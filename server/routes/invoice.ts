import express from "express";
import {
  createInvoice,
  getInvoices,
  getInvoice,
  updateInvoice,
  deleteInvoice,
  getInvoicesByStatus,
  getInvoicesByPaymentTerms,
  getInvoicesByProject,
  getOverdueInvoices,
} from "../controllers/Invoice";
import { verifyToken, verifyAdmin, verifyHead } from "../middlewares";

const router = express.Router();

// All routes require authentication
router.use(verifyToken);

// GET routes
router.get("/", getInvoices); // Get all invoices
router.get("/overdue", getOverdueInvoices); // Get overdue invoices
router.get("/status/:status", getInvoicesByStatus); // Get invoices by status
router.get("/payment-terms/:paymentTerms", getInvoicesByPaymentTerms); // Get invoices by payment terms
router.get("/project/:projectId", getInvoicesByProject); // Get invoices by project
router.get("/:id", getInvoice); // Get single invoice

// POST routes
router.post("/", verifyHead, createInvoice); // Create invoice (head+ only)

// PUT routes
router.put("/:id", verifyHead, updateInvoice); // Update invoice (head+ only)

// DELETE routes
router.delete("/:id", verifyAdmin, deleteInvoice); // Delete invoice (admin+ only)

export default router;
