import { Request, Response, NextFunction } from "express";
import { User } from "../models";

const verifyHead = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Check if userId exists (should be set by verifyToken middleware)
    if (!req.userId) {
      res.status(401).json({ message: "Unauthorized - User ID not found" });
      return;
    }

    // Find the user in database
    const user = await User.findById(req.userId).select(
      "role status department"
    );

    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    // Check if user is approved
    if (user.status !== "Approved") {
      res.status(403).json({ message: "Access denied - User not approved" });
      return;
    }

    // Check if user has head, admin, or director role
    const allowedRoles = ["head", "admin", "director"];
    if (!allowedRoles.includes(user.role)) {
      res
        .status(403)
        .json({ message: "Access denied - Head privileges required" });
      return;
    }

    // Add user data to request for further use in controllers
    (req as any).user = {
      id: user._id,
      role: user.role,
      department: user.department,
    };

    // User is verified head or higher, proceed
    next();
  } catch (error) {
    console.error("Head verification error:", error);
    res
      .status(500)
      .json({ message: "Internal server error during role verification" });
    return;
  }
};

export default verifyHead;
