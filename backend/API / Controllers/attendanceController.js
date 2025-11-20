const Attendance = require('../models/Attendance');
const Student = require('../models/Student');
const Class = require('../models/Class');

// @desc    Mark attendance from watch
exports.markAttendance = async (req, res) => {
  try {
    const { studentId, classId, nfcTagId, location, deviceMac } = req.body;

    // Verify NFC tag matches class
    const classInfo = await Class.findById(classId);
    if (!classInfo || classInfo.nfcTagId !== nfcTagId) {
      return res.status(400).json({ error: 'Invalid NFC tag for this class' });
    }

    // Check if already marked today
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const existing = await Attendance.findOne({
      studentId,
      classId,
      checkInTime: { $gte: today }
    });

    if (existing) {
      return res.status(400).json({ 
        error: 'Attendance already marked for this class today',
        attendance: existing 
      });
    }

    // Create attendance record
    const attendance = await Attendance.create({
      studentId,
      classId,
      checkInTime: new Date(),
      status: 'present',
      location,
      deviceMac
    });

    res.status(201).json({
      success: true,
      message: 'Attendance marked successfully',
      attendance
    });
  } catch (error) {
    console.error('Mark attendance error:', error);
    res.status(500).json({ error: 'Failed to mark attendance' });
  }
};

// @desc    Get class attendance
exports.getClassAttendance = async (req, res) => {
  try {
    const { classId } = req.params;
    const { date } = req.query;

    const query = { classId };
    
    if (date) {
      const targetDate = new Date(date);
      targetDate.setHours(0, 0, 0, 0);
      const nextDay = new Date(targetDate);
      nextDay.setDate(nextDay.getDate() + 1);
      
      query.checkInTime = { $gte: targetDate, $lt: nextDay };
    }

    const attendance = await Attendance.find(query)
      .populate('studentId', 'firstName lastName studentId')
      .sort({ checkInTime: -1 });

    const classInfo = await Class.findById(classId);
    const totalStudents = await Student.countDocuments({ classId });
    const presentCount = attendance.filter(a => a.status === 'present').length;

    res.json({
      success: true,
      attendance,
      summary: {
        totalStudents,
        presentCount,
        absentCount: totalStudents - presentCount,
        attendanceRate: ((presentCount / totalStudents) * 100).toFixed(2) + '%'
      },
      classInfo
    });
  } catch (error) {
    console.error('Get class attendance error:', error);
    res.status(500).json({ error: 'Failed to fetch attendance' });
  }
};

// @desc    Get student attendance history
exports.getStudentAttendance = async (req, res) => {
  try {
    const { studentId } = req.params;
    const { startDate, endDate, limit = 30 } = req.query;

    const query = { studentId };
    
    if (startDate || endDate) {
      query.checkInTime = {};
      if (startDate) query.checkInTime.$gte = new Date(startDate);
      if (endDate) query.checkInTime.$lte = new Date(endDate);
    }

    const attendance = await Attendance.find(query)
      .populate('classId', 'className section')
      .sort({ checkInTime: -1 })
      .limit(parseInt(limit));

    const totalClasses = attendance.length;
    const presentCount = attendance.filter(a => a.status === 'present').length;
    const lateCount = attendance.filter(a => a.status === 'late').length;

    res.json({
      success: true,
      attendance,
      summary: {
        totalClasses,
        presentCount,
        lateCount,
        absentCount: totalClasses - presentCount - lateCount,
        attendanceRate: ((presentCount / totalClasses) * 100).toFixed(2) + '%'
      }
    });
  } catch (error) {
    console.error('Get student attendance error:', error);
    res.status(500).json({ error: 'Failed to fetch student attendance' });
  }
};

// @desc    Get today's attendance summary
exports.getTodayAttendance = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const attendance = await Attendance.find({
      checkInTime: { $gte: today, $lt: tomorrow }
    }).populate('studentId classId');

    const totalStudents = await Student.countDocuments();
    const presentToday = new Set(attendance.map(a => a.studentId._id.toString())).size;

    res.json({
      success: true,
      summary: {
        totalStudents,
        presentToday,
        absentToday: totalStudents - presentToday,
        attendanceRate: ((presentToday / totalStudents) * 100).toFixed(2) + '%'
      },
      attendance
    });
  } catch (error) {
    console.error('Get today attendance error:', error);
    res.status(500).json({ error: 'Failed to fetch today\'s attendance' });
  }
};

// @desc    Generate attendance report
exports.generateReport = async (req, res) => {
  try {
    const { classId, startDate, endDate } = req.query;

    const query = {};
    if (classId) query.classId = classId;
    if (startDate || endDate) {
      query.checkInTime = {};
      if (startDate) query.checkInTime.$gte = new Date(startDate);
      if (endDate) query.checkInTime.$lte = new Date(endDate);
    }

    const attendance = await Attendance.find(query)
      .populate('studentId', 'firstName lastName studentId')
      .populate('classId', 'className section');

    // Group by student
    const studentStats = {};
    attendance.forEach(record => {
      const studentId = record.studentId._id.toString();
      if (!studentStats[studentId]) {
        studentStats[studentId] = {
          student: record.studentId,
          totalClasses: 0,
          present: 0,
          absent: 0,
          late: 0
        };
      }
      studentStats[studentId].totalClasses++;
      if (record.status === 'present') studentStats[studentId].present++;
      else if (record.status === 'late') studentStats[studentId].late++;
      else studentStats[studentId].absent++;
    });

    res.json({
      success: true,
      report: Object.values(studentStats),
      period: { startDate, endDate }
    });
  } catch (error) {
    console.error('Generate report error:', error);
    res.status(500).json({ error: 'Failed to generate report' });
  }
};

// @desc    Update attendance record
exports.updateAttendance = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, checkOutTime } = req.body;

    const attendance = await Attendance.findByIdAndUpdate(
      id,
      { status, checkOutTime },
      { new: true }
    );

    if (!attendance) {
      return res.status(404).json({ error: 'Attendance record not found' });
    }

    res.json({
      success: true,
      message: 'Attendance updated successfully',
      attendance
    });
  } catch (error) {
    console.error('Update attendance error:', error);
    res.status(500).json({ error: 'Failed to update attendance' });
  }
};
