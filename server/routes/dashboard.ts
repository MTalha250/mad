import { Router } from "express";
import {
  getDashboardData,
  getUserDashboardData,
} from "../controllers/Dashboard";
import { verifyToken, verifyHead } from "../middlewares";

const router = Router();

router.use(verifyToken);

router.get("/", verifyHead, getDashboardData);
router.get("/user", getUserDashboardData);

export default router;
