import { Request, Response, NextFunction } from "express";
import { User } from "../models";

const verifyAdmin = async (
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
    const user = await User.findById(req.userId).select("role status");

    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    // Check if user is approved
    if (user.status !== "Approved") {
      res.status(403).json({ message: "Access denied - User not approved" });
      return;
    }

    // Check if user has admin or director role (director has higher privileges)
    if (user.role !== "admin" && user.role !== "director") {
      res
        .status(403)
        .json({ message: "Access denied - Admin privileges required" });
      return;
    }

    // User is verified admin or director, proceed
    next();
  } catch (error) {
    console.error("Admin verification error:", error);
    res
      .status(500)
      .json({ message: "Internal server error during role verification" });
    return;
  }
};

export default verifyAdmin;
