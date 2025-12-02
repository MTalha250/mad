import mongoose, { Schema, Document } from "mongoose";

export interface IInvoice extends Document {
  invoiceReference: string;
  invoiceDate: Date | null;
  amount: string;
  paymentTerms: "Cash" | "Credit";
  creditDays?: string;
  dueDate: Date | null;
  project: mongoose.Types.ObjectId;
  status: "Pending" | "In Progress" | "Completed" | "Cancelled";
  createdBy: mongoose.Types.ObjectId;
}

const InvoiceSchema = new Schema<IInvoice>(
  {
    invoiceReference: {
      type: String,
      trim: true,
    },
    invoiceDate: {
      type: Date,
      default: null,
    },
    amount: {
      type: String,
      required: true,
      trim: true,
    },
    paymentTerms: {
      type: String,
      enum: ["Cash", "Credit"],
      required: true,
      default: "Cash",
    },
    creditDays: {
      type: String,
      default: "",
      trim: true,
    },
    dueDate: {
      type: Date,
      default: null,
    },
    project: {
      type: Schema.Types.ObjectId,
      ref: "Project",
      required: true,
    },
    status: {
      type: String,
      enum: ["Pending", "In Progress", "Completed", "Cancelled"],
      default: "Pending",
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

InvoiceSchema.index({ project: 1 });
InvoiceSchema.index({ status: 1 });
InvoiceSchema.index({ paymentTerms: 1 });
InvoiceSchema.index({ dueDate: 1 });
InvoiceSchema.index({ invoiceDate: 1 });
InvoiceSchema.index({ createdBy: 1 });

const Invoice = mongoose.model<IInvoice>("Invoice", InvoiceSchema);

export default Invoice;
