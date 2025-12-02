import { User } from "../models";
import bcrypt from "bcryptjs";
import nodemailer from "nodemailer";
import jwt from "jsonwebtoken";
import { Request, Response } from "express";

// Helper function to send push notifications
export const sendPushNotifications = async (
  tokens: string[],
  title: string,
  body: string,
  data?: any
): Promise<void> => {
  try {
    if (tokens.length === 0) return;

    const messages = tokens.map((token) => ({
      to: token,
      sound: "default",
      title,
      body,
      data: data || {},
    }));

    // Split into chunks of 100 (Expo's limit)
    const chunks = [];
    for (let i = 0; i < messages.length; i += 100) {
      chunks.push(messages.slice(i, i + 100));
    }

    // Send each chunk
    for (const chunk of chunks) {
      await fetch("https://exp.host/--/api/v2/push/send", {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Accept-encoding": "gzip, deflate",
          "Content-Type": "application/json",
        },
        body: JSON.stringify(chunk),
      });
    }
  } catch (error) {
    console.error("Failed to send push notifications:", error);
  }
};

// Helper function to send notifications to directors and admins
export const sendNotificationToAdmins = async (
  subject: string,
  htmlContent: string,
  pushTitle?: string,
  pushBody?: string,
  pushData?: any
): Promise<void> => {
  try {
    // Get all directors and admins
    const adminUsers = await User.find({
      role: { $in: ["director", "admin"] },
      status: "Approved",
    });

    if (adminUsers.length === 0) return;

    // Send push notifications if push details provided
    if (pushTitle && pushBody) {
      const pushTokens = adminUsers
        .filter((user) => user.pushToken)
        .map((user) => user.pushToken!);

      if (pushTokens.length > 0) {
        await sendPushNotifications(pushTokens, pushTitle, pushBody, pushData);
      }
    }

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD,
      },
    });

    // Send email to each admin
    const emailPromises = adminUsers.map((admin) => {
      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: admin.email,
        subject,
        html: htmlContent,
      };
      return transporter.sendMail(mailOptions);
    });

    await Promise.all(emailPromises);
  } catch (error) {
    console.error("Failed to send admin notifications:", error);
    // Don't throw error to avoid breaking the main flow
  }
};

// Helper function to send notifications to specific users
export const sendNotificationToUsers = async (
  userIds: string[],
  pushTitle: string,
  pushBody: string,
  pushData?: any,
  emailSubject?: string,
  emailContent?: string
): Promise<void> => {
  try {
    if (userIds.length === 0) return;

    // Get users by IDs
    const users = await User.find({
      _id: { $in: userIds },
      status: "Approved",
    });

    if (users.length === 0) return;

    // Send push notifications
    const pushTokens = users
      .filter((user) => user.pushToken)
      .map((user) => user.pushToken!);

    if (pushTokens.length > 0) {
      await sendPushNotifications(pushTokens, pushTitle, pushBody, pushData);
    }

    // Send emails if email details provided
    if (emailSubject && emailContent) {
      const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASSWORD,
        },
      });

      const emailPromises = users.map((user) => {
        const mailOptions = {
          from: process.env.EMAIL_USER,
          to: user.email,
          subject: emailSubject,
          html: emailContent,
        };
        return transporter.sendMail(mailOptions);
      });

      await Promise.all(emailPromises);
    }
  } catch (error) {
    console.error("Failed to send user notifications:", error);
  }
};

interface RegisterRequest {
  role: string;
  department?: string;
  name: string;
  email: string;
  password: string;
  phone: string;
}

interface LoginRequest {
  role: string;
  email: string;
  password: string;
}

interface UpdateUserRequest {
  name?: string;
  email?: string;
  phone?: string;
  department?: "accounts" | "technical" | "it" | "sales" | "store";
}

interface ForgotPasswordRequest {
  email: string;
}

interface VerifyResetCodeRequest {
  email: string;
  code: string;
  newPassword: string;
}

interface UpdatePushTokenRequest {
  pushToken: string;
}

