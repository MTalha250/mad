import { Invoice, User, Project } from "../models";
import { Request, Response } from "express";
import { sendNotificationToAdmins } from "./User";

interface InvoiceRequest {
  invoiceReference?: string;
  invoiceDate?: Date;
  amount?: string;
  paymentTerms?: "Cash" | "Credit";
  creditDays?: string;
  dueDate?: Date;
  project?: string;
  status?: "Pending" | "In Progress" | "Completed" | "Cancelled";
}

export const createInvoice = async (
  req: Request<{}, {}, InvoiceRequest>,
  res: Response
): Promise<void> => {
  try {
    const {
      invoiceReference,
      amount,
      paymentTerms,
      creditDays,
      dueDate,
      project,
      status,
    } = req.body;

    const newInvoice = await Invoice.create({
      invoiceReference: invoiceReference || "",
      invoiceDate: invoiceReference ? new Date() : null,
      amount: amount || "0",
      paymentTerms: paymentTerms || "Cash",
      creditDays: creditDays || "",
      dueDate: dueDate || null,
      project: project || "",
      status: status || "Pending",
      createdBy: req.userId,
    });

    // Send email notification to directors and admins
    try {
      const creator = await User.findById(req.userId);
      const projectDetails = project
        ? await Project.findById(project).populate("createdBy", "name")
        : null;
      const formattedDueDate = dueDate
        ? new Date(dueDate).toLocaleDateString()
        : "Not set";
      const formattedInvoiceDate = invoiceReference
        ? new Date().toLocaleDateString()
        : "Not set";

      await sendNotificationToAdmins(
        "New Invoice Created - TechnoTrends",
        `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #A82F39;">New Invoice Created</h2>
            <p>A new invoice has been generated in the TechnoTrends system.</p>
            <div style="background-color: #f0f9ff; padding: 20px; margin: 20px 0; border-radius: 8px;">
              <h3 style="color: #A82F39; margin: 0 0 15px 0;">Invoice Details:</h3>
              ${
                invoiceReference
                  ? `<p><strong>Invoice Reference:</strong> ${invoiceReference}</p>`
                  : "<p><strong>Invoice Reference:</strong> Not specified</p>"
              }
              <p><strong>Amount:</strong> $${amount || "0"}</p>
              <p><strong>Payment Terms:</strong> ${paymentTerms || "Cash"}</p>
              ${
                paymentTerms === "Credit" && creditDays
                  ? `<p><strong>Credit Days:</strong> ${creditDays} days</p>`
                  : ""
              }
              <p><strong>Status:</strong> ${status || "Pending"}</p>
              <p><strong>Invoice Date:</strong> ${formattedInvoiceDate}</p>
              <p><strong>Due Date:</strong> ${formattedDueDate}</p>
              <p><strong>Created By:</strong> ${creator?.name || "Unknown"} (${
          creator?.email || "No email"
        })</p>
              <p><strong>Created At:</strong> ${new Date().toLocaleString()}</p>
            </div>
            ${
              projectDetails
                ? `
              <div style="background-color: #f9fafb; padding: 15px; margin: 15px 0; border-radius: 8px;">
                <h4 style="color: #374151; margin: 0 0 10px 0;">Related Project:</h4>
                <p><strong>Client:</strong> ${
                  projectDetails.clientName || "Not specified"
                }</p>
                <p><strong>Description:</strong> ${
                  projectDetails.description || "No description"
                }</p>
                <p><strong>Project Status:</strong> ${projectDetails.status}</p>
              </div>
            `
                : "<p><em>No project associated with this invoice.</em></p>"
            }
            <p>Please review the invoice in the admin dashboard.</p>
            <hr style="margin: 30px 0;">
            <p style="color: #666; font-size: 12px;">
              This is an automated notification from TechnoTrends.
            </p>
          </div>
        `,
        "💰 New Invoice Created",
        `${creator?.name || "Someone"} created an invoice for $${
          amount || "0"
        }${projectDetails ? ` (${projectDetails.clientName})` : ""}.`,
        {
          type: "invoice_created",
          invoiceId: (newInvoice._id as any).toString(),
          amount: amount || "0",
          clientName: projectDetails?.clientName || "Unknown",
        }
      );
    } catch (emailError) {
      console.error(
        "Failed to send invoice creation notification:",
        emailError
      );
    }

    res.status(201).json({
      message: "Invoice created successfully",
      invoice: newInvoice,
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getInvoices = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const invoices = await Invoice.find()
      .where("status")
      .ne("Cancelled")
      .populate("project createdBy")
      .sort({ createdAt: -1 });

    res.status(200).json(invoices);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getInvoice = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;

    const invoice = await Invoice.findById(id)
      .populate(
        "project",
        "clientName description status po quotation jcReferences dcReferences"
      )
      .populate("createdBy", "name email role");

    if (!invoice) {
      res.status(404).json({ message: "Invoice not found" });
      return;
    }

    res.status(200).json(invoice);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const updateInvoice = async (
  req: Request<{ id: string }, {}, InvoiceRequest>,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const updatedInvoice = await Invoice.findByIdAndUpdate(
      id,
      {
        ...updateData,
        invoiceDate: updateData.invoiceReference ? new Date() : null,
      },
      {
        new: true,
        runValidators: true,
      }
    )
      .populate("project", "clientName description status")
      .populate("createdBy", "name email");

    if (!updatedInvoice) {
      res.status(404).json({ message: "Invoice not found" });
      return;
    }

    res.status(200).json({
      message: "Invoice updated successfully",
      invoice: updatedInvoice,
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const deleteInvoice = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;

    const invoice = await Invoice.findById(id);

    if (!invoice) {
      res.status(404).json({ message: "Invoice not found" });
      return;
    }

    invoice.status = "Cancelled";
    await invoice.save();

    res.status(200).json({ message: "Invoice deleted successfully" });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getInvoicesByStatus = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { status } = req.params;

    const invoices = await Invoice.find({ status })
      .where("status")
      .ne("Cancelled")
      .populate("project", "clientName description status")
      .populate("createdBy", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(invoices);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getInvoicesByPaymentTerms = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { paymentTerms } = req.params;

    const invoices = await Invoice.find({ paymentTerms })
      .where("status")
      .ne("Cancelled")
      .populate("project", "clientName description status")
      .populate("createdBy", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(invoices);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getInvoicesByProject = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { projectId } = req.params;

    const invoices = await Invoice.find({ project: projectId })
      .where("status")
      .ne("Cancelled")
      .populate("project", "clientName description status")
      .populate("createdBy", "name email")
      .sort({ createdAt: -1 });

    res.status(200).json(invoices);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getOverdueInvoices = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const currentDate = new Date();

    const overdueInvoices = await Invoice.find({
      dueDate: { $lt: currentDate },
      status: { $ne: "Completed" },
    })
      .where("status")
      .ne("Cancelled")
      .populate("project", "clientName description status")
      .populate("createdBy", "name email")
      .sort({ dueDate: 1 });

    res.status(200).json(overdueInvoices);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};
