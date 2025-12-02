import express from "express";
import {
  register,
  login,
  getUser,
  updateUser,
  getPendingUsers,
  changeUserStatus,
  getUsers,
  resetPassword,
  getApprovedUsers,
  deleteUser,
  forgotPassword,
  verifyResetCode,
  updatePushToken,
} from "../controllers/User";
import { verifyAdmin, verifyHead, verifyToken } from "../middlewares";

const router = express.Router();
router.post("/register", register);
router.post("/login", login);
router.post("/forgot-password", forgotPassword);
router.post("/verify-reset-code", verifyResetCode);
router.post("/update-push-token", verifyToken, updatePushToken);
router.get("/profile", verifyToken, getUser);
router.get("/", verifyToken, getUsers);
router.put("/profile", verifyToken, updateUser);
router.get("/pending", verifyToken, verifyAdmin, getPendingUsers);
router.put("/pending/:id", verifyToken, verifyAdmin, changeUserStatus);
router.put("/reset-password", verifyToken, resetPassword);
router.get("/approved", verifyToken, verifyAdmin, getApprovedUsers);
router.delete("/:id", verifyToken, verifyAdmin, deleteUser);

export default router;
