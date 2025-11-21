#include <unity.h>
#include "sensors.h"

// Test setup
void setUp(void) {
    initSensors();
}

// Test teardown
void tearDown(void) {
    // Clean up
}

// Test heart rate sensor initialization
void test_heart_rate_init(void) {
    float heartRate;
    bool result = readHeartRate(heartRate);
    
    TEST_ASSERT_TRUE(result);
    TEST_ASSERT_GREATER_THAN(0, heartRate);
    TEST_ASSERT_LESS_THAN(200, heartRate);
}

// Test accelerometer reading
void test_accelerometer_reading(void) {
    float x, y, z;
    bool result = readAccelerometer(x, y, z);
    
    TEST_ASSERT_TRUE(result);
    TEST_ASSERT_GREATER_THAN(-2.0, x);
    TEST_ASSERT_LESS_THAN(2.0, x);
    TEST_ASSERT_GREATER_THAN(-2.0, y);
    TEST_ASSERT_LESS_THAN(2.0, y);
    TEST_ASSERT_GREATER_THAN(8.0, z);  // Gravity
    TEST_ASSERT_LESS_THAN(11.0, z);
}

// Test step counting
void test_step_counting(void) {
    int initialSteps = calculateSteps();
    
    // Simulate movement
    for(int i = 0; i < 10; i++) {
        float x, y, z;
        readAccelerometer(x, y, z);
        delay(100);
    }
    
    int finalSteps = calculateSteps();
    TEST_ASSERT_GREATER_OR_EQUAL(initialSteps, finalSteps);
}

// Test focus score calculation
void test_focus_score_calculation(void) {
    SensorData data;
    data.heartRate = 75.0;
    data.steps = 100;
    data.movementCount = 5;
    data.interactionCount = 2;
    data.timestamp = millis();
    
    FocusData focus = calculateFocusScore(data);
    
    TEST_ASSERT_GREATER_OR_EQUAL(0, focus.focusScore);
    TEST_ASSERT_LESS_OR_EQUAL(100, focus.focusScore);
    TEST_ASSERT_GREATER_OR_EQUAL(0, focus.distractionCount);
}

// Test sensor health check
void test_sensor_health(void) {
    bool healthy = isSensorHealthy();
    TEST_ASSERT_TRUE(healthy);
}

// Test temperature reading
void test_temperature_reading(void) {
    float temp = calculateTemperature();
    
    TEST_ASSERT_GREATER_THAN(20.0, temp);  // Reasonable room temp
    TEST_ASSERT_LESS_THAN(40.0, temp);
}

// Test movement detection
void test_movement_detection(void) {
    int movements = detectMovement();
    TEST_ASSERT_GREATER_OR_EQUAL(0, movements);
}

// Test sensor data collection
void test_collect_all_sensors(void) {
    SensorData data = collectAllSensorData();
    
    TEST_ASSERT_GREATER_OR_EQUAL(0, data.heartRate);
    TEST_ASSERT_GREATER_OR_EQUAL(0, data.steps);
    TEST_ASSERT_GREATER_OR_EQUAL(0, data.movementCount);
    TEST_ASSERT_GREATER_THAN(0, data.timestamp);
}

void setup() {
    delay(2000);  // Wait for board to stabilize
    
    UNITY_BEGIN();
    
    RUN_TEST(test_heart_rate_init);
    RUN_TEST(test_accelerometer_reading);
    RUN_TEST(test_step_counting);
    RUN_TEST(test_focus_score_calculation);
    RUN_TEST(test_sensor_health);
    RUN_TEST(test_temperature_reading);
    RUN_TEST(test_movement_detection);
    RUN_TEST(test_collect_all_sensors);
    
    UNITY_END();
}

void loop() {
    // Empty
}
