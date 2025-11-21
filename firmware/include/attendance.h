#ifndef ATTENDANCE_H
#define ATTENDANCE_H

#include <Arduino.h>

// Attendance structure
struct AttendanceData {
    String studentId;
    String classId;
    String nfcTagId;
    String location;
    unsigned long timestamp;
    String deviceMac;
};

// Function declarations
void initAttendance();
bool readNFCTag(String &tagId);
bool markAttendance(const String &nfcTagId);
bool sendAttendanceToServer(const AttendanceData &data);
String getCurrentLocation();
bool isAttendanceMarkedToday();
void displayAttendanceStatus(bool success);

#endif
