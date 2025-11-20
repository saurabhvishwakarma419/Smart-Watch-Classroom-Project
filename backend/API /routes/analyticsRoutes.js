const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const { auth, authorize } = require('../middleware/auth');

// @route   POST /api/analytics/process
// @desc    Process sensor data from watch
// @access  Private
router.post('/process', auth, analyticsController.processSensorData);

// @route   GET /api/analytics/focus/:studentId
// @desc    Get student focus analytics
// @access  Private
router.get('/focus/:studentId', auth, analyticsController.getStudentFocusData);

// @route   GET /api/analytics/class/:classId
// @desc    Get class engagement metrics
// @access  Private (Teacher, Admin)
router.get('/class/:classId', auth, authorize('teacher', 'admin'), analyticsController.getClassAnalytics);

// @route   GET /api/analytics/trends/:studentId
// @desc    Get student performance trends
// @access  Private
router.get('/trends/:studentId', auth, analyticsController.getStudentTrends);

// @route   GET /api/analytics/dashboard
// @desc    Get teacher dashboard analytics
// @access  Private (Teacher, Admin)
router.get('/dashboard', auth, authorize('teacher', 'admin'), analyticsController.getDashboardAnalytics);

module.exports = router;
