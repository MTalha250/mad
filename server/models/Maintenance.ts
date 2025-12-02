import mongoose, { Schema, Document } from "mongoose";

const Value = new Schema(
  {
    value: {
      type: String,
      default: "",
      trim: true,
    },
    isEdited: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
    _id: false,
  }
);

export interface IMaintenance extends Document {
  clientName: string;
  remarks: {
    value: string;
    isEdited: boolean;
    createdAt: Date;
    updatedAt: Date;
  };
  serviceDates: Array<{
    serviceDate: Date;
    actualDate: Date | null;
    jcReference: string;
    invoiceRef: string;
    paymentStatus: "Pending" | "Paid" | "Overdue" | "Cancelled";
    isCompleted: boolean;
    month: number; // 1-12
    year: number;
  }>;
  users: mongoose.Types.ObjectId[];
  status: "Pending" | "In Progress" | "Completed" | "Cancelled";
  createdBy: mongoose.Types.ObjectId;
}

const ServiceDateSchema = new Schema(
  {
    serviceDate: {
      type: Date,
      required: true,
    },
    actualDate: {
      type: Date,
      default: null,
    },
    jcReference: {
      type: String,
      default: "",
      trim: true,
    },
    invoiceRef: {
      type: String,
      default: "",
      trim: true,
    },
    paymentStatus: {
      type: String,
      enum: ["Pending", "Paid", "Overdue", "Cancelled"],
      default: "Pending",
    },
    isCompleted: {
      type: Boolean,
      default: false,
    },
    month: {
      type: Number,
      required: true,
      min: 1,
      max: 12,
    },
    year: {
      type: Number,
      required: true,
    },
  },
  {
    _id: false,
  }
);

const MaintenanceSchema = new Schema<IMaintenance>(
  {
    clientName: {
      type: String,
      required: true,
      trim: true,
    },
    remarks: {
      type: Value,
      default: () => ({}),
    },
    serviceDates: {
      type: [ServiceDateSchema],
      default: [],
    },
    users: {
      type: [mongoose.Schema.Types.ObjectId],
      ref: "User",
      default: [],
    },
    status: {
      type: String,
      enum: ["Pending", "In Progress", "Completed", "Cancelled"],
      default: "Pending",
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

const Maintenance = mongoose.model<IMaintenance>(
  "Maintenance",
  MaintenanceSchema
);

export default Maintenance;
