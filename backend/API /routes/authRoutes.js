const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { validateLogin, validateRegister } = require('../middleware/validation');

// @route   POST /api/auth/register
// @desc    Register new user
// @access  Public
router.post('/register', validateRegister, authController.register);

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post('/login', validateLogin, authController.login);

// @route   POST /api/auth/refresh
// @desc    Refresh JWT token
// @access  Public
router.post('/refresh', authController.refreshToken);

// @route   POST /api/auth/logout
// @desc    Logout user
// @access  Private
router.post('/logout', authController.logout);

// @route   POST /api/auth/forgot-password
// @desc    Request password reset
// @access  Public
router.post('/forgot-password', authController.forgotPassword);

// @route   POST /api/auth/reset-password
// @desc    Reset password
// @access  Public
router.post('/reset-password', authController.resetPassword);

module.exports = router;
