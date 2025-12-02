import express from "express";
import {
  createMaintenance,
  getMaintenances,
  getMaintenance,
  updateMaintenance,
  deleteMaintenance,
  assignUsersToMaintenance,
  getMaintenancesByUser,
  getMaintenancesByStatus,
  getUpcomingMaintenances,
} from "../controllers/Maintenance";
import {
  verifyToken,
  verifyAdmin,
  verifyDirector,
  verifyHead,
} from "../middlewares";

const router = express.Router();

// Public routes (with token verification)
router.get("/user", verifyToken, getMaintenancesByUser);
router.get("/upcoming", verifyToken, getUpcomingMaintenances);
router.get("/status/:status", verifyToken, getMaintenancesByStatus);

// Admin/Director/Head routes
router.post("/", verifyToken, verifyHead, createMaintenance);
router.get("/", verifyToken, verifyHead, getMaintenances);
router.get("/:id", verifyToken, getMaintenance);
router.put("/:id", verifyToken, updateMaintenance);
router.delete("/:id", verifyToken, verifyAdmin, deleteMaintenance);
router.post(
  "/:id/assign-users",
  verifyToken,
  verifyHead,
  assignUsersToMaintenance
);

export default router;
