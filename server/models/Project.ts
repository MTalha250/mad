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

export interface IProject extends Document {
  clientName: string;
  description: string;
  po: {
    value: string;
    isEdited: boolean;
    createdAt: Date;
    updatedAt: Date;
  };
  quotation: {
    value: string;
    isEdited: boolean;
    createdAt: Date;
    updatedAt: Date;
  };
  remarks: {
    value: string;
    isEdited: boolean;
    createdAt: Date;
    updatedAt: Date;
  };
  surveyPhotos: string[];
  surveyDate: Date | null;
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
  status: "Pending" | "In Progress" | "Completed" | "Cancelled";
  users: mongoose.Types.ObjectId[];
  dueDate: Date | null;
  createdBy: mongoose.Types.ObjectId;
}

const ProjectSchema = new Schema<IProject>(
  {
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
    quotation: {
      type: Value,
      default: () => ({ value: "", isEdited: false }),
    },
    remarks: {
      type: Value,
      default: () => ({ value: "", isEdited: false }),
    },
    surveyPhotos: [
      {
        type: String,
      },
    ],
    surveyDate: {
      type: Date,
      default: null,
    },
    jcReferences: [Value],
    dcReferences: [Value],
    status: {
      type: String,
      enum: ["Pending", "In Progress", "Completed", "Cancelled"],
      default: "Pending",
    },
    users: [
      {
        type: Schema.Types.ObjectId,
        ref: "User",
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
  },
  {
    timestamps: true,
  }
);

ProjectSchema.index({ clientName: 1 });
ProjectSchema.index({ status: 1 });
ProjectSchema.index({ createdBy: 1 });
ProjectSchema.index({ dueDate: 1 });
ProjectSchema.index({ "po.value": 1 });
ProjectSchema.index({ "quotation.value": 1 });
ProjectSchema.index({ "jcReferences.value": 1 });
ProjectSchema.index({ "dcReferences.value": 1 });

const Project = mongoose.model<IProject>("Project", ProjectSchema);

export default Project;
