import { Project, Invoice, User } from "../models";
import { Request, Response } from "express";
import mongoose from "mongoose";
import { sendNotificationToAdmins, sendNotificationToUsers } from "./User";

interface ProjectRequest {
  clientName?: string;
  description?: string;
  po?: {
    value: string;
    isEdited: boolean;
  };
  quotation?: {
    value: string;
    isEdited: boolean;
  };
  remarks?: {
    value: string;
    isEdited: boolean;
  };
  surveyDate?: Date;
  surveyPhotos?: string[];
  jcReferences?: Array<{
    value: string;
    isEdited: boolean;
  }>;
  dcReferences?: Array<{
    value: string;
    isEdited: boolean;
  }>;
  status?: "Pending" | "In Progress" | "Completed" | "Cancelled";
  users?: string[];
  dueDate?: Date;
}

const createInvoiceForProject = async (projectId: string, userId: string) => {
  try {
    const project = await Project.findById(projectId).populate(
      "createdBy",
      "name email"
    );

    const newInvoice = await Invoice.create({
      amount: "0",
      paymentTerms: "Cash",
      project: projectId,
      createdBy: userId,
    });
    // Send push notification to admins about automatic invoice creation
    try {
      await sendNotificationToAdmins(
        "Invoice Auto-Created - TechnoTrends",
        `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #A82F39;">Invoice Automatically Created</h2>
            <p>An invoice has been automatically created due to JC/DC references being added to a project.</p>
            <div style="background-color: #f0f9ff; padding: 20px; margin: 20px 0; border-radius: 8px;">
              <h3 style="color: #A82F39; margin: 0 0 15px 0;">Invoice Details:</h3>
              <p><strong>Project Client:</strong> ${
                project?.clientName || "Unknown Client"
              }</p>
              <p><strong>Invoice Reference:</strong> ${
                newInvoice.invoiceReference || "Not set"
              }</p>
              <p><strong>Amount:</strong> ${newInvoice.amount}</p>
              <p><strong>Payment Terms:</strong> ${newInvoice.paymentTerms}</p>
              <p><strong>Status:</strong> ${newInvoice.status}</p>
              <p><strong>Created At:</strong> ${new Date().toLocaleString()}</p>
            </div>
            <p>Please review and update the invoice details in the admin dashboard.</p>
            <hr style="margin: 30px 0;">
            <p style="color: #666; font-size: 12px;">
              This is an automated notification from TechnoTrends.
            </p>
          </div>
        `,
        "💰 Invoice Auto-Created",
        `An invoice was automatically created for project: ${
          project?.clientName || "Unknown Client"
        }`,
        {
          type: "invoice_created",
          invoiceId: (newInvoice._id as mongoose.Types.ObjectId).toString(),
          projectId: projectId,
          clientName: project?.clientName || "Unknown Client",
        }
      );
    } catch (notificationError) {
      console.error(
        "Failed to send invoice creation notification:",
        notificationError
      );
    }

    return newInvoice;
  } catch (error) {
    console.error("Error creating invoice:", error);
    throw error;
  }
};

