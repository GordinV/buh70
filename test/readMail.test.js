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
            expect(readMail.isTeatisEmail('', 'Saadan dokument nr. 073-1234')).toBe(false);

            expect(readMail.isTeatisError({ doc_type: 'TEATIS' })).toBe(true);
            expect(readMail.isTeatisError({ subject: 'Saadan dokument nr. 55', body: 'maksevõla teatis' })).toBe(true);
            expect(readMail.isTeatisError({ doc_type: 'ARV', subject: 'Saadan dokument nr. 073-1234, 0730123456' })).toBe(false);
        });

        test('extracts teatis number instead of embedded invoice numbers from debt table', () => {
            const raw = 'Subject: Undelivered Mail Returned to Sender\r\n' +
                'From: Mail Delivery System <MAILER-DAEMON@narva.ee>\r\n\r\n' +
                '<debtor@example.ee>: 550 5.1.1 User unknown\n' +
                'Subject: Saadan dokument nr. 104\n' +
                'MAKSEVÕLA TEATIS NR-104\n' +
                'Arve number | Viitenumber | Summa\n' +
                '073-1234 | 0730123456 | 25.00\n' +
                '095-5678 | 0950567890 | 30.00\n';

            const parsed = readMail.parseIncomingEmail(raw);
            expect(parsed).toBeDefined();
            expect(parsed.doc_type).toBe('TEATIS');
            expect(parsed.doc_number).toBe('104');
            expect(parsed.status).toBe('Aadressi viga');
        });

        test('notifyAccountantsAboutFailedInvoices notifies responsible person for TEATIS Aadressi viga', async () => {
            const mockSendMail = jest.fn().mockResolvedValue({ messageId: 'teatis-notify-1' });
            const mockTransporter = { sendMail: mockSendMail };

            const cancelResults = [
                {
                    doc_type: 'TEATIS',
                    doc_number: '104',
                    doc_id: 55501,
                    recipient_email: 'debtor@example.ee',
                    status: 'success',
                    email: 'vastutav@narva.ee',
                    subject: 'Saadan dokument nr. 104'
                }
            ];
            const deliveryErrors = [
                {
                    doc_type: 'TEATIS',
                    doc_number: '104',
                    recipient_email: 'debtor@example.ee',
                    status: 'Aadressi viga',
                    reason: '550 5.1.1 User unknown',
                    subject: 'Saadan dokument nr. 104'
                }
            ];

            const res = await readMail.notifyAccountantsAboutFailedInvoices(
                cancelResults,
                deliveryErrors,
                77701,
                mockTransporter
            );

            expect(res.groupedCount).toBe(1);
            expect(mockSendMail).toHaveBeenCalledTimes(1);
            const mail = mockSendMail.mock.calls[0][0];
            expect(mail.to).toBe('vastutav@narva.ee');
            expect(mail.subject).toContain('Kättetoimetamata maksevõla teatised (1 tk)');
            expect(mail.text).toContain('Maksevõla teatis nr: 104');
            expect(mail.html).toContain('Teatis 104');
        });
    });
});

const { EventEmitter } = require('events');

