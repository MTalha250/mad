import { Request, Response } from "express";
import { Maintenance, User } from "../models";
import { sendNotificationToAdmins, sendNotificationToUsers } from "./User";

interface MaintenanceRequest {
  clientName?: string;
  remarks?: {
    value: string;
    isEdited: boolean;
  };
  serviceDates?: Array<{
    serviceDate: Date;
    actualDate?: Date | null;
    jcReference?: string;
    invoiceRef?: string;
    paymentStatus?: "Pending" | "Paid" | "Overdue" | "Cancelled";
    isCompleted?: boolean;
    month?: number;
    year?: number;
  }>;
  users?: string[];
  status?: "Pending" | "In Progress" | "Completed" | "Cancelled";
}

const determineMaintenanceStatus = (
  serviceDates?: Array<{ isCompleted: boolean }>,
  users?: string[]
): "Pending" | "In Progress" | "Completed" | "Cancelled" => {
  // If users are assigned, status is "In Progress"
  if (users && users.length > 0) {
    return "In Progress";
  }

  // If all service dates are completed, status is "Completed"
  if (serviceDates && serviceDates.length > 0) {
    const allCompleted = serviceDates.every((sd) => sd.isCompleted);
    if (allCompleted) {
      return "Completed";
    }
  }

  return "Pending";
};

const generateNextMonthServiceDates = (
  completedServiceDate: Date,
  templateDates: Date[]
): Array<{
  serviceDate: Date;
  actualDate: Date | null;
  jcReference: string;
  invoiceRef: string;
  paymentStatus: "Pending" | "Paid" | "Overdue" | "Cancelled";
  isCompleted: boolean;
  month: number;
  year: number;
}> => {
  const nextMonth = new Date(completedServiceDate);
  nextMonth.setMonth(nextMonth.getMonth() + 1);

  const nextMonthNumber = nextMonth.getMonth() + 1; // 1-12
  const nextYear = nextMonth.getFullYear();

  return templateDates.map((templateDate) => {
    const serviceDate = new Date(
      nextYear,
      nextMonthNumber - 1,
      templateDate.getDate()
    );

    return {
      serviceDate,
      actualDate: null,
      jcReference: "",
      invoiceRef: "",
      paymentStatus: "Pending" as const,
      isCompleted: false,
      month: nextMonthNumber,
      year: nextYear,
    };
  });
};

