import jwt, { JwtPayload } from "jsonwebtoken";
import { Request, Response, NextFunction } from "express";
import dotenv from "dotenv";

dotenv.config();

// Extend the Request interface to include userId
declare global {
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

// Define the expected JWT payload structure
interface CustomJwtPayload extends JwtPayload {
  id: string;
  email: string;
  role: string;
}

const verifyToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    const isCustomAuth = token && token.length < 500;

    if (!token) {
      res.status(401).json({ message: "Unauthorized - No token provided" });
      return;
    }

    // Check if JWT_SECRET is defined
    if (!process.env.JWT_SECRET) {
      res
        .status(500)
        .json({ message: "Internal server error - JWT secret not configured" });
      return;
    }

    let decodedData: CustomJwtPayload | JwtPayload;

    if (token && isCustomAuth) {
      // Verify custom JWT token
      try {
        decodedData = jwt.verify(
          token,
          process.env.JWT_SECRET
        ) as CustomJwtPayload;
        req.userId = decodedData.id;
      } catch (jwtError) {
        res.status(401).json({ message: "Invalid token" });
        return;
      }
    } else {
      // Handle external auth (like Google OAuth)
      decodedData = jwt.decode(token) as JwtPayload;
      if (decodedData && decodedData.sub) {
        req.userId = decodedData.sub;
      } else {
        res.status(401).json({ message: "Invalid token format" });
        return;
      }
    }

    next();
  } catch (error) {
    console.error("Token verification error:", error);
    res
      .status(401)
      .json({ message: "Unauthorized - Token verification failed" });
    return;
  }
};

export default verifyToken;