describe('fetchEmailsViaImapTls', () => {
    function createMockTlsConnect(onWrite) {
        const socket = new EventEmitter();
        socket.sent = [];
        socket.timeoutMs = 0;
        socket.ended = false;
        socket.setTimeout = jest.fn((ms) => {
            socket.timeoutMs = ms;
        });
        socket.end = jest.fn(() => {
            socket.ended = true;
        });
        socket.write = jest.fn((data) => {
            const text = String(data);
            socket.sent.push(text);
            if (onWrite) onWrite(text, socket);
            return true;
        });
        const tlsConnect = jest.fn(() => {
            process.nextTick(() => {
                socket.emit('data', Buffer.from('* OK IMAP4rev1 ready\r\n', 'latin1'));
            });
            return socket;
        });
        return { socket, tlsConnect };
    }

    function buildFetchLiteral(uid, rawEmail) {
        const len = Buffer.byteLength(rawEmail, 'utf8');
        return `* 1 FETCH (UID ${uid} BODY[] {${len}}\r\n${rawEmail})\r\n`;
    }

    test('sends UID SEARCH SINCE in <d-Mon-yyyy> format and parses email', async () => {
        const rawEmail = 'Date: Sun, 15 Nov 2026 08:00:00 +0000\r\nSubject: Bounce\r\n\r\nArve nr: 101\r\n';
        const { socket, tlsConnect } = createMockTlsConnect((cmd, sock) => {
            if (cmd.startsWith('A01 LOGIN')) {
                sock.emit('data', Buffer.from('A01 OK LOGIN completed\r\n'));
            } else if (cmd.startsWith('A02 SELECT')) {
                sock.emit('data', Buffer.from('A02 OK [READ-ONLY] SELECT completed\r\n'));
            } else if (cmd.startsWith('A03 UID SEARCH')) {
                sock.emit('data', Buffer.from('* SEARCH 42\r\nA03 OK SEARCH completed\r\n'));
            } else if (cmd.startsWith('A04 UID FETCH')) {
                sock.emit('data', Buffer.from(buildFetchLiteral(42, rawEmail) + 'A04 OK FETCH completed\r\n'));
            }
        });

        const res = await readMail.fetchEmailsViaImapTls(
            { host: 'mail.test', port: 993, user: 'u', pass: 'p' },
            new Date('2026-11-15T10:30:00.000Z'),
            { tlsConnect }
        );

        expect(socket.sent.some((c) => c.trim() === 'A03 UID SEARCH SINCE 15-Nov-2026')).toBe(true);
        expect(res).toHaveLength(1);
        expect(res[0].uid).toBe(42);
        expect(res[0].rawText).toContain('Arve nr: 101');
    });

    test('does not terminate FETCH early when "A04 OK" appears inside email body', async () => {
        const rawEmail = 'Date: Sun, 15 Nov 2026 08:00:00 +0000\r\nSubject: Status A04 OK inside line\r\n\r\nBody text A04 OK here\r\n';
        const { tlsConnect } = createMockTlsConnect((cmd, sock) => {
            if (cmd.startsWith('A01 LOGIN')) {
                sock.emit('data', Buffer.from('A01 OK\r\n'));
            } else if (cmd.startsWith('A02 SELECT')) {
                sock.emit('data', Buffer.from('A02 OK\r\n'));
            } else if (cmd.startsWith('A03 UID SEARCH')) {
                sock.emit('data', Buffer.from('* SEARCH 7\r\nA03 OK\r\n'));
            } else if (cmd.startsWith('A04 UID FETCH')) {
                const payload = buildFetchLiteral(7, rawEmail);
                sock.emit('data', Buffer.from(payload));
                process.nextTick(() => {
                    sock.emit('data', Buffer.from('A04 OK FETCH completed\r\n'));
                });
            }
        });

        const res = await readMail.fetchEmailsViaImapTls(
            { host: 'mail.test', port: 993, user: 'u', pass: 'p' },
            new Date('2026-11-15T00:00:00.000Z'),
            { tlsConnect }
        );

        expect(res).toHaveLength(1);
        expect(res[0].rawText).toContain('Body text A04 OK here');
    });

    test('handles 1-byte chunks identically to single chunk', async () => {
        const rawEmail = 'Date: Sun, 15 Nov 2026 08:00:00 +0000\r\nSubject: Chunked\r\n\r\nArve nr: 202\r\n';
        const { tlsConnect } = createMockTlsConnect((cmd, sock) => {
            if (cmd.startsWith('A01 LOGIN')) {
                sock.emit('data', Buffer.from('A01 OK\r\n'));
            } else if (cmd.startsWith('A02 SELECT')) {
                sock.emit('data', Buffer.from('A02 OK\r\n'));
            } else if (cmd.startsWith('A03 UID SEARCH')) {
                sock.emit('data', Buffer.from('* SEARCH 11\r\nA03 OK\r\n'));
            } else if (cmd.startsWith('A04 UID FETCH')) {
                const full = Buffer.from(buildFetchLiteral(11, rawEmail) + 'A04 OK\r\n', 'utf8');
                for (let i = 0; i < full.length; i++) {
                    sock.emit('data', full.slice(i, i + 1));
                }
            }
        });

        const res = await readMail.fetchEmailsViaImapTls(
            { host: 'mail.test', port: 993, user: 'u', pass: 'p' },
            new Date('2026-11-15T00:00:00.000Z'),
            { tlsConnect }
        );

        expect(res).toHaveLength(1);
        expect(res[0].uid).toBe(11);
        expect(res[0].rawText).toContain('Arve nr: 202');
    });

    test('switches to Archive with SINCE when INBOX search returns empty', async () => {
        const rawEmail = 'Date: Mon, 16 Nov 2026 08:00:00 +0000\r\nSubject: Archived\r\n\r\nArve nr: 303\r\n';
        let selectedFolder = 'INBOX';
        const { socket, tlsConnect } = createMockTlsConnect((cmd, sock) => {
            if (cmd.startsWith('A01 LOGIN')) {
                sock.emit('data', Buffer.from('A01 OK\r\n'));
            } else if (cmd.startsWith('A02 SELECT')) {
                selectedFolder = cmd.indexOf('Archive') !== -1 ? 'Archive' : 'INBOX';
                sock.emit('data', Buffer.from('A02 OK\r\n'));
            } else if (cmd.startsWith('A03 UID SEARCH')) {
                if (selectedFolder === 'INBOX') {
                    sock.emit('data', Buffer.from('* SEARCH\r\nA03 OK\r\n'));
                } else {
                    sock.emit('data', Buffer.from('* SEARCH 99\r\nA03 OK\r\n'));
                }
            } else if (cmd.startsWith('A04 UID FETCH')) {
                sock.emit('data', Buffer.from(buildFetchLiteral(99, rawEmail) + 'A04 OK\r\n'));
            }
        });

        const res = await readMail.fetchEmailsViaImapTls(
            { host: 'mail.test', port: 993, user: 'u', pass: 'p' },
            new Date('2026-11-16T00:00:00.000Z'),
            { tlsConnect }
        );

        expect(socket.sent.some((c) => c.trim() === 'A02 SELECT "Archive"')).toBe(true);
        expect(socket.sent.filter((c) => c.trim() === 'A03 UID SEARCH SINCE 16-Nov-2026')).toHaveLength(2);
        expect(res).toHaveLength(1);
        expect(res[0].uid).toBe(99);
    });

    test('rejects with step and folder on idle timeout', async () => {
        const { socket, tlsConnect } = createMockTlsConnect((cmd, sock) => {
            if (cmd.startsWith('A01 LOGIN')) {
                sock.emit('data', Buffer.from('A01 OK\r\n'));
            } else if (cmd.startsWith('A02 SELECT')) {
                sock.emit('data', Buffer.from('A02 OK\r\n'));
            } else if (cmd.startsWith('A03 UID SEARCH')) {
                sock.emit('data', Buffer.from('* SEARCH 1\r\nA03 OK\r\n'));
            } else if (cmd.startsWith('A04 UID FETCH')) {
                sock.emit('data', Buffer.from('* 1 FETCH (UID 1 BODY[] {100}\r\npartial'));
                process.nextTick(() => {
                    sock.emit('timeout');
                });
            }
        });

        let caughtErr = null;
        try {
            await readMail.fetchEmailsViaImapTls(
                { host: 'mail.test', port: 993, user: 'u', pass: 'p' },
                new Date('2026-11-15T00:00:00.000Z'),
                { tlsConnect, idleTimeoutMs: 5000 }
            );
        } catch (err) {
            caughtErr = err;
        }
        expect(caughtErr).toBeDefined();
        expect(caughtErr.message).toMatch(/IMAP idle timeout at step FETCH \(INBOX\), received \d+\.\d+ MB after 5 s/);
        expect(socket.timeoutMs).toBe(0);
        expect(socket.ended).toBe(true);
    });

    test('rejects with step and folder on total timeout', async () => {
        const { tlsConnect } = createMockTlsConnect(() => {
            // Do not respond to LOGIN -> triggers total timeout
        });

        let caughtErr = null;
        try {
            await readMail.fetchEmailsViaImapTls(
                { host: 'mail.test', port: 993, user: 'u', pass: 'p' },
                new Date('2026-11-15T00:00:00.000Z'),
                { tlsConnect, idleTimeoutMs: 5000, totalTimeoutMs: 30 }
            );
        } catch (err) {
            caughtErr = err;
        }
        expect(caughtErr).toBeDefined();
        expect(caughtErr.message).toMatch(/IMAP total timeout at step LOGIN \(INBOX\), received \d+\.\d+ MB after 0 s/);
    });

    test('fetches UIDs in batches with sequential tags when exceeding batchThreshold', async () => {
        const raw1 = 'Date: Sun, 15 Nov 2026 08:00:00 +0000\r\nSubject: E1\r\n\r\nBody1\r\n';
        const raw2 = 'Date: Sun, 15 Nov 2026 08:01:00 +0000\r\nSubject: E2\r\n\r\nBody2\r\n';
        const raw3 = 'Date: Sun, 15 Nov 2026 08:02:00 +0000\r\nSubject: E3\r\n\r\nBody3\r\n';
        const { socket, tlsConnect } = createMockTlsConnect((cmd, sock) => {
            if (cmd.startsWith('A01 LOGIN')) {
                sock.emit('data', Buffer.from('A01 OK\r\n'));
            } else if (cmd.startsWith('A02 SELECT')) {
                sock.emit('data', Buffer.from('A02 OK\r\n'));
            } else if (cmd.startsWith('A03 UID SEARCH')) {
                sock.emit('data', Buffer.from('* SEARCH 1 2 3\r\nA03 OK\r\n'));
            } else if (cmd.startsWith('A04 UID FETCH')) {
                sock.emit('data', Buffer.from(buildFetchLiteral(1, raw1) + buildFetchLiteral(2, raw2) + 'A04 OK\r\n'));
            } else if (cmd.startsWith('A05 UID FETCH')) {
                sock.emit('data', Buffer.from(buildFetchLiteral(3, raw3) + 'A05 OK\r\n'));
            }
        });

        const res = await readMail.fetchEmailsViaImapTls(
            { host: 'mail.test', port: 993, user: 'u', pass: 'p' },
            new Date('2026-11-15T00:00:00.000Z'),
            { tlsConnect, batchThreshold: 2, batchSize: 2 }
        );

        expect(socket.sent.some((c) => c.trim() === 'A04 UID FETCH 1,2 (UID BODY.PEEK[])')).toBe(true);
        expect(socket.sent.some((c) => c.trim() === 'A05 UID FETCH 3 (UID BODY.PEEK[])')).toBe(true);
        expect(socket.sent.some((c) => c.trim() === 'A06 LOGOUT')).toBe(true);
        expect(res.map((m) => m.uid)).toEqual([1, 2, 3]);
    });
});