export const register = async (
  req: Request<{}, {}, RegisterRequest>,
  res: Response
): Promise<void> => {
  const { role, department, name, email, password, phone } = req.body;
  try {
    if (!process.env.JWT_SECRET) {
      res
        .status(500)
        .json({ message: "Internal server error - JWT secret not configured" });
      return;
    }

    const user = await User.findOne({ email });
    if (user) {
      res.status(400).json({ message: "User already exists" });
      return;
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const newUser = await User.create({
      name,
      email,
      password: hashedPassword,
      phone,
      role,
      department,
    });

    const token = jwt.sign({ id: newUser._id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    res.status(201).json({
      message: "Account created successfully. Please wait for approval.",
      user: newUser,
      token,
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const login = async (
  req: Request<{}, {}, LoginRequest>,
  res: Response
): Promise<void> => {
  const { role, email, password } = req.body;
  try {
    if (!process.env.JWT_SECRET) {
      res
        .status(500)
        .json({ message: "Internal server error - JWT secret not configured" });
      return;
    }

    const user = await User.findOne({ email });
    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    if (user.role !== role) {
      res.status(400).json({ message: "Invalid role" });
      return;
    }

    if (user.status !== "Approved") {
      res.status(400).json({ message: "User not approved" });
      return;
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      res.status(400).json({ message: "Invalid credentials" });
      return;
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    res.status(200).json({
      message: "Login successful",
      user,
      token,
      role: user.role,
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const user = await User.findById(req.userId);

    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    res.status(200).json({
      user: user,
      role: user.role,
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const updateUser = async (
  req: Request<{}, {}, UpdateUserRequest>,
  res: Response
): Promise<void> => {
  try {
    const { name, email, phone } = req.body;

    if (email) {
      const existingUser = await User.findOne({
        email: email.toLowerCase().trim(),
        _id: { $ne: req.userId },
      });

      if (existingUser) {
        res.status(400).json({ message: "Email already in use" });
        return;
      }
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.userId,
      {
        name,
        email,
        phone,
      },
      {
        new: true,
      }
    );

    if (!updatedUser) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    res.status(200).json({
      message: "User updated successfully",
      user: updatedUser,
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const deleteUser = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndDelete(id);
    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }
    res.status(200).json({ message: "User deleted successfully" });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getUsers = async (req: Request, res: Response): Promise<void> => {
  try {
    const users = await User.find({
      role: "user",
      status: "Approved",
    }).sort({ createdAt: -1 });
    res.status(200).json(users);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getApprovedUsers = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const users = await User.find({ status: "Approved" }).sort({
      createdAt: -1,
    });
    res.status(200).json(users);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const getPendingUsers = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const users = await User.find({ status: "Pending" });
    res.status(200).json(users);
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const changeUserStatus = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const user = await User.findByIdAndUpdate(id, { status }, { new: true });
    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    // Send email and push notification if user is approved
    if (status === "Approved") {
      try {
        // Send push notification if user has a push token
        if (user.pushToken) {
          await sendPushNotifications(
            [user.pushToken],
            "Account Approved! 🎉",
            `Welcome to TechnoTrends, ${user.name}! Your account has been approved.`,
            { type: "user_approved", userId: user._id }
          );
        }

        const transporter = nodemailer.createTransport({
          service: "gmail",
          auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASSWORD,
          },
        });

        const mailOptions = {
          from: process.env.EMAIL_USER,
          to: user.email,
          subject: "Account Approved - TechnoTrends",
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #A82F39;">Account Approved!</h2>
              <p>Hi ${user.name},</p>
              <p>Great news! Your account has been approved and you can now access the TechnoTrends system.</p>
              <div style="background-color: #f0f9ff; padding: 20px; margin: 20px 0; border-radius: 8px;">
                <h3 style="color: #A82F39; margin: 0 0 10px 0;">Account Details:</h3>
                <p><strong>Name:</strong> ${user.name}</p>
                <p><strong>Email:</strong> ${user.email}</p>
                <p><strong>Role:</strong> ${
                  user.role.charAt(0).toUpperCase() + user.role.slice(1)
                }</p>
                ${
                  user.department
                    ? `<p><strong>Department:</strong> ${
                        user.department.charAt(0).toUpperCase() +
                        user.department.slice(1)
                      }</p>`
                    : ""
                }
              </div>
              <p>You can now sign in to your account and start using the platform.</p>
              <div style="text-align: center; margin: 30px 0;">
                <a href="#" style="background-color: #A82F39; color: white; padding: 12px 30px; text-decoration: none; border-radius: 25px; display: inline-block;">Sign In Now</a>
              </div>
              <p>If you have any questions or need assistance, please don't hesitate to contact us.</p>
              <hr style="margin: 30px 0;">
              <p style="color: #666; font-size: 12px;">
                This is an automated message from TechnoTrends. Please do not reply to this email.
              </p>
            </div>
          `,
        };

        await transporter.sendMail(mailOptions);
      } catch (error) {
        console.error("Failed to send approval notifications:", error);
        // Don't fail the request if notifications fail
      }
    }

    res.status(200).json({ message: "User status changed successfully" });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const resetPassword = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { oldPassword, newPassword } = req.body;
    const user = await User.findById(req.userId);
    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }
    const isPasswordValid = await bcrypt.compare(oldPassword, user.password);
    if (!isPasswordValid) {
      res.status(400).json({ message: "Invalid old password" });
      return;
    }
    const hashedPassword = await bcrypt.hash(newPassword, 12);
    await User.findByIdAndUpdate(req.userId, { password: hashedPassword });
    res.status(200).json({ message: "Password reset successfully" });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const forgotPassword = async (
  req: Request<{}, {}, ForgotPasswordRequest>,
  res: Response
): Promise<void> => {
  try {
    const { email } = req.body;

    if (!email) {
      res.status(400).json({ message: "Email is required" });
      return;
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) {
      res
        .status(404)
        .json({ message: "No account found with this email address" });
      return;
    }

    // Generate 6-digit verification code
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    const resetCodeExpires = new Date(Date.now() + 60000); // 1 minute from now

    // Save reset code to user
    await User.findByIdAndUpdate(user._id, {
      resetCode,
      resetCodeExpires,
    });

    // Configure nodemailer transporter
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD,
      },
    });

    // Email content
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: "Password Reset - TechnoTrends",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #A82F39;">Password Reset Request</h2>
          <p>Hi ${user.name},</p>
          <p>You have requested to reset your password. Please use the following verification code:</p>
          <div style="background-color: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0;">
            <h1 style="color: #A82F39; font-size: 36px; margin: 0; letter-spacing: 5px;">${resetCode}</h1>
          </div>
          <p><strong>Important:</strong> This code will expire in 1 minute for security reasons.</p>
          <p>If you didn't request this password reset, please ignore this email.</p>
          <hr style="margin: 30px 0;">
          <p style="color: #666; font-size: 12px;">
            This is an automated message from TechnoTrends. Please do not reply to this email.
          </p>
        </div>
      `,
    };

    // Send email
    try {
      await transporter.sendMail(mailOptions);

      res.status(200).json({
        message: `Verification code sent to ${email}. Please check your email and enter the 6-digit code within 1 minute.`,
        code: resetCode, // Send code to frontend for development/testing
      });
    } catch (emailError) {
      console.error("Email sending error:", emailError);

      // Clear the reset code since email failed
      await User.findByIdAndUpdate(user._id, {
        $unset: { resetCode: 1, resetCodeExpires: 1 },
      });

      res.status(500).json({
        message: "Failed to send verification code. Please try again later.",
      });
    }
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const verifyResetCode = async (
  req: Request<{}, {}, VerifyResetCodeRequest>,
  res: Response
): Promise<void> => {
  try {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
      res
        .status(400)
        .json({ message: "Email, code, and new password are required" });
      return;
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) {
      res.status(404).json({ message: "User not found" });
      return;
    }

    if (!user.resetCode || !user.resetCodeExpires) {
      res.status(400).json({ message: "No password reset request found" });
      return;
    }

    if (user.resetCode !== code) {
      res.status(400).json({ message: "Invalid verification code" });
      return;
    }

    if (new Date() > user.resetCodeExpires) {
      // Clear expired code
      await User.findByIdAndUpdate(user._id, {
        $unset: { resetCode: 1, resetCodeExpires: 1 },
      });
      res.status(400).json({
        message: "Verification code has expired. Please request a new one.",
      });
      return;
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 12);

    // Update password and clear reset code
    await User.findByIdAndUpdate(user._id, {
      password: hashedPassword,
      $unset: { resetCode: 1, resetCodeExpires: 1 },
    });

    res.status(200).json({
      message:
        "Password reset successfully. You can now login with your new password.",
    });
  } catch (error) {
    console.log(error);
    const errorMessage =
      error instanceof Error ? error.message : "An unknown error occurred";
    res.status(500).json({ message: errorMessage });
  }
};

export const updatePushToken = async (
  req: Request<{}, {}, UpdatePushTokenRequest>,
  res: Response
): Promise<void> => {
  try {
    const { pushToken } = req.body;

    if (!pushToken) {
      res.status(400).json({ message: "Push token is required" });
      return;
    }

    // Update user's push token
    await User.findByIdAndUpdate(req.userId, { pushToken });

    res.status(200).json({ message: "Push token updated successfully" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
};
