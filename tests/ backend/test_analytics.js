const request = require('supertest');
const app = require('../../backend/server');
const { expect } = require('chai');

describe('Analytics API Tests', () => {
    let authToken;
    let studentId;

    before(async () => {
        const res = await request(app)
            .post('/api/auth/login')
            .send({
                email: 'test@student.com',
                password: 'testpass123'
            });
        
        authToken = res.body.token;
        studentId = res.body.user.id;
    });

    describe('POST /api/analytics/process', () => {
        it('should process sensor data and return focus score', async () => {
            const res = await request(app)
                .post('/api/analytics/process')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    studentId: studentId,
                    classId: 'CLASS_001',
                    sensorData: {
                        heartRateAvg: 75,
                        movementCount: 5,
                        interactionCount: 2,
                        durationMinutes: 45,
                        startTime: new Date(),
                        endTime: new Date()
                    }
                });

            expect(res.status).to.equal(200);
            expect(res.body).to.have.property('focusScore');
            expect(res.body.focusScore).to.be.within(0, 100);
        });

        it('should reject invalid sensor data', async () => {
            const res = await request(app)
                .post('/api/analytics/process')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    studentId: studentId,
                    sensorData: {
                        // Missing required fields
                    }
                });

            expect(res.status).to.equal(400);
        });
    });

    describe('GET /api/analytics/focus/:studentId', () => {
        it('should get student focus analytics', async () => {
            const res = await request(app)
                .get(`/api/analytics/focus/${studentId}`)
                .set('Authorization', `Bearer ${authToken}`);

            expect(res.status).to.equal(200);
            expect(res.body).to.have.property('focusData');
            expect(res.body).to.have.property('summary');
        });
    });

    describe('GET /api/analytics/class/:classId', () => {
        it('should get class engagement metrics', async () => {
            const res = await request(app)
                .get('/api/analytics/class/CLASS_001')
                .set('Authorization', `Bearer ${authToken}`);

            expect(res.status).to.equal(200);
            expect(res.body).to.have.property('analytics');
            expect(res.body).to.have.property('summary');
            expect(res.body.summary).to.have.property('averageClassFocus');
        });
    });
});
