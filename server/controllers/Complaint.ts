import { Complaint, User } from "../models";
import { Request, Response } from "express";
import { sendNotificationToAdmins, sendNotificationToUsers } from "./User";

interface ComplaintRequest {
  complaintReference?: string;
  clientName?: string;
  description?: string;
  po?: {
    value: string;
    isEdited: boolean;
  };
  visitDates?: Date[];
  dueDate?: Date;
  users?: string[];
  jcReferences?: Array<{
    value: string;
    isEdited: boolean;
  }>;
  dcReferences?: Array<{
    value: string;
    isEdited: boolean;
  }>;
  quotation?: {
    value: string;
    isEdited: boolean;
  };
  photos?: string[];
  priority?: "Low" | "Medium" | "High";
  remarks?: {
    value: string;
    isEdited: boolean;
  };
  status?: "Pending" | "In Progress" | "Completed" | "Cancelled";
}

const determineComplaintStatus = (
  jcReferences?: Array<{ value: string; isEdited: boolean }>,
  dcReferences?: Array<{ value: string; isEdited: boolean }>,
  users?: string[]
): "Pending" | "In Progress" | "Completed" | "Cancelled" => {
  const hasJcReferences = jcReferences && jcReferences.length > 0;
  const hasDcReferences = dcReferences && dcReferences.length > 0;
  const hasUsers = users && users.length > 0;

  if (hasJcReferences || hasDcReferences) {
    return "Completed";
  }

  if (hasUsers) {
    return "In Progress";
  }

  return "Pending";
};