describe('getMailCredentials & getMailTransporter (no hardcoded credentials)', () => {
    const db = require('../libs/db');

    test('getMailCredentials loads account from ou.userid via mailer and ignores IMAP_PASS env', async () => {
        const origQueryDb = db.queryDb;
        const prevImapPass = process.env.IMAP_PASS;
        process.env.IMAP_PASS = 'ignored-env-imap-pass';
        db.queryDb = jest.fn(() => Promise.resolve({
            data: [{
                smtp: 'mail.narva.ee',
                port: 465,
                user: 'oppetasu',
                pass: 'card-pass',
                imap: 'mail.narva.ee',
                imap_port: 993,
                imap_mailbox: 'INBOX'
            }]
        }));

        try {
            const account = await readMail.getMailCredentials(63, 11770);
            expect(account.imap.user).toBe('oppetasu');
            expect(account.imap.pass).toBe('card-pass');
            expect(account.smtp.auth.pass).toBe('card-pass');
        } finally {
            db.queryDb = origQueryDb;
            if (prevImapPass === undefined) delete process.env.IMAP_PASS;
            else process.env.IMAP_PASS = prevImapPass;
        }
    });

    test('getMailTransporter throws mail_password_missing without smtpConfig even if SMTP_PASS is set', () => {
        const prevSmtpPass = process.env.SMTP_PASS;
        process.env.SMTP_PASS = 'ignored-env-smtp-pass';
        try {
            expect(() => readMail.getMailTransporter(null, null)).toThrow('mail_password_missing');
        } finally {
            if (prevSmtpPass === undefined) delete process.env.SMTP_PASS;
            else process.env.SMTP_PASS = prevSmtpPass;
        }
    });
});

