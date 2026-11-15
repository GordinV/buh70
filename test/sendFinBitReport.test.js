'use strict';

const db = require('../libs/db');
const nodemailer = require('nodemailer');

jest.mock('../libs/db', () => ({
    queryDb: jest.fn()
}));

jest.mock('nodemailer', () => ({
    createTransport: jest.fn()
}));

const sendFinBitReport = require('../routes/raama/sendFinBitReport');

describe('sendFinBitReport unit tests', () => {
    let mockTransporter;

    beforeEach(() => {
        jest.clearAllMocks();
        mockTransporter = {
            sendMail: jest.fn().mockReturnValue(Promise.resolve({
                messageId: 'test-message-id-123',
                response: '250 2.0.0 Ok: queued as test-id'
            }))
        };
        nodemailer.createTransport.mockReturnValue(mockTransporter);
    });

    describe('Email Formatting', () => {
        test('formatInvoiceEmailText formats invoice details correctly', () => {
            const invoices = [
                { asutus: 'LINNAKANTSELEI TEST', number: '3307', kontr_agent: 'AVILON AUTO' },
                { asutus: 'LINNAKANTSELEI TEST', number: '10526995', kontr_agent: 'Infotark AS' }
            ];

            const text = sendFinBitReport.formatInvoiceEmailText(invoices);
            expect(text).toContain('Süsteemi on imporditud järgmised e-arved:');
            expect(text).toContain('1. Arve nr: 3307 | Hankija: AVILON AUTO | Asutus: LINNAKANTSELEI TEST');
            expect(text).toContain('2. Arve nr: 10526995 | Hankija: Infotark AS | Asutus: LINNAKANTSELEI TEST');
            expect(text).toContain('Kokku: 2 arve(t).');
        });

        test('formatInvoiceEmailText handles empty invoice list', () => {
            const text = sendFinBitReport.formatInvoiceEmailText([]);
            expect(text).toContain('Arveid ei leitud');
        });

        test('formatInvoiceEmailHtml formats HTML table and escapes special chars', () => {
            const invoices = [
                { asutus: 'LINNAKANTSELEI <TEST>', number: '3307 & 1', kontr_agent: '"AVILON" AUTO' }
            ];

            const html = sendFinBitReport.formatInvoiceEmailHtml(invoices);
            expect(html).toContain('LINNAKANTSELEI &lt;TEST&gt;');
            expect(html).toContain('3307 &amp; 1');
            expect(html).toContain('&quot;AVILON&quot; AUTO');
            expect(html).toContain('Kokku imporditud: <strong>1</strong> arve(t).');
        });
    });

    describe('getReport', () => {
        test('calls docs.get_arve_kinnitaja with logId', async () => {
            const mockDbResult = {
                error_code: 0,
                result: 1,
                data: [
                    {
                        email: 'raamatupidaja@narva.ee',
                        arved: [{ asutus: 'TEST', number: '100', kontr_agent: 'Firma' }]
                    }
                ]
            };
            db.queryDb.mockReturnValueOnce(Promise.resolve(mockDbResult));

            const result = await sendFinBitReport.getReport(8129348);
            expect(db.queryDb).toHaveBeenCalledWith(
                expect.stringContaining('select * from docs.get_arve_kinnitaja($1)'),
                [8129348],
                null, null, null, null,
                expect.any(Object)
            );
            expect(result.data).toHaveLength(1);
            expect(result.data[0].email).toBe('raamatupidaja@narva.ee');
        });
    });

    describe('sendNotificationEmail & sendFinBitReportNotifications', () => {
        test('sendNotificationEmail sends email with expected params', async () => {
            const smtpConfig = {
                host: 'smtp.zone.eu',
                port: 465,
                secure: true,
                from: 'robot@narva.ee',
                userName: 'Buh70 Robot'
            };
            const invoices = [{ asutus: 'TEST', number: '100', kontr_agent: 'Vendor' }];

            const info = await sendFinBitReport.sendNotificationEmail(
                'accountant@narva.ee',
                invoices,
                smtpConfig,
                mockTransporter
            );

            expect(mockTransporter.sendMail).toHaveBeenCalledTimes(1);
            const callArgs = mockTransporter.sendMail.mock.calls[0][0];
            expect(callArgs.to).toBe('accountant@narva.ee');
            expect(callArgs.from).toContain('robot@narva.ee');
            expect(callArgs.subject).toContain('Teavitus: imporditud e-arved (1 tk)');
            expect(callArgs.text).toContain('100');
            expect(info.messageId).toBe('test-message-id-123');
        });

        test('sendFinBitReportNotifications handles array and json string arved for multiple recipients', async () => {
            const reportData = {
                data: [
                    {
                        email: 'user1@narva.ee',
                        arved: [{ asutus: 'ASUTUS 1', number: 'A-1', kontr_agent: 'PARTNER 1' }]
                    },
                    {
                        email_to: 'user2@narva.ee',
                        arved: JSON.stringify([{ asutus: 'ASUTUS 2', number: 'B-2', kontr_agent: 'PARTNER 2' }])
                    }
                ]
            };

            const results = await sendFinBitReport.sendFinBitReportNotifications(reportData, 2477, {
                transporter: mockTransporter,
                smtpConfig: { host: 'smtp.zone.eu', port: 465, secure: true, from: 'noreply@narva.ee' }
            });

            expect(results).toHaveLength(2);
            expect(results[0].success).toBe(true);
            expect(results[0].email).toBe('user1@narva.ee');
            expect(results[1].success).toBe(true);
            expect(results[1].email).toBe('user2@narva.ee');
            expect(mockTransporter.sendMail).toHaveBeenCalledTimes(2);
        });

        test('getSenderAddress correctly formats sender email', () => {
            expect(sendFinBitReport.getSenderAddress('palk')).toBe('palk@narva.ee');
            expect(sendFinBitReport.getSenderAddress('custom@test.ee')).toBe('custom@test.ee');
            expect(sendFinBitReport.getSenderAddress(null)).toBe('noreply@narva.ee');
        });

        test('sendFinBitReportNotifications uses SMTP config returned directly in row from docs.get_arve_kinnitaja', async () => {
            const reportData = {
                data: [
                    {
                        email: 'kinnitaja@narva.ee',
                        arved: [{ asutus: 'LINNAKANTSELEI', number: '777', kontr_agent: 'Vendor' }],
                        smtp: 'smtp.custom.ee',
                        smtp_port: '587',
                        smtp_pass: 'secret123',
                        smtp_user: 'earved_robot'
                    }
                ]
            };

            const results = await sendFinBitReport.sendFinBitReportNotifications(reportData, 2477);

            expect(nodemailer.createTransport).toHaveBeenCalledWith(expect.objectContaining({
                host: 'smtp.custom.ee',
                port: 587,
                secure: false,
                auth: {
                    user: 'earved_robot',
                    pass: 'secret123'
                }
            }));
            expect(results).toHaveLength(1);
            expect(results[0].success).toBe(true);
            expect(mockTransporter.sendMail).toHaveBeenCalledWith(expect.objectContaining({
                to: 'kinnitaja@narva.ee',
                from: expect.stringContaining('earved_robot@narva.ee')
            }));
        });
    });

    describe('Express Handler exports.main', () => {
        test('returns 400 when logId is missing', async () => {
            const req = { query: {}, body: {}, params: {} };
            const res = {
                status: jest.fn().mockReturnThis(),
                send: jest.fn().mockReturnThis()
            };

            await sendFinBitReport.main(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.send).toHaveBeenCalledWith(expect.objectContaining({
                status: 400,
                error_message: expect.stringContaining('Param logId is missing')
            }));
        });

        test('creates log in ou.logs and returns 200 with STARTED status', async () => {
            db.queryDb
                // createLog
                .mockReturnValueOnce(Promise.resolve({ data: [{ id: 9901 }] }))
                // getImportInfo in background (импорт создал 0 документов -> рассылки нет)
                .mockReturnValueOnce(Promise.resolve({ data: [{ flow: 'docs.sp_loe_earved', imported: [], total_imported: '0' }] }))
                // endLog in background
                .mockReturnValueOnce(Promise.resolve({ data: [] }));

            const req = {
                body: { logId: 8129348, user_id: 2477, rekv_id: 63 }
            };
            const res = {
                status: jest.fn().mockReturnThis(),
                send: jest.fn().mockReturnThis()
            };

            await sendFinBitReport.main(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.send).toHaveBeenCalledWith(expect.objectContaining({
                status: 200,
                result: 1,
                log_id: 9901,
                data: expect.objectContaining({
                    action: 'sendFinBitReport',
                    status: 'STARTED',
                    log_id: 9901
                })
            }));
        });
    });

    describe('executeReport', () => {
        test('synchronously executes full workflow: createLog -> getReport -> send -> endLog', async () => {
            db.queryDb
                // 1. createLog
                .mockReturnValueOnce(Promise.resolve({ data: [{ id: 501 }] }))
                // 1.1 getImportInfo: импорт создал 1 документ
                .mockReturnValueOnce(Promise.resolve({ data: [{ flow: 'docs.sp_loe_earved', imported: [{ doc_id: 1 }] }] }))
                // 2. getReport
                .mockReturnValueOnce(Promise.resolve({
                    data: [
                        {
                            email: 'target@narva.ee',
                            arved: [
                                { asutus: 'LINNAKANTSELEI TEST', number: '3307', kontr_agent: 'AVILON AUTO' }
                            ]
                        }
                    ]
                }))
                // 2.1 getAlreadySentEmails: ранее никому не отправлено
                .mockReturnValueOnce(Promise.resolve({ data: [] }))
                // 3. endLog
                .mockReturnValueOnce(Promise.resolve({ data: [] }));

            const result = await sendFinBitReport.executeReport(2477, 63, 8129348, {
                transporter: mockTransporter,
                smtpConfig: { host: 'smtp.zone.eu', port: 465, secure: true, from: 'noreply@narva.ee' }
            });

            expect(result.logId).toBe(501);
            expect(result.sendResults).toHaveLength(1);
            expect(result.sendResults[0].success).toBe(true);
            expect(result.sendResults[0].response).toContain('250 2.0.0 Ok');
            expect(mockTransporter.sendMail).toHaveBeenCalledTimes(1);

            // Проверяем вызов endLog с успехом, сохранением JSON результата и ответа почтового сервера
            expect(db.queryDb).toHaveBeenLastCalledWith(
                expect.stringContaining('update ou.logs'),
                [
                    'success',
                    null,
                    expect.stringContaining('250 2.0.0 Ok'),
                    expect.stringContaining('target@narva.ee: 250 2.0.0 Ok: queued as test-id'),
                    501,
                    null
                ],
                null, null, null, null,
                expect.any(Object)
            );
        });

        test('handles error and logs failure to ou.logs', async () => {
            db.queryDb
                // 1. createLog
                .mockReturnValueOnce(Promise.resolve({ data: [{ id: 502 }] }))
                // 1.1 getImportInfo
                .mockReturnValueOnce(Promise.resolve({ data: [{ flow: 'docs.sp_loe_earved', imported: [{ doc_id: 1 }] }] }))
                // 2. getReport fails
                .mockReturnValueOnce(Promise.reject(new Error('DB Connection lost')))
                // 3. endLog (failed)
                .mockReturnValueOnce(Promise.resolve({ data: [] }));

            let error = null;
            try {
                await sendFinBitReport.executeReport(2477, 63, 8129348);
            } catch (err) {
                error = err;
            }
            expect(error).not.toBeNull();
            expect(error.message).toContain('DB Connection lost');

            expect(db.queryDb).toHaveBeenLastCalledWith(
                expect.stringContaining('update ou.logs'),
                ['failed', expect.stringContaining('DB Connection lost'), null, null, 502, JSON.stringify({ retryable: true })],
                null, null, null, null,
                expect.any(Object)
            );
        });
    });

    describe('processReport: нет новых счетов / получатели / идемпотентность', () => {
        const smtpOptions = () => ({
            transporter: mockTransporter,
            smtpConfig: { host: 'smtp.zone.eu', port: 465, secure: true, from: 'noreply@narva.ee' }
        });

        test('импорт создал 0 документов -> success (no_op), get_arve_kinnitaja не вызывается, письма не уходят', async () => {
            db.queryDb.mockReturnValueOnce(Promise.resolve({ data: [{ flow: 'docs.sp_loe_earved', imported: [], total_imported: '0' }] }));

            const outcome = await sendFinBitReport.processReport(8563304, 2477, 9001, smtpOptions());

            expect(outcome.status).toBe('success');
            expect(outcome.noOp).toBe(true);
            expect(outcome.sendResults).toEqual([]);
            expect(outcome.response).toContain('Uusi arveid ei imporditud');
            expect(db.queryDb).toHaveBeenCalledTimes(1);
            expect(mockTransporter.sendMail).not.toHaveBeenCalled();
        });

        test('лог импорта не найден или другой flow -> failed, retryable=false', async () => {
            db.queryDb.mockReturnValueOnce(Promise.resolve({ data: [] }));
            const notFound = await sendFinBitReport.processReport(1, 2477, 9001, smtpOptions());
            expect(notFound.status).toBe('failed');
            expect(notFound.retryable).toBe(false);
            expect(notFound.errorMessage).toContain('Impordi logi ei leitud');

            db.queryDb.mockReturnValueOnce(Promise.resolve({ data: [{ flow: 'getEarved', imported: null }] }));
            const wrongFlow = await sendFinBitReport.processReport(2, 2477, 9001, smtpOptions());
            expect(wrongFlow.status).toBe('failed');
            expect(wrongFlow.retryable).toBe(false);
        });

        test('документы импортированы, но получателей нет -> failed, retryable=false', async () => {
            db.queryDb
                .mockReturnValueOnce(Promise.resolve({ data: [{ flow: 'docs.sp_loe_earved', imported: [{ doc_id: 5 }] }] }))
                .mockReturnValueOnce(Promise.resolve({ data: [] }));

            const outcome = await sendFinBitReport.processReport(8563304, 2477, 9001, smtpOptions());

            expect(outcome.status).toBe('failed');
            expect(outcome.retryable).toBe(false);
            expect(outcome.errorMessage).toContain('saajaid ei leitud');
        });

        test('лог импорта старого формата (без result.imported): используется totalImported', async () => {
            db.queryDb.mockReturnValueOnce(Promise.resolve({ data: [{ flow: 'docs.sp_loe_earved', imported: null, total_imported: '3' }] }));
            const info = await sendFinBitReport.getImportInfo(10);
            expect(info.importedCount).toBe(3);
        });

        test('повтор после частичного сбоя: получившим письмо повторно не отправляем', async () => {
            db.queryDb
                .mockReturnValueOnce(Promise.resolve({ data: [{ flow: 'docs.sp_loe_earved', imported: [{ doc_id: 1 }, { doc_id: 2 }] }] }))
                .mockReturnValueOnce(Promise.resolve({
                    data: [
                        { email: 'Done@narva.ee', arved: [{ number: '1' }] },
                        { email: 'todo@narva.ee', arved: [{ number: '2' }] }
                    ]
                }))
                // предыдущий запуск: Done@narva.ee получил письмо, todo@narva.ee - нет
                .mockReturnValueOnce(Promise.resolve({
                    data: [{ result: [
                        { email: 'done@narva.ee', success: true },
                        { email: 'todo@narva.ee', success: false, error: 'connect ETIMEDOUT' }
                    ] }]
                }));

            const outcome = await sendFinBitReport.processReport(8563304, 2477, 9002, smtpOptions());

            expect(mockTransporter.sendMail).toHaveBeenCalledTimes(1);
            expect(mockTransporter.sendMail.mock.calls[0][0].to).toBe('todo@narva.ee');
            expect(outcome.status).toBe('success');
            expect(outcome.sendResults[0].already_sent).toBe(true);
            expect(outcome.sendResults[1].success).toBe(true);
        });

        test('SMTP-сбой части получателей -> failed, retryable=true', async () => {
            mockTransporter.sendMail
                .mockReturnValueOnce(Promise.resolve({ messageId: 'm1', response: '250 OK' }))
                .mockReturnValueOnce(Promise.reject(new Error('connect ETIMEDOUT')));
            db.queryDb
                .mockReturnValueOnce(Promise.resolve({ data: [{ flow: 'docs.sp_loe_earved', imported: [{ doc_id: 1 }] }] }))
                .mockReturnValueOnce(Promise.resolve({
                    data: [
                        { email: 'a@narva.ee', arved: [{ number: '1' }] },
                        { email: 'b@narva.ee', arved: [{ number: '2' }] }
                    ]
                }))
                .mockReturnValueOnce(Promise.resolve({ data: [] }));

            const outcome = await sendFinBitReport.processReport(8563304, 2477, 9003, smtpOptions());

            expect(outcome.status).toBe('failed');
            expect(outcome.retryable).toBe(true);
            expect(outcome.errorMessage).toContain('1 / 2');
        });

        test('evaluateSendResults: только отсутствие адреса -> retryable=false; все успешно -> success', () => {
            expect(sendFinBitReport.evaluateSendResults([{ success: true }, { success: true, already_sent: true }]).status).toBe('success');
            const missing = sendFinBitReport.evaluateSendResults([{ success: false, error: 'Recipient email is missing' }]);
            expect(missing.status).toBe('failed');
            expect(missing.retryable).toBe(false);
        });
    });

    describe('endLog and endReport function', () => {
        test('endLog / endReport saves mail server response and structured result into propertis', async () => {
            db.queryDb.mockReturnValueOnce(Promise.resolve({ data: [] }));

            const sendResults = [
                {
                    email: 'user1@narva.ee',
                    invoicesCount: 2,
                    success: true,
                    messageId: 'msg-1',
                    response: '250 2.0.0 Ok: queued as abc'
                },
                {
                    email: 'user2@narva.ee',
                    invoicesCount: 1,
                    success: false,
                    error: 'Mailbox full',
                    response: '552 5.2.2 Mailbox full'
                }
            ];

            await sendFinBitReport.endReport(1001, 'success', sendResults);

            expect(db.queryDb).toHaveBeenCalledWith(
                expect.stringContaining('update ou.logs'),
                [
                    'success',
                    null,
                    expect.stringContaining('user1@narva.ee'),
                    'user1@narva.ee: 250 2.0.0 Ok: queued as abc; user2@narva.ee: 552 5.2.2 Mailbox full',
                    1001,
                    null
                ],
                null, null, null, null,
                expect.any(Object)
            );
        });
    });
});
