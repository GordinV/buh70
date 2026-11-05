'use strict';

const readMail = require('../routes/raama/readMail');

describe('readMail - accountant notification filtering for "Muud vead"', () => {
    let mockTransporter;

    beforeEach(() => {
        mockTransporter = {
            sendMail: jest.fn().mockResolvedValue({
                messageId: '<test-message-id@narva.ee>',
                response: '250 OK'
            })
        };
    });

    describe('isMuudVeadStatus', () => {
        test('correctly identifies "Muud vead" status regardless of case or whitespace', () => {
            expect(readMail.isMuudVeadStatus('Muud vead')).toBe(true);
            expect(readMail.isMuudVeadStatus('muud vead')).toBe(true);
            expect(readMail.isMuudVeadStatus('MUUD VEAD')).toBe(true);
            expect(readMail.isMuudVeadStatus('  Muud vead  ')).toBe(true);
            expect(readMail.isMuudVeadStatus('muud_vead')).toBe(true);
        });

        test('returns false for other statuses or falsy values', () => {
            expect(readMail.isMuudVeadStatus('Aadressi viga')).toBe(false);
            expect(readMail.isMuudVeadStatus('Postkast täis')).toBe(false);
            expect(readMail.isMuudVeadStatus('Domeeni viga')).toBe(false);
            expect(readMail.isMuudVeadStatus('Tagastatud')).toBe(false);
            expect(readMail.isMuudVeadStatus(null)).toBe(false);
            expect(readMail.isMuudVeadStatus(undefined)).toBe(false);
            expect(readMail.isMuudVeadStatus('')).toBe(false);
        });
    });

    describe('sendAccountantNotificationEmail', () => {
        test('does not send email and returns null when all invoices have "Muud vead" status', async () => {
            const invoices = [
                {
                    doc_number: '101',
                    recipient_email: 'client1@example.com',
                    status: 'Muud vead',
                    reason: 'Määramata saatmise tõrge'
                },
                {
                    doc_number: '102',
                    recipient_email: 'client2@example.com',
                    status: 'Muud vead',
                    reason: 'Tundmatu viga'
                }
            ];

            const result = await readMail.sendAccountantNotificationEmail(
                'raamatupidaja@narva.ee',
                invoices,
                12345,
                mockTransporter
            );

            expect(result).toBeNull();
            expect(mockTransporter.sendMail).not.toHaveBeenCalled();
        });

        test('filters out "Muud vead" invoices and sends notification only with valid errors', async () => {
            const invoices = [
                {
                    doc_number: '101',
                    recipient_email: 'client1@example.com',
                    status: 'Muud vead',
                    reason: 'Määramata viga'
                },
                {
                    doc_number: '102',
                    recipient_email: 'client2@example.com',
                    status: 'Aadressi viga',
                    reason: 'User unknown'
                }
            ];

            const result = await readMail.sendAccountantNotificationEmail(
                'raamatupidaja@narva.ee',
                invoices,
                12345,
                mockTransporter
            );

            expect(result).toBeDefined();
            expect(mockTransporter.sendMail).toHaveBeenCalledTimes(1);

            const mailOptions = mockTransporter.sendMail.mock.calls[0][0];
            expect(mailOptions.to).toBe('raamatupidaja@narva.ee');
            expect(mailOptions.subject).toContain('(1 tk)');
            expect(mailOptions.text).toContain('102');
            expect(mailOptions.text).not.toContain('101');
            expect(mailOptions.html).toContain('102');
            expect(mailOptions.html).not.toContain('101');
        });

        test('returns null if invoice list is empty or accountantEmail is missing', async () => {
            const res1 = await readMail.sendAccountantNotificationEmail(null, [{ doc_number: '101', status: 'Aadressi viga' }], 12345, mockTransporter);
            expect(res1).toBeNull();

            const res2 = await readMail.sendAccountantNotificationEmail('raamatupidaja@narva.ee', [], 12345, mockTransporter);
            expect(res2).toBeNull();

            expect(mockTransporter.sendMail).not.toHaveBeenCalled();
        });
    });

    describe('notifyAccountantsAboutFailedInvoices', () => {
        test('does not send any email when all invoices have "Muud vead" status', async () => {
            const cancelResults = [
                { doc_number: '101', email: 'acc1@narva.ee', status: 'success' },
                { doc_number: '102', email: 'acc2@narva.ee', status: 'success' }
            ];

            const deliveryErrors = [
                { doc_number: '101', status: 'Muud vead', reason: 'Määramata saatmise tõrge' },
                { doc_number: '102', status: 'Muud vead', reason: 'Tundmatu viga' }
            ];

            const res = await readMail.notifyAccountantsAboutFailedInvoices(
                cancelResults,
                deliveryErrors,
                12345,
                mockTransporter
            );

            expect(res.groupedCount).toBe(0);
            expect(Object.keys(res.results).length).toBe(0);
            expect(mockTransporter.sendMail).not.toHaveBeenCalled();
        });

        test('only sends notification to accountant who has valid non-"Muud vead" invoices', async () => {
            const cancelResults = [
                { doc_number: '101', email: 'acc1@narva.ee', status: 'success' },
                { doc_number: '102', email: 'acc2@narva.ee', status: 'success' }
            ];

            const deliveryErrors = [
                { doc_number: '101', status: 'Muud vead', reason: 'Määramata viga' },
                { doc_number: '102', status: 'Postkast täis', reason: 'Quota exceeded' }
            ];

            const res = await readMail.notifyAccountantsAboutFailedInvoices(
                cancelResults,
                deliveryErrors,
                12345,
                mockTransporter
            );

            expect(res.groupedCount).toBe(1);
            expect(res.results['acc2@narva.ee']).toBeDefined();
            expect(res.results['acc2@narva.ee'].success).toBe(true);
            expect(res.results['acc2@narva.ee'].count).toBe(1);
            expect(res.results['acc1@narva.ee']).toBeUndefined();

            expect(mockTransporter.sendMail).toHaveBeenCalledTimes(1);
            const callArgs = mockTransporter.sendMail.mock.calls[0][0];
            expect(callArgs.to).toBe('acc2@narva.ee');
            expect(callArgs.text).toContain('102');
            expect(callArgs.text).not.toContain('101');
        });

        test('filters out "Muud vead" when accountant has mixed invoices', async () => {
            const cancelResults = [
                { doc_number: '101', email: 'acc1@narva.ee', status: 'success' },
                { doc_number: '102', email: 'acc1@narva.ee', status: 'success' }
            ];

            const deliveryErrors = [
                { doc_number: '101', status: 'Muud vead', reason: 'Määramata viga' },
                { doc_number: '102', status: 'Domeeni viga', reason: 'DNS lookup failed' }
            ];

            const res = await readMail.notifyAccountantsAboutFailedInvoices(
                cancelResults,
                deliveryErrors,
                12345,
                mockTransporter
            );

            expect(res.groupedCount).toBe(1);
            expect(res.results['acc1@narva.ee']).toBeDefined();
            expect(res.results['acc1@narva.ee'].count).toBe(1);

            expect(mockTransporter.sendMail).toHaveBeenCalledTimes(1);
            const callArgs = mockTransporter.sendMail.mock.calls[0][0];
            expect(callArgs.to).toBe('acc1@narva.ee');
            expect(callArgs.subject).toContain('(1 tk)');
            expect(callArgs.text).toContain('102');
            expect(callArgs.text).not.toContain('101');
        });
    });

    describe('sendOtherErrorsAlertEmail', () => {
        test('includes subject and email body in notification for "Muud vead"', async () => {
            const otherErrors = [
                {
                    doc_number: '073-1234',
                    recipient_email: 'client@example.ee',
                    status: 'Muud vead',
                    reason: 'Määramata saatmise tõrge',
                    subject: 'Arve nr 073-1234 saatmine',
                    body: 'Delivery failed due to remote server internal temporary error 451 4.3.0'
                }
            ];

            const result = await readMail.sendOtherErrorsAlertEmail(otherErrors, 99999, mockTransporter);

            expect(result).toBeDefined();
            expect(mockTransporter.sendMail).toHaveBeenCalledTimes(1);

            const mailOptions = mockTransporter.sendMail.mock.calls[0][0];
            expect(mailOptions.to).toContain('vladislav.gordin@gmail.com');
            expect(mailOptions.to).toContain('andrei.vargunin@narva.ee');
            expect(mailOptions.subject).toBe('buh70: E-posti saatmise vead (Muud vead)');

            // Проверка text версии
            expect(mailOptions.text).toContain('Arve nr: 073-1234');
            expect(mailOptions.text).toContain('Teema: Arve nr 073-1234 saatmine');
            expect(mailOptions.text).toContain('Kirja sisu:');
            expect(mailOptions.text).toContain('Delivery failed due to remote server internal temporary error 451 4.3.0');

            // Проверка html версии
            expect(mailOptions.html).toContain('073-1234');
            expect(mailOptions.html).toContain('Arve nr 073-1234 saatmine');
            expect(mailOptions.html).toContain('Delivery failed due to remote server internal temporary error 451 4.3.0');
        });

        test('separates invoice and teatis errors into separate tables in "Muud vead" notification', async () => {
            const otherErrors = [
                {
                    doc_type: 'ARV',
                    doc_number: '073-1234',
                    recipient_email: 'arve.client@example.ee',
                    status: 'Muud vead',
                    reason: 'Määramata arve viga',
                    subject: 'Saadan dokument nr. 073-1234, 0730123456',
                    body: 'Remote MTA error for invoice 073-1234'
                },
                {
                    doc_type: 'TEATIS',
                    doc_number: '104',
                    recipient_email: 'teatis.client@example.ee',
                    status: 'Muud vead',
                    reason: 'Määramata teatise viga',
                    subject: 'Saadan dokument nr. 104',
                    body: 'Remote MTA error for teatis 104 maksevõla teatis'
                }
            ];

            const result = await readMail.sendOtherErrorsAlertEmail(otherErrors, 11111, mockTransporter);

            expect(result).toBeDefined();
            expect(mockTransporter.sendMail).toHaveBeenCalledTimes(1);

            const mailOptions = mockTransporter.sendMail.mock.calls[0][0];

            // Проверка разделения в HTML
            expect(mailOptions.html).toContain('Arved (счета) - 1 tk');
            expect(mailOptions.html).toContain('Teatised (извещения - automailerTeatis) - 1 tk');
            expect(mailOptions.html).toContain('073-1234');
            expect(mailOptions.html).toContain('104');

            // Проверка разделения в TEXT
            expect(mailOptions.text).toContain('=== ARVED (СЧЕТА) (1 tk) ===');
            expect(mailOptions.text).toContain('=== TEATISED (ИЗВЕЩЕНИЯ - automailerTeatis) (1 tk) ===');
            expect(mailOptions.text).toContain('Arve nr: 073-1234');
            expect(mailOptions.text).toContain('Teatise nr: 104');
        });

        test('returns null when errors list has no valid doc numbers', async () => {
            const res = await readMail.sendOtherErrorsAlertEmail([
                { doc_number: 'N/A', status: 'Muud vead' },
                { doc_number: '', status: 'Muud vead' }
            ], 99999, mockTransporter);

            expect(res).toBeNull();
            expect(mockTransporter.sendMail).not.toHaveBeenCalled();
        });
    });

    describe('parseIncomingEmail', () => {
        test('extracts subject and decoded body into error object', () => {
            const raw = 'Subject: Mail delivery failed: returning message to sender\r\n' +
                'From: Mail Delivery System <mailer-daemon@narva.ee>\r\n' +
                'Date: Wed, 05 Nov 2026 10:00:00 +0200\r\n\r\n' +
                'This message was created automatically by mail delivery software.\n' +
                'A message that you sent could not be delivered to one or more of its recipients.\n' +
                'Arve nr: 095-9641\n' +
                'Recipient: client@narva.ee\n';

            const parsed = readMail.parseIncomingEmail(raw);
            expect(parsed).toBeDefined();
            expect(parsed.doc_number).toBe('095-9641');
            expect(parsed.subject).toBe('Mail delivery failed: returning message to sender');
            expect(parsed.body).toContain('Arve nr: 095-9641');
            expect(parsed.body_text).toContain('This message was created automatically');
            expect(parsed.doc_type).toBe('ARV');
        });

        test('identifies teatis email and sets doc_type to TEATIS', () => {
            const raw = 'Subject: Delivery Status Notification (Failure)\r\n' +
                'From: postmaster@mail.narva.ee\r\n\r\n' +
                'Message could not be delivered to recipient.\n' +
                'Subject: Saadan dokument nr. 45\n' +
                'MAKSEVÕLA TEATIS NR-45\n' +
                'Recipient: client@example.com\n';

            const parsed = readMail.parseIncomingEmail(raw);
            expect(parsed).toBeDefined();
            expect(parsed.doc_type).toBe('TEATIS');
            expect(parsed.doc_number).toBe('45');
            expect(parsed.status).toBe('Muud vead');
        });
    });

    describe('isTeatisEmail & isTeatisError', () => {
        test('correctly identifies teatis and separates from invoices', () => {
            expect(readMail.isTeatisEmail('MAKSEVÕLA TEATIS', 'Saadan dokument nr. 12')).toBe(true);
            expect(readMail.isTeatisEmail('automailerTeatis delivery', '')).toBe(true);
            expect(readMail.isTeatisEmail('', 'Saadan dokument nr. 12')).toBe(true);
            expect(readMail.isTeatisEmail('', 'Saadan dokument nr. 073-1234, 0730123456')).toBe(false);

            expect(readMail.isTeatisError({ doc_type: 'TEATIS' })).toBe(true);
            expect(readMail.isTeatisError({ subject: 'Saadan dokument nr. 55', body: 'maksevõla teatis' })).toBe(true);
            expect(readMail.isTeatisError({ doc_type: 'ARV', subject: 'Saadan dokument nr. 073-1234, 0730123456' })).toBe(false);
        });
    });
});
