import { Request, Response, NextFunction } from "express";
import { User } from "../models";

const verifyDirector = async (
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

    // Check if user has director role
    if (user.role !== "director") {
      res
        .status(403)
        .json({ message: "Access denied - Director privileges required" });
      return;
    }

    // User is verified director, proceed
    next();
  } catch (error) {
    console.error("Director verification error:", error);
    res
      .status(500)
      .json({ message: "Internal server error during role verification" });
    return;
  }
};

export default verifyDirector;