export const createMaintenance = async (
  req: Request<{}, {}, MaintenanceRequest>,
  res: Response
): Promise<void> => {
  try {
    const {
      clientName,
      remarks,
      serviceDates = [],
      users = [],
      status,
    } = req.body;

    if (!clientName) {
      res.status(400).json({ message: "Client name is required" });
      return;
    }

    // Process service dates to include month and year
    const processedServiceDates = serviceDates.map((sd) => {
      const serviceDate = new Date(sd.serviceDate);
      return {
        serviceDate,
        actualDate: sd.actualDate || null,
        jcReference: sd.jcReference || "",
        invoiceRef: sd.invoiceRef || "",
        paymentStatus: sd.paymentStatus || "Pending",
        isCompleted: sd.isCompleted || false,
        month: serviceDate.getMonth() + 1, // 1-12
        year: serviceDate.getFullYear(),
      };
    });

    const maintenanceStatus =
      status || determineMaintenanceStatus(processedServiceDates, users);

    const maintenance = new Maintenance({
      clientName,
      remarks: remarks || { value: "", isEdited: false },
      serviceDates: processedServiceDates,
      users,
      status: maintenanceStatus,
      createdBy: req.userId,
    });

    await maintenance.save();

    // Populate the created maintenance
    const populatedMaintenance = await Maintenance.findById(maintenance._id)
      .populate("users", "name email role")
      .populate("createdBy", "name email role");

    // Send notification to admins and directors
    await sendNotificationToAdmins(
      "New Maintenance Created",
      `<h2>New Maintenance Created</h2>
       <p><strong>Client:</strong> ${clientName}</p>
       <p><strong>Service Dates:</strong> ${processedServiceDates.length}</p>
       <p><strong>Created by:</strong> ${
         (populatedMaintenance?.createdBy as any)?.name
       }</p>`,
      "New Maintenance Created",
      `New maintenance for ${clientName} has been created`,
      {
        type: "maintenance_created",
        maintenanceId: (maintenance._id as any).toString(),
      }
    );

    res.status(201).json({
      message: "Maintenance created successfully",
      maintenance: populatedMaintenance,
    });
  } catch (error: any) {
    console.error("Error creating maintenance:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getMaintenances = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const maintenances = await Maintenance.find({})
      .populate("users", "name email role")
      .populate("createdBy", "name email role")
      .sort({ createdAt: -1 });

    res.status(200).json(maintenances);
  } catch (error: any) {
    console.error("Error fetching maintenances:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getMaintenance = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const maintenance = await Maintenance.findById(req.params.id)
      .populate("users", "name email role")
      .populate("createdBy", "name email role");

    if (!maintenance) {
      res.status(404).json({ message: "Maintenance not found" });
      return;
    }

    res.status(200).json(maintenance);
  } catch (error: any) {
    console.error("Error fetching maintenance:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const updateMaintenance = async (
  req: Request<{ id: string }, {}, MaintenanceRequest>,
  res: Response
): Promise<void> => {
  try {
    const maintenance = await Maintenance.findById(req.params.id);

    if (!maintenance) {
      res.status(404).json({ message: "Maintenance not found" });
      return;
    }

    const { clientName, remarks, serviceDates, users, status } = req.body;

    // Store original service dates for next month generation
    const originalServiceDates = [...maintenance.serviceDates];

    // Update fields
    if (clientName !== undefined) maintenance.clientName = clientName;
    if (remarks !== undefined) {
      maintenance.remarks = {
        value: remarks.value,
        isEdited: remarks.isEdited,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any;
    }
    if (users !== undefined) maintenance.users = users as any;

    // Handle service dates updates and check for completion
    if (serviceDates !== undefined) {
      const processedServiceDates = serviceDates.map((sd) => {
        const serviceDate = new Date(sd.serviceDate!);
        return {
          serviceDate,
          actualDate: sd.actualDate || null,
          jcReference: sd.jcReference || "",
          invoiceRef: sd.invoiceRef || "",
          paymentStatus: sd.paymentStatus || "Pending",
          isCompleted: sd.isCompleted || false,
          month: serviceDate.getMonth() + 1,
          year: serviceDate.getFullYear(),
        };
      });

      maintenance.serviceDates = processedServiceDates as any;

      // Check if any service date was just completed
      const newlyCompleted = processedServiceDates.filter((newSd, index) => {
        const originalSd = originalServiceDates[index];
        return newSd.isCompleted && originalSd && !originalSd.isCompleted;
      });

      // Generate next month's service dates for newly completed ones
      if (newlyCompleted.length > 0) {
        const templateDates = originalServiceDates.map((sd) => sd.serviceDate);
        const nextMonthDates = generateNextMonthServiceDates(
          newlyCompleted[0].serviceDate,
          templateDates
        );

        // Add next month's service dates
        maintenance.serviceDates.push(...(nextMonthDates as any));
      }
    }

    // Update status
    if (status !== undefined) {
      maintenance.status = status;
    } else {
      maintenance.status = determineMaintenanceStatus(
        maintenance.serviceDates,
        maintenance.users.map((u) => u.toString())
      );
    }

    await maintenance.save();

    const updatedMaintenance = await Maintenance.findById(maintenance._id)
      .populate("users", "name email role")
      .populate("createdBy", "name email role");

    res.status(200).json({
      message: "Maintenance updated successfully",
      maintenance: updatedMaintenance,
    });
  } catch (error: any) {
    console.error("Error updating maintenance:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const deleteMaintenance = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const maintenance = await Maintenance.findByIdAndDelete(req.params.id);

    if (!maintenance) {
      res.status(404).json({ message: "Maintenance not found" });
      return;
    }

    res.status(200).json({ message: "Maintenance deleted successfully" });
  } catch (error: any) {
    console.error("Error deleting maintenance:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const assignUsersToMaintenance = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { userIds } = req.body;
    const maintenance = await Maintenance.findById(req.params.id);

    if (!maintenance) {
      res.status(404).json({ message: "Maintenance not found" });
      return;
    }

    if (!userIds || !Array.isArray(userIds)) {
      res.status(400).json({ message: "User IDs are required" });
      return;
    }

    // Validate that all userIds exist
    const users = await User.find({ _id: { $in: userIds } });
    if (users.length !== userIds.length) {
      res.status(400).json({ message: "One or more user IDs are invalid" });
      return;
    }

    maintenance.users = userIds;
    maintenance.status = determineMaintenanceStatus(
      maintenance.serviceDates,
      userIds
    );
    await maintenance.save();

    const updatedMaintenance = await Maintenance.findById(maintenance._id)
      .populate("users", "name email role")
      .populate("createdBy", "name email role");

    // Send notifications to assigned users
    await sendNotificationToUsers(
      userIds,
      "New Maintenance Assignment",
      `You have been assigned to maintenance for ${maintenance.clientName}`,
      {
        type: "maintenance_assigned",
        maintenanceId: (maintenance._id as any).toString(),
      },
      "New Maintenance Assignment",
      `<h2>New Maintenance Assignment</h2>
       <p>You have been assigned to maintenance for <strong>${maintenance.clientName}</strong></p>
       <p>Please check your app for more details.</p>`
    );

    res.status(200).json({
      message: "Users assigned successfully",
      maintenance: updatedMaintenance,
    });
  } catch (error: any) {
    console.error("Error assigning users:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getMaintenancesByUser = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const maintenances = await Maintenance.find({ users: req.userId })
      .populate("users", "name email role")
      .populate("createdBy", "name email role")
      .sort({ createdAt: -1 });

    res.status(200).json(maintenances);
  } catch (error: any) {
    console.error("Error fetching user maintenances:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getMaintenancesByStatus = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { status } = req.params;
    const maintenances = await Maintenance.find({ status })
      .populate("users", "name email role")
      .populate("createdBy", "name email role")
      .sort({ createdAt: -1 });

    res.status(200).json(maintenances);
  } catch (error: any) {
    console.error("Error fetching maintenances by status:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getUpcomingMaintenances = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const maintenances = await Maintenance.find({
      serviceDates: {
        $elemMatch: {
          serviceDate: { $gte: today, $lte: tomorrow },
          isCompleted: false,
        },
      },
    })
      .populate("users", "name email role")
      .populate("createdBy", "name email role")
      .sort({ "serviceDates.serviceDate": 1 });

    res.status(200).json(maintenances);
  } catch (error: any) {
    console.error("Error fetching upcoming maintenances:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};
