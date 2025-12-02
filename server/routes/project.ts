import express from "express";
import {
  createProject,
  getProjects,
  getProject,
  updateProject,
  deleteProject,
  assignUsersToProject,
  getProjectsByStatus,
  getProjectsByUser,
} from "../controllers/Project";
import { verifyToken, verifyAdmin, verifyHead } from "../middlewares";

const router = express.Router();

// All routes require authentication
router.use(verifyToken);

// GET routes
router.get("/", getProjects); // Get all projects
router.get("/user", getProjectsByUser); // Get projects by user
router.get("/status/:status", getProjectsByStatus); // Get projects by status
router.get("/:id", getProject); // Get single project

// POST routes
router.post("/", verifyHead, createProject); // Create project (head+ only)
router.post("/:id/assign-users", verifyHead, assignUsersToProject); // Assign users (head+ only)

// PUT routes
router.put("/:id", updateProject); // Update project

// DELETE routes
router.delete("/:id", verifyAdmin, deleteProject); // Delete project (admin+ only)

export default router;
