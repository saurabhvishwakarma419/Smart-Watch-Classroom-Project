const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const { auth, authorize } = require('../middleware/auth');

// @route   POST /api/attendance/mark
// @desc    Mark attendance (from watch)
// @access  Private
router.post('/mark', auth, attendanceController.markAttendance);

// @route   GET /api/attendance/class/:classId
// @desc    Get attendance for a class
// @access  Private (Teacher, Admin)
router.get('/class/:classId', auth, authorize('teacher', 'admin'), attendanceController.getClassAttendance);

// @route   GET /api/attendance/student/:studentId
// @desc    Get student attendance history
// @access  Private
router.get('/student/:studentId', auth, attendanceController.getStudentAttendance);

// @route   GET /api/attendance/today
// @desc    Get today's attendance summary
// @access  Private (Teacher, Admin)
router.get('/today', auth, authorize('teacher', 'admin'), attendanceController.getTodayAttendance);

// @route   GET /api/attendance/report
// @desc    Generate attendance report
// @access  Private (Teacher, Admin)
router.get('/report', auth, authorize('teacher', 'admin'), attendanceController.generateReport);

// @route   PUT /api/attendance/:id
// @desc    Update attendance record
// @access  Private (Teacher, Admin)
router.put('/:id', auth, authorize('teacher', 'admin'), attendanceController.updateAttendance);

module.exports = router;