export const createComplaint = async (
  req: Request<{}, {}, ComplaintRequest>,
  res: Response
): Promise<void> => {
  try {
    const {
      complaintReference,
      clientName,
      description,
      po,
      visitDates,
      dueDate,
      users,
      jcReferences,
      dcReferences,
      quotation,
      photos,
      priority,
      remarks,
    } = req.body;

    const autoStatus = determineComplaintStatus(
      jcReferences,
      dcReferences,
      users
    );

    const newComplaint = await Complaint.create({
      complaintReference: complaintReference || "",
      clientName: clientName || "",
      description: description || "",
      po: po || { value: "", isEdited: false },
      visitDates: visitDates || [],
      dueDate: dueDate || null,
      users: users || [],
      jcReferences: jcReferences || [],
      dcReferences: dcReferences || [],
      quotation: quotation || { value: "", isEdited: false },
      photos: photos || [],
      priority: priority || "Medium",
      remarks: remarks || { value: "", isEdited: false },
      status: autoStatus,
      createdBy: req.userId,
    });

    // Send email notification to directors and admins
    try {
      const creator = await User.findById(req.userId);
      const formattedDueDate = dueDate
        ? new Date(dueDate).toLocaleDateString()
        : "Not set";
      const formattedVisitDates =
        visitDates && visitDates.length > 0
          ? visitDates
              .map((date) => new Date(date).toLocaleDateString())
              .join(", ")
          : "No visits scheduled";

      await sendNotificationToAdmins(
        "New Complaint Created - TechnoTrends",
        `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #A82F39;">New Complaint Created</h2>
            <p>A new complaint has been submitted in the TechnoTrends system.</p>
            <div style="background-color: #f0f9ff; padding: 20px; margin: 20px 0; border-radius: 8px;">
              <h3 style="color: #A82F39; margin: 0 0 15px 0;">Complaint Details:</h3>
              ${
                complaintReference
                  ? `<p><strong>Reference:</strong> ${complaintReference}</p>`
                  : ""
              }
              <p><strong>Client Name:</strong> ${
                clientName || "Not specified"
              }</p>
              <p><strong>Description:</strong> ${
                description || "No description provided"
              }</p>
              <p><strong>Priority:</strong> <span style="color: ${
                priority === "High"
                  ? "#DC2626"
                  : priority === "Medium"
                  ? "#D97706"
                  : "#059669"
              };">${priority || "Medium"}</span></p>
              <p><strong>Status:</strong> ${autoStatus}</p>
              <p><strong>Due Date:</strong> ${formattedDueDate}</p>
              <p><strong>Visit Dates:</strong> ${formattedVisitDates}</p>
              ${
                po?.value
                  ? `<p><strong>PO Number:</strong> ${po.value}</p>`
                  : ""
              }
              ${
                quotation?.value
                  ? `<p><strong>Quotation:</strong> ${quotation.value}</p>`
                  : ""
              }
              <p><strong>Created By:</strong> ${creator?.name || "Unknown"} (${
          creator?.email || "No email"
        })</p>
              <p><strong>Created At:</strong> ${new Date().toLocaleString()}</p>
            </div>
            ${
              photos && photos.length > 0
                ? `<p><strong>Attachments:</strong> ${photos.length} photo(s) uploaded</p>`
                : ""
            }
            ${
              jcReferences && jcReferences.length > 0
                ? `<p><strong>JC References:</strong> ${jcReferences
                    .map((ref) => ref.value)
                    .join(", ")}</p>`
                : ""
            }
            ${
              dcReferences && dcReferences.length > 0
                ? `<p><strong>DC References:</strong> ${dcReferences
                    .map((ref) => ref.value)
                    .join(", ")}</p>`
                : ""
            }
            ${
              remarks?.value
                ? `<p><strong>Remarks:</strong> ${remarks.value}</p>`
                : ""
            }
            <p>Please review the complaint in the admin dashboard.</p>
            <hr style="margin: 30px 0;">
            <p style="color: #666; font-size: 12px;">
              This is an automated notification from TechnoTrends.
            </p>
          </div>
        `,
        "⚠️ New Complaint Submitted",
        `${creator?.name || "Someone"} submitted a ${(
          priority || "medium"
        ).toLowerCase()} priority complaint for ${clientName || "a client"}.`,
        {
          type: "complaint_created",
          complaintId: (newComplaint._id as any).toString(),
          clientName: clientName || "Unknown",
          priority: priority || "Medium",
        }
      );
    } catch (emailError) {
      console.error(
        "Failed to send complaint creation notification:",
        emailError
      );
    }

    res.status(201).json({
      message: "Complaint created successfully",
      complaint: newComplaint,
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getComplaints = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const complaints = await Complaint.find()
      .where("status")
      .ne("Cancelled")
      .populate("createdBy", "name email")
      .populate("users", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(complaints);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getComplaint = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;

    const complaint = await Complaint.findById(id)
      .populate("createdBy", "name email role")
      .populate("users", "name email role");

    if (!complaint) {
      res.status(404).json({ message: "Complaint not found" });
      return;
    }

    res.status(200).json(complaint);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const updateComplaint = async (
  req: Request<{ id: string }, {}, ComplaintRequest>,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const { jcReferences, dcReferences, users, ...updateData } = req.body;

    const currentComplaint = await Complaint.findById(id);
    if (!currentComplaint) {
      res.status(404).json({ message: "Complaint not found" });
      return;
    }

    const finalJcReferences =
      jcReferences !== undefined ? jcReferences : currentComplaint.jcReferences;
    const finalDcReferences =
      dcReferences !== undefined ? dcReferences : currentComplaint.dcReferences;
    const finalUsers =
      users !== undefined
        ? users
        : currentComplaint.users.map((u) => u.toString());
    const autoStatus = determineComplaintStatus(
      finalJcReferences,
      finalDcReferences,
      finalUsers
    );

    const updatedComplaint = await Complaint.findByIdAndUpdate(
      id,
      {
        ...updateData,
        jcReferences: finalJcReferences,
        dcReferences: finalDcReferences,
        users: finalUsers,
        status: autoStatus,
      },
      {
        new: true,
        runValidators: true,
      }
    )
      .populate("createdBy", "name email")
      .populate("users", "name email");

    if (!updatedComplaint) {
      res.status(404).json({ message: "Complaint not found" });
      return;
    }

    res.status(200).json({
      message: "Complaint updated successfully",
      complaint: updatedComplaint,
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const deleteComplaint = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;

    const complaint = await Complaint.findById(id);

    if (!complaint) {
      res.status(404).json({ message: "Complaint not found" });
      return;
    }

    complaint.status = "Cancelled";
    await complaint.save();

    res.status(200).json({ message: "Complaint deleted successfully" });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const assignUsersToComplaint = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const { userIds } = req.body;

    const currentComplaint = await Complaint.findById(id);
    if (!currentComplaint) {
      res.status(404).json({ message: "Complaint not found" });
      return;
    }

    const updatedComplaint = await Complaint.findByIdAndUpdate(
      id,
      { $addToSet: { users: { $each: userIds } } },
      { new: true }
    ).populate("users", "name email");

    if (!updatedComplaint) {
      res.status(404).json({ message: "Complaint not found" });
      return;
    }

    const userIdStrings = updatedComplaint.users.map((u) => u._id.toString());
    const autoStatus = determineComplaintStatus(
      currentComplaint.jcReferences,
      currentComplaint.dcReferences,
      userIdStrings
    );

    if (updatedComplaint.status !== autoStatus) {
      await Complaint.findByIdAndUpdate(id, { status: autoStatus });
      updatedComplaint.status = autoStatus;
    }

    // Send notifications to newly assigned users
    try {
      const currentUserIds = currentComplaint.users.map((u) => u.toString());
      const newlyAssignedUserIds = userIds.filter(
        (userId: string) => !currentUserIds.includes(userId)
      );

      if (newlyAssignedUserIds.length > 0) {
        const complaintWithDetails = await Complaint.findById(id).populate(
          "createdBy",
          "name"
        );

        await sendNotificationToUsers(
          newlyAssignedUserIds,
          "⚠️ New Complaint Assignment",
          `You've been assigned to complaint: ${
            complaintWithDetails?.clientName || "Unknown Client"
          }`,
          {
            type: "complaint_assigned",
            complaintId: id,
            clientName: complaintWithDetails?.clientName || "Unknown Client",
            priority: complaintWithDetails?.priority || "Medium",
          }
        );
      }
    } catch (notificationError) {
      console.error(
        "Failed to send assignment notifications:",
        notificationError
      );
    }

    res.status(200).json({
      message: "Users assigned to complaint successfully",
      complaint: updatedComplaint,
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getComplaintsByUser = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const complaints = await Complaint.find({
      users: { $in: [req.userId] },
    })
      .where("status")
      .ne("Cancelled")
      .populate("createdBy", "name email")
      .populate("users", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(complaints);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getComplaintsByStatus = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { status } = req.params;

    const complaints = await Complaint.find({ status })
      .where("status")
      .ne("Cancelled")
      .populate("createdBy", "name email")
      .populate("users", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(complaints);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getComplaintsByPriority = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { priority } = req.params;

    const complaints = await Complaint.find({ priority })
      .where("status")
      .ne("Cancelled")
      .populate("createdBy", "name email")
      .populate("users", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(complaints);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};