const determineProjectStatus = (
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

export const createProject = async (
  req: Request<{}, {}, ProjectRequest>,
  res: Response
): Promise<void> => {
  try {
    const {
      clientName,
      description,
      po,
      quotation,
      remarks,
      surveyPhotos,
      jcReferences,
      dcReferences,
      users,
      dueDate,
    } = req.body;

    const autoStatus = determineProjectStatus(
      jcReferences,
      dcReferences,
      users
    );

    const newProject = await Project.create({
      clientName: clientName || "",
      description: description || "",
      po: po || { value: "", isEdited: false },
      quotation: quotation || { value: "", isEdited: false },
      remarks: remarks || { value: "", isEdited: false },
      surveyDate: surveyPhotos && surveyPhotos.length > 0 ? new Date() : null,
      surveyPhotos: surveyPhotos || [],
      jcReferences: jcReferences || [],
      dcReferences: dcReferences || [],
      users: users || [],
      dueDate: dueDate || null,
      status: autoStatus,
      createdBy: req.userId,
    });

    const hasJcReferences = jcReferences && jcReferences.length > 0;
    const hasDcReferences = dcReferences && dcReferences.length > 0;

    let createdInvoice = null;
    if (hasJcReferences || hasDcReferences) {
      try {
        createdInvoice = await createInvoiceForProject(
          (newProject._id as mongoose.Types.ObjectId).toString(),
          req.userId!
        );
      } catch (invoiceError) {
        console.error("Failed to create invoice:", invoiceError);
      }
    }

    // Send email notification to directors and admins
    try {
      const creator = await User.findById(req.userId);
      const formattedDueDate = dueDate
        ? new Date(dueDate).toLocaleDateString()
        : "Not set";

      await sendNotificationToAdmins(
        "New Project Created - TechnoTrends",
        `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #A82F39;">New Project Created</h2>
            <p>A new project has been created in the TechnoTrends system.</p>
            <div style="background-color: #f0f9ff; padding: 20px; margin: 20px 0; border-radius: 8px;">
              <h3 style="color: #A82F39; margin: 0 0 15px 0;">Project Details:</h3>
              <p><strong>Client Name:</strong> ${
                clientName || "Not specified"
              }</p>
              <p><strong>Description:</strong> ${
                description || "No description provided"
              }</p>
              <p><strong>Status:</strong> ${autoStatus}</p>
              <p><strong>Due Date:</strong> ${formattedDueDate}</p>
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
              surveyPhotos && surveyPhotos.length > 0
                ? `<p><strong>Survey Photos:</strong> ${surveyPhotos.length} photo(s) uploaded</p>`
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
            <p>Please review the project in the admin dashboard.</p>
            <hr style="margin: 30px 0;">
            <p style="color: #666; font-size: 12px;">
              This is an automated notification from TechnoTrends.
            </p>
          </div>
        `,
        "📋 New Project Created",
        `${creator?.name || "Someone"} created a new project for ${
          clientName || "a client"
        }.`,
        {
          type: "project_created",
          projectId: (newProject._id as mongoose.Types.ObjectId).toString(),
          clientName: clientName || "Unknown",
        }
      );
    } catch (emailError) {
      console.error(
        "Failed to send project creation notification:",
        emailError
      );
    }

    res.status(201).json({
      message: "Project created successfully",
      project: newProject,
      ...(createdInvoice && { invoice: createdInvoice }),
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getProjects = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const projects = await Project.find()
      .where("status")
      .ne("Cancelled")
      .populate("createdBy", "name email")
      .populate("users", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(projects);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getProject = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;

    const project = await Project.findById(id)
      .populate("createdBy", "name email role")
      .populate("users", "name email role");

    if (!project) {
      res.status(404).json({ message: "Project not found" });
      return;
    }

    res.status(200).json(project);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const updateProject = async (
  req: Request<{ id: string }, {}, ProjectRequest>,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const { jcReferences, dcReferences, users, ...updateData } = req.body;

    const currentProject = await Project.findById(id);
    if (!currentProject) {
      res.status(404).json({ message: "Project not found" });
      return;
    }

    const finalJcReferences =
      jcReferences !== undefined ? jcReferences : currentProject.jcReferences;
    const finalDcReferences =
      dcReferences !== undefined ? dcReferences : currentProject.dcReferences;
    const finalUsers =
      users !== undefined
        ? users
        : currentProject.users.map((u) => u.toString());
    const autoStatus = determineProjectStatus(
      finalJcReferences,
      finalDcReferences,
      finalUsers
    );

    const updatedProject = await Project.findByIdAndUpdate(
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

    if (!updatedProject) {
      res.status(404).json({ message: "Project not found" });
      return;
    }

    const hasNewJcReferences = jcReferences && jcReferences.length > 0;
    const hasNewDcReferences = dcReferences && dcReferences.length > 0;
    const hadPreviousJcReferences =
      currentProject.jcReferences && currentProject.jcReferences.length > 0;
    const hadPreviousDcReferences =
      currentProject.dcReferences && currentProject.dcReferences.length > 0;

    let createdInvoice = null;

    if (
      (hasNewJcReferences || hasNewDcReferences) &&
      !(hadPreviousJcReferences || hadPreviousDcReferences)
    ) {
      try {
        const existingInvoice = await Invoice.findOne({ project: id });

        if (!existingInvoice) {
          createdInvoice = await createInvoiceForProject(id, req.userId!);
        }
      } catch (invoiceError) {
        console.error("Failed to create invoice:", invoiceError);
      }
    }

    res.status(200).json({
      message: "Project updated successfully",
      project: updatedProject,
      ...(createdInvoice && { invoice: createdInvoice }),
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const deleteProject = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const project = await Project.findById(id);
    if (!project) {
      res.status(404).json({ message: "Project not found" });
      return;
    }
    project.status = "Cancelled";
    await project.save();

    res.status(200).json({ message: "Project deleted successfully" });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const assignUsersToProject = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const { userIds } = req.body;
    const currentProject = await Project.findById(id);
    if (!currentProject) {
      res.status(404).json({ message: "Project not found" });
      return;
    }

    const updatedProject = await Project.findByIdAndUpdate(
      id,
      { $addToSet: { users: { $each: userIds } } },
      { new: true }
    ).populate("users", "name email");

    if (!updatedProject) {
      res.status(404).json({ message: "Project not found" });
      return;
    }

    const userIdStrings = updatedProject.users.map((u) => u._id.toString());
    const autoStatus = determineProjectStatus(
      currentProject.jcReferences,
      currentProject.dcReferences,
      userIdStrings
    );

    if (updatedProject.status !== autoStatus) {
      await Project.findByIdAndUpdate(id, { status: autoStatus });
      updatedProject.status = autoStatus;
    }

    // Send notifications to newly assigned users
    try {
      const currentUserIds = currentProject.users.map((u) => u.toString());
      const newlyAssignedUserIds = userIds.filter(
        (userId: string) => !currentUserIds.includes(userId)
      );

      if (newlyAssignedUserIds.length > 0) {
        const projectWithDetails = await Project.findById(id).populate(
          "createdBy",
          "name"
        );

        await sendNotificationToUsers(
          newlyAssignedUserIds,
          "📋 New Project Assignment",
          `You've been assigned to project: ${
            projectWithDetails?.clientName || "Unknown Client"
          }`,
          {
            type: "project_assigned",
            projectId: id,
            clientName: projectWithDetails?.clientName || "Unknown Client",
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
      message: "Users assigned to project successfully",
      project: updatedProject,
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getProjectsByUser = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const projects = await Project.find({
      users: { $in: [req.userId] },
    })
      .where("status")
      .ne("Cancelled")
      .populate("createdBy", "name email")
      .populate("users", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(projects);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getProjectsByStatus = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { status } = req.params;

    const projects = await Project.find({ status })
      .where("status")
      .ne("Cancelled")
      .populate("createdBy", "name email")
      .populate("users", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(projects);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};