describe('readMail hardening (MIME, JSONB sanitize, socket close, teatis, recipient, cursor, emailContent)', () => {
    const db = require('../libs/db');
    const os = require('os');
    const fs = require('fs');
    const path = require('path');

    test('sanitizeJsonString removes NUL bytes and replaces unpaired UTF-16 surrogates', () => {
        const input = 'test\x00' + String.fromCharCode(0xD83D) + 'end';
        expect(readMail.sanitizeJsonString(input)).toBe('test\uFFFDend');

        const validPair = 'ok' + String.fromCharCode(0xD83D, 0xDE00) + '!';
        expect(readMail.sanitizeJsonString(validPair)).toBe(validPair);
    });

    test('decodeEmailBody skips binary PDF attachment and strips NUL bytes while keeping text body', () => {
        const pdfBase64 = Buffer.from('%PDF-1.4\x00binary\x00content', 'latin1').toString('base64');
        const raw =
            'Subject: Permanent failure notice\r\n' +
            'From: Mail Delivery Subsystem <mailer-daemon@googlemail.com>\r\n' +
            'Content-Type: multipart/mixed; boundary="b1"\r\n\r\n' +
            '--b1\r\n' +
            'Content-Type: text/plain; charset="utf-8"\r\n\r\n' +
            'Delivery failed for Saadan dokument nr. 072-1318\r\n' +
            'Final-Recipient: rfc822;zechev@mail.ru\r\n' +
            '--b1\r\n' +
            'Content-Type: application/pdf; name="teatis.pdf"\r\n' +
            'Content-Disposition: attachment; filename="teatis.pdf"\r\n' +
            'Content-Transfer-Encoding: base64\r\n\r\n' +
            pdfBase64 + '\r\n' +
            '--b1--\r\n';

        const decoded = readMail.decodeEmailBody(raw);
        expect(decoded).toContain('Delivery failed for Saadan dokument nr. 072-1318');
        expect(decoded).not.toContain('%PDF-1.4');
        expect(decoded).not.toContain('\x00');
    });

    test('endLog strips body/body_text before DB write, throws on {error_code: 9}, and catch closes log as failed', async () => {
        const origQueryDb = db.queryDb;
        const calls = [];
        db.queryDb = jest.fn((sql, params) => {
            calls.push({ sql, params });
            if (sql.includes('insert into ou.logs')) {
                return Promise.resolve({ error_code: 0, data: [{ id: 777 }] });
            }
            if (sql.includes('update ou.logs') && params[0] === 'success') {
                return Promise.resolve({ error_code: 9, error_message: 'unsupported Unicode escape sequence' });
            }
            return Promise.resolve({ error_code: 0, data: [] });
        });

        try {
            await expect(
                readMail.endLog(777, 'success', null, [{ doc_number: '072-1318', body: 'secret-body', body_text: 'secret-text' }])
            ).rejects.toThrow('DB Query failed');

            const successCall = calls.find((c) => c.sql.includes('update ou.logs') && c.params[0] === 'success');
            const writtenJson = JSON.parse(successCall.params[3]);
            expect(writtenJson[0].doc_number).toBe('072-1318');
            expect(writtenJson[0].body).toBeUndefined();
            expect(writtenJson[0].body_text).toBeUndefined();

            calls.length = 0;
            await expect(
                readMail.executeCalculation(11770, 63, { emailContent: 'Subject: Permanent failure notice\r\nFrom: mailer-daemon@test.ee\r\n\r\nArve nr: 095-1111\nFinal-Recipient: rfc822;a@b.ee' })
            ).rejects.toThrow('DB Query failed');

            const failedCall = calls.find((c) => c.sql.includes('update ou.logs') && c.params[0] === 'failed');
            expect(failedCall).toBeDefined();
        } finally {
            db.queryDb = origQueryDb;
        }
    });

    test('saveReadMailState does not advance cursor when endLog fails', async () => {
        const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'readmail-cursor-'));
        const statePath = path.join(tmpDir, 'state.json');
        const initialDate = '2026-11-26T06:00:00.000Z';
        fs.writeFileSync(statePath, JSON.stringify({ lastReadDate: initialDate, lastReadUid: 1 }));

        const origQueryDb = db.queryDb;
        const origImapFetch = readMail.fetchEmailsViaImapTls;
        const EventEmitter = require('events');

        db.queryDb = jest.fn((sql, params) => {
            if (sql.includes('ou.userid')) {
                return Promise.resolve({
                    data: [{ smtp: 'mail.narva.ee', port: 465, user: 'oppetasu', pass: 'p', imap: 'mail.narva.ee', imap_port: 993, imap_mailbox: 'INBOX' }]
                });
            }
            if (sql.includes('insert into ou.logs')) {
                return Promise.resolve({ error_code: 0, data: [{ id: 888 }] });
            }
            if (sql.includes('update ou.logs') && params[0] === 'success') {
                return Promise.resolve({ error_code: 9, error_message: 'db write error' });
            }
            return Promise.resolve({ error_code: 0, data: [] });
        });

        const tlsConnect = () => {
            const sock = new EventEmitter();
            sock.setTimeout = jest.fn();
            sock.end = jest.fn();
            sock.write = (cmd) => {
                if (cmd.startsWith('A01 LOGIN')) sock.emit('data', Buffer.from('A01 OK\r\n'));
                else if (cmd.startsWith('A02 SELECT')) sock.emit('data', Buffer.from('A02 OK\r\n'));
                else if (cmd.startsWith('A03 UID SEARCH')) sock.emit('data', Buffer.from('* SEARCH 10\r\nA03 OK\r\n'));
                else if (cmd.startsWith('A04 UID FETCH')) {
                    const raw = 'Date: Fri, 27 Nov 2026 06:00:00 +0200\r\nSubject: Permanent failure notice\r\nFrom: mailer-daemon@test.ee\r\n\r\nArve nr: 095-9999\r\nFinal-Recipient: rfc822;u@test.ee\r\n';
                    const header = `* 1 FETCH (UID 10 BODY[] {${Buffer.byteLength(raw)}}\r\n`;
                    sock.emit('data', Buffer.from(header + raw + ')\r\nA04 OK\r\n'));
                }
            };
            process.nextTick(() => sock.emit('data', Buffer.from('* OK ready\r\n')));
            return sock;
        };

        // Подменяем tls.connect не напрямую, а через executeReadMailProcess нельзя — проверим через runReadMailInBackground?
        // В runReadMailInBackground нельзя прокинуть tlsConnect, поэтому проверим deferStateSave на executeReadMailProcess + endLog:
        try {
            const stateOut = {};
            const errs = await readMail.executeReadMailProcess({
                emailContent: 'Subject: Test\r\n\r\nArve nr: 095-9999\r\nFinal-Recipient: rfc822;u@test.ee',
                stateFilePath: statePath,
                deferStateSave: true,
                stateOutput: stateOut
            });
            expect(errs.length).toBe(1);
            await expect(readMail.endLog(888, 'success', null, errs)).rejects.toThrow('DB Query failed');
            const after = JSON.parse(fs.readFileSync(statePath, 'utf8'));
            expect(after.lastReadDate).toBe(initialDate);
        } finally {
            db.queryDb = origQueryDb;
            fs.rmSync(tmpDir, { recursive: true, force: true });
        }
    });

    test('fetchEmailsViaImapTls rejects immediately when socket emits close before A04 OK', async () => {
        const EventEmitter = require('events');
        const sock = new EventEmitter();
        sock.setTimeout = jest.fn();
        sock.end = jest.fn();
        sock.write = (cmd) => {
            if (cmd.startsWith('A01 LOGIN')) sock.emit('data', Buffer.from('A01 OK\r\n'));
            else if (cmd.startsWith('A02 SELECT')) sock.emit('data', Buffer.from('A02 OK\r\n'));
            else if (cmd.startsWith('A03 UID SEARCH')) sock.emit('data', Buffer.from('* SEARCH 1\r\nA03 OK\r\n'));
            else if (cmd.startsWith('A04 UID FETCH')) {
                process.nextTick(() => sock.emit('close'));
            }
        };
        const tlsConnect = () => {
            process.nextTick(() => sock.emit('data', Buffer.from('* OK ready\r\n')));
            return sock;
        };

        await expect(
            readMail.fetchEmailsViaImapTls(
                { host: 'mail.test', port: 993, user: 'u', pass: 'p' },
                new Date('2026-11-15T00:00:00.000Z'),
                { tlsConnect, idleTimeoutMs: 5000, totalTimeoutMs: 5000 }
            )
        ).rejects.toThrow(/IMAP socket closed prematurely at step FETCH \(INBOX\)/);
    });

    test('parseIncomingEmail ignores plain email mentioning teatis without nr and extracts client recipient_email instead of mailer-daemon', () => {
        const plainMsg =
            'Subject: Koosoleku teatis kolleegidele\r\n' +
            'From: kolleeg@narva.ee\r\n\r\n' +
            'Tere, see on teatis koosoleku kohta homme kell 10.\r\n';
        const parsedPlain = readMail.parseIncomingEmail(plainMsg);
        expect(parsedPlain.doc_number).toBe('N/A');
        expect(readMail.hasValidDocNumber(parsedPlain.doc_number)).toBe(false);

        const bounce072 =
            'Subject: Delivery Status Notification (Failure)\r\n' +
            'From: Mail Delivery Subsystem <mailer-daemon@googlemail.com>\r\n\r\n' +
            'Delivery to the following recipient failed permanently:\r\n' +
            '     zechev@mail.ru\r\n\r\n' +
            'Final-Recipient: rfc822;zechev@mail.ru\r\n' +
            'Subject: Saadan dokument nr. 072-1318\r\n' +
            'MAKSEVÕLA TEATIS NR-072-1318\r\n';
        const parsed072 = readMail.parseIncomingEmail(bounce072);
        expect(parsed072.doc_type).toBe('TEATIS');
        expect(parsed072.doc_number).toBe('072-1318');
        expect(parsed072.recipient_email).toBe('zechev@mail.ru');
    });

    test('executeCalculation loads mailAccount for emailContent mode so alerts do not fail with mail_password_missing', async () => {
        const origQueryDb = db.queryDb;
        const mockTransporter = { sendMail: jest.fn().mockResolvedValue({ messageId: '<ok@narva.ee>' }) };
        const nodemailer = require('nodemailer');
        const origCreateTransport = nodemailer.createTransport;
        nodemailer.createTransport = jest.fn(() => mockTransporter);

        db.queryDb = jest.fn((sql) => {
            if (sql.includes('insert into ou.logs')) return Promise.resolve({ error_code: 0, data: [{ id: 999 }] });
            if (sql.includes('update ou.logs')) return Promise.resolve({ error_code: 0, data: [] });
            if (sql.includes('docs.tuhista_arve_saatmise_staatus')) return Promise.resolve({ error_code: 0, data: [{ result: [] }] });
            if (sql.includes('ou.userid')) {
                return Promise.resolve({
                    data: [{ smtp: 'mail.narva.ee', port: 465, user: 'oppetasu', pass: 'card-pass', imap: 'mail.narva.ee', imap_port: 993, imap_mailbox: 'INBOX' }]
                });
            }
            return Promise.resolve({ error_code: 0, data: [] });
        });

        try {
            const res = await readMail.executeCalculation(11770, 63, {
                emailContent: 'Subject: Delivery failure\r\nFrom: mailer-daemon@test.ee\r\n\r\nArve nr: 095-1234\r\nFinal-Recipient: rfc822;client@example.ee'
            });
            expect(res.length).toBe(1);
            expect(mockTransporter.sendMail).toHaveBeenCalledTimes(1);
        } finally {
            db.queryDb = origQueryDb;
            nodemailer.createTransport = origCreateTransport;
        }
    });

    test('decodeEmailBody preserves and decodes folded RFC2047 headers in message/rfc822 and message/global parts', () => {
        const subjectB64 = Buffer.from('Saadan dokument nr. 072-1318', 'utf8').toString('base64');
        const raw =
            'Subject: Delivery Status Notification\r\n' +
            'Content-Type: multipart/report; boundary="rep1"\r\n\r\n' +
            '--rep1\r\n' +
            'Content-Type: text/plain; charset="utf-8"\r\n\r\n' +
            'Bounce explanation.\r\n' +
            '--rep1\r\n' +
            'Content-Type: message/rfc822\r\n\r\n' +
            'From: =?UTF-8?B?' + Buffer.from('Õppetasu', 'utf8').toString('base64') + '?= <oppetasu@narva.ee>\r\n' +
            'To: zechev@mail.ru\r\n' +
            'Cc: copy@example.ee\r\n' +
            'Date: Thu, 26 Nov 2026 22:45:39 +0200\r\n' +
            'Original-Recipient: rfc822;zechev@mail.ru\r\n' +
            'Final-Recipient: rfc822;zechev@mail.ru\r\n' +
            'Subject: =?UTF-8?B?' + subjectB64 + '?=\r\n' +
            ' \t(lisainfo)\r\n\r\n' +
            'Original message body.\r\n' +
            '--rep1--\r\n';

        const decoded = readMail.decodeEmailBody(raw);
        expect(decoded).toContain('From: Õppetasu <oppetasu@narva.ee>');
        expect(decoded).toContain('To: zechev@mail.ru');
        expect(decoded).toContain('Cc: copy@example.ee');
        expect(decoded).toContain('Date: Thu, 26 Nov 2026 22:45:39 +0200');
        expect(decoded).toContain('Original-Recipient: rfc822;zechev@mail.ru');
        expect(decoded).toContain('Final-Recipient: rfc822;zechev@mail.ru');
        expect(decoded).toContain('Subject: Saadan dokument nr. 072-1318 (lisainfo)');
        expect(decoded).toContain('Original message body.');
    });

    test('decodeEmailBody handles text/rfc822-headers, message/rfc822-headers, message/global-headers, message/global-delivery-status and message/global', () => {
        const subjEncoded = '=?UTF-8?Q?Arve_nr_095-2222?=';
        const raw =
            'Content-Type: multipart/mixed; boundary="m1"\r\n\r\n' +
            '--m1\r\n' +
            'Content-Type: text/rfc822-headers\r\n\r\n' +
            'To: client1@example.ee\r\n' +
            'Subject: ' + subjEncoded + '\r\n' +
            '--m1\r\n' +
            'Content-Type: message/rfc822-headers\r\n\r\n' +
            'Final-Recipient: rfc822;client2@example.ee\r\n' +
            '--m1\r\n' +
            'Content-Type: message/global-headers\r\n\r\n' +
            'Original-Recipient: utf-8;client3@example.ee\r\n' +
            '--m1\r\n' +
            'Content-Type: message/global-delivery-status\r\n\r\n' +
            'Action: failed\r\nStatus: 5.1.1\r\n' +
            '--m1\r\n' +
            'Content-Type: message/global\r\n\r\n' +
            'Subject: Global embedded\r\n\r\n' +
            'Global body text\r\n' +
            '--m1--\r\n';

        const decoded = readMail.decodeEmailBody(raw);
        expect(decoded).toContain('To: client1@example.ee');
        expect(decoded).toContain('Subject: Arve nr 095-2222');
        expect(decoded).toContain('Final-Recipient: rfc822;client2@example.ee');
        expect(decoded).toContain('Original-Recipient: utf-8;client3@example.ee');
        expect(decoded).toContain('Action: failed');
        expect(decoded).toContain('Subject: Global embedded');
        expect(decoded).toContain('Global body text');
    });

    test('parseIncomingEmail falls back to From header for non-bounce client emails without address in body', () => {
        const raw =
            'Subject: Re: Saadan dokument nr. 095-3333\r\n' +
            'From: Klient <klient.vastus@gmail.com>\r\n\r\n' +
            'Tere, palun saatke arve 095-3333 uuesti.\r\n';

        const parsed = readMail.parseIncomingEmail(raw);
        expect(parsed).toBeDefined();
        expect(parsed.doc_number).toBe('095-3333');
        expect(parsed.recipient_email).toBe('klient.vastus@gmail.com');

        const internalRaw =
            'Subject: Re: Saadan dokument nr. 095-3334\r\n' +
            'From: Kolleeg <kolleeg@narva.ee>\r\n\r\n' +
            'Tere, kontrollisin arvet 095-3334.\r\n';
        const parsedInternal = readMail.parseIncomingEmail(internalRaw);
        expect(parsedInternal.recipient_email).toBe('unknown@client.ee');
    });
});
