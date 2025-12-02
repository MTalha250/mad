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

export interface IComplaint extends Document {
  complaintReference: string;
  clientName: string;
  description: string;
  po: {
    value: string;
    isEdited: boolean;
    createdAt: Date;
    updatedAt: Date;
  };
  visitDates: Date[];
  dueDate: Date | null;
  createdBy: mongoose.Types.ObjectId;
  users: mongoose.Types.ObjectId[];
  jcReferences: Array<{
    value: string;
    isEdited: boolean;
    createdAt: Date;
    updatedAt: Date;
  }>;
  dcReferences: Array<{
    value: string;
    isEdited: boolean;
    createdAt: Date;
    updatedAt: Date;
  }>;
  quotation: {
    value: string;
    isEdited: boolean;
    createdAt: Date;
    updatedAt: Date;
  };
  photos: string[];
  priority: "Low" | "Medium" | "High";
  remarks: {
    value: string;
    isEdited: boolean;
    createdAt: Date;
    updatedAt: Date;
  };
  status: "Pending" | "In Progress" | "Completed" | "Cancelled";
}

const ComplaintSchema = new Schema<IComplaint>(
  {
    complaintReference: {
      type: String,
      trim: true,
    },
    clientName: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    po: {
      type: Value,
      default: () => ({ value: "", isEdited: false }),
    },
    visitDates: [
      {
        type: Date,
      },
    ],
    dueDate: {
      type: Date,
      default: null,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    users: [
      {
        type: Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    jcReferences: [Value],
    dcReferences: [Value],
    quotation: {
      type: Value,
      default: () => ({ value: "", isEdited: false }),
    },
    photos: [
      {
        type: String,
      },
    ],
    priority: {
      type: String,
      enum: ["Low", "Medium", "High"],
      default: "Medium",
    },
    remarks: {
      type: Value,
      default: () => ({ value: "", isEdited: false }),
    },
    status: {
      type: String,
      enum: ["Pending", "In Progress", "Completed", "Cancelled"],
      default: "Pending",
    },
  },
  {
    timestamps: true,
  }
);

ComplaintSchema.index({ clientName: 1 });
ComplaintSchema.index({ status: 1 });
ComplaintSchema.index({ priority: 1 });
ComplaintSchema.index({ createdBy: 1 });
ComplaintSchema.index({ dueDate: 1 });
ComplaintSchema.index({ "po.value": 1 });
ComplaintSchema.index({ "quotation.value": 1 });
ComplaintSchema.index({ "jcReferences.value": 1 });
ComplaintSchema.index({ "dcReferences.value": 1 });

const Complaint = mongoose.model<IComplaint>("Complaint", ComplaintSchema);

export default Complaint;
