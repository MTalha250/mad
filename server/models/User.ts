import mongoose, { Schema, Document } from "mongoose";

export interface IUser extends Document {
  name: string;
  email: string;
  phone: string;
  password: string;
  role: "director" | "admin" | "head" | "user";
  department?: "accounts" | "technical" | "it" | "sales" | "store";
  status: "Pending" | "Approved" | "Rejected";
  assignedComplaints: mongoose.Types.ObjectId[];
  assignedProjects: mongoose.Types.ObjectId[];
  resetCode?: string;
  resetCodeExpires?: Date;
  pushToken?: string;
}

const UserSchema = new Schema<IUser>(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
      trim: true,
    },
    password: {
      type: String,
      required: true,
    },
    role: {
      type: String,
      enum: ["director", "admin", "head", "user"],
      required: true,
    },
    department: {
      type: String,
      enum: ["accounts", "technical", "it", "sales", "store"],
      required: function (this: IUser) {
        return this.role === "head";
      },
    },
    status: {
      type: String,
      enum: ["Pending", "Approved", "Rejected"],
      default: "Pending",
    },
    assignedComplaints: [
      {
        type: Schema.Types.ObjectId,
        ref: "Complaint",
      },
    ],
    assignedProjects: [
      {
        type: Schema.Types.ObjectId,
        ref: "Project",
      },
    ],
    resetCode: {
      type: String,
    },
    resetCodeExpires: {
      type: Date,
    },
    pushToken: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

UserSchema.index({ role: 1 });
UserSchema.index({ department: 1 });
UserSchema.index({ status: 1 });
UserSchema.index({ role: 1, department: 1 });

const User = mongoose.model<IUser>("User", UserSchema);

export default User;
