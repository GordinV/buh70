import * as fs from 'fs';
import * as path from 'path';
import {
  cleanEmailText,
  categorizeMailError,
  createLog,
  decodeEmailBody,
  decodeMimeWords,
  endLog,
  filterNewEmails,
  getDefaultMailAccess,
  loadReadMailState,
  parseDeliveryFailureText,
  parseDeliveryFailureWithAi,
  parseIncomingEmail,
  saveReadMailState,
  sendOtherErrorsAlertEmail,
  ALERT_EMAILS,
  tuhistaArveSaatmiseStaatus,
} from './tools';
import { runReadMailSubagent, manifest } from './agent';
import { RawIncomingEmail, ReadMailState, TASK_FLOW_READ_MAIL } from './schemas';
import { ApiClient } from '../shared/api_client';

const SAMPLE_BOUNCE_EMAIL = `From: Õppetasu [mailto:kallekaleva@kallekaleva.planet.ee]
Sent: Monday, October 12, 2026 2:18 PM
To: Andrei Vargunin <andrei.vargunin@narva.ee>
Subject: Fwd: Fwd: Permanent failure notice
-------- Edastatud kiri --------
Teema:
Fwd: Permanent failure notice
Kuupäev:
Mon, 12 Oct 2026 08:30:31 +0300
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Vastamise aadress:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
Organisatsioon:
Narva Linnavalitsuse Kultuuriosakonna raamatupidamisteenistus
Saaja:
Karina Portnova [<karina.portnova@narvakultuur.ee>](mailto:karina.portnova@narvakultuur.ee)
Teema:
Saadan dokument nr. 101-10772, 1010177139
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Kuupäev:
08.10.2026, 17:30
Saaja:
[jekaterinabazutova@gmail.ru](mailto:jekaterinabazutova@gmail.ru)
-------- Edastatud kiri --------
Teema:
Permanent failure notice
Kuupäev:
Sat, 10 Oct 2026 21:49:14 +0300
Saatja:
[MAILER-DAEMON@narva.ee](mailto:MAILER-DAEMON@narva.ee)
Saaja:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
I am deeply sorry, but I was not able to deliver your mail to the following addresses:
[jekaterinabazutova@gmail.ru](mailto:jekaterinabazutova@gmail.ru) : Domain lookup error
This is a permanent delivery failure. The delivery has been tried 20 times and will not be rescheduled again.`;

const SAMPLE_BOUNCE_EMAIL_OVERQUOTA = `From: Õppetasu [mailto:kallekaleva@kallekaleva.planet.ee]
Sent: Monday, October 12, 2026 2:18 PM
To: Andrei Vargunin <andrei.vargunin@narva.ee>
Subject: Fwd: Fwd: Permanent failure notice
-------- Edastatud kiri --------
Teema:
Fwd: Permanent failure notice
Kuupäev:
Mon, 12 Oct 2026 08:29:50 +0300
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Vastamise aadress:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
Organisatsioon:
Narva Linnavalitsuse Kultuuriosakonna raamatupidamisteenistus
Saaja:
Jelena Verestsagina [<jelena.verestsagina@narva.ee>](mailto:jelena.verestsagina@narva.ee)
Teema:
Saadan dokument nr. 100-11324, 1000164479
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Kuupäev:
08.10.2026, 14:00
Saaja:
[gkucheruk@gmail.com](mailto:gkucheruk@gmail.com)
-------- Edastatud kiri --------
Teema:
Permanent failure notice
Kuupäev:
Sat, 10 Oct 2026 18:19:19 +0300
Saatja:
[MAILER-DAEMON@narva.ee](mailto:MAILER-DAEMON@narva.ee)
Saaja:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
I am deeply sorry, but I was not able to deliver your mail to the following addresses:
[gkucheruk@gmail.com](mailto:gkucheruk@gmail.com) : 4.2.2 The recipient's inbox is out of storage space. Please direct the 4.2.2 recipient to 4.2.2 https://support.google.com/mail/?p=OverQuotaTemp 2adb3069b0e04-5bcddec2f0bsi4074070e87.95 - gsmtp
This is a permanent delivery failure. The delivery has been tried 20 times and will not be rescheduled again.`;

const SAMPLE_BOUNCE_EMAIL_NOSUCHUSER = `From: Õppetasu [mailto:kallekaleva@kallekaleva.planet.ee]
Sent: Monday, October 12, 2026 2:19 PM
To: Andrei Vargunin <andrei.vargunin@narva.ee>
Subject: Fwd: Fwd: Permanent failure notice
-------- Edastatud kiri --------
Teema:
Fwd: Permanent failure notice
Kuupäev:
Thu, 8 Oct 2026 08:15:56 +0300
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Vastamise aadress:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
Organisatsioon:
Narva Linnavalitsuse Kultuuriosakonna raamatupidamisteenistus
Saaja:
Maksim Grigorjev [<maksim.grigorjev@narva.ee>](mailto:maksim.grigorjev@narva.ee)
Teema:
Saadan dokument nr. 098-10566, 0980169799
Saatja:
Õppetasu [<oppetasu@narva.ee>](mailto:oppetasu@narva.ee)
Kuupäev:
08.10.2026, 08:00
Saaja:
[tleera651@gmail.com](mailto:tleera651@gmail.com)
-------- Edastatud kiri --------
Teema:
Permanent failure notice
Kuupäev:
Thu, 8 Oct 2026 08:01:01 +0300
Saatja:
[MAILER-DAEMON@narva.ee](mailto:MAILER-DAEMON@narva.ee)
Saaja:
[oppetasu@narva.ee](mailto:oppetasu@narva.ee)
I am deeply sorry, but I was not able to deliver your mail to the following addresses:
[tleera651@gmail.com](mailto:tleera651@gmail.com) : 5.1.1 The email account that you tried to reach does not exist. Please try 5.1.1 double-checking the recipient's email address for typos or 5.1.1 unnecessary spaces. For more information, go to 5.1.1 https://support.google.com/mail/?p=NoSuchUser 2adb3069b0e04-5bcd30a8a52si1587306e87.186 - gsmtp
This is a permanent delivery failure. The delivery has been tried 0 times and will not be rescheduled again.`;

describe('Субагент read_mail (Анализ входящей почты и ошибок счетов)', () => {
  const testStateFile = path.resolve(__dirname, 'test_read_mail_state.json');

  afterEach(() => {
    if (fs.existsSync(testStateFile)) {
      try {
        fs.unlinkSync(testStateFile);
      } catch {
        // ignore
      }
    }
  });

  describe('getDefaultMailAccess (Параметры по аналогии с automailer.js)', () => {
    it('должен содержать настройки доступа, аналогичные automailer.js', () => {
      const access = getDefaultMailAccess();

      expect(access.user).toBe('oppetasu');
      expect(access.userName).toBe('Õppetasu');
      expect(access.userMail).toBe('oppetasu@narva.ee');
      expect(access.userId).toBe(11558);
      expect(access.port).toBe(993);
      expect(access.secure).toBe(true);
      // Проверяем tls.rejectUnauthorized: false из automailer.js
      expect(access.rejectUnauthorized).toBe(false);
    });
  });

  describe('categorizeMailError (Классификация ошибок по 4 регламентным статусам)', () => {
    it('должен возвращать "Domeeni viga" для сбоев поиска домена и DNS', () => {
      expect(categorizeMailError('', 'Domain lookup error')).toBe('Domeeni viga');
      expect(categorizeMailError('Host or domain name not found')).toBe('Domeeni viga');
      expect(categorizeMailError('DNS query failed for example.com')).toBe('Domeeni viga');
      expect(categorizeMailError('No MX record found')).toBe('Domeeni viga');
    });

    it('должен возвращать "Aadressi viga" для неизвестного пользователя или неверного адреса', () => {
      expect(categorizeMailError('', '550 5.1.1 User unknown')).toBe('Aadressi viga');
      expect(categorizeMailError('Recipient address rejected: Access denied')).toBe('Aadressi viga');
      expect(categorizeMailError('Mailbox unavailable / disabled')).toBe('Aadressi viga');
      expect(categorizeMailError('Account does not exist')).toBe('Aadressi viga');
    });

    it('должен возвращать "Postkast täis" при переполнении почтового ящика или квоты', () => {
      expect(categorizeMailError('', 'Quota exceeded')).toBe('Postkast täis');
      expect(categorizeMailError('Mailbox is full')).toBe('Postkast täis');
      expect(categorizeMailError('552 5.2.2 Over quota')).toBe('Postkast täis');
      expect(categorizeMailError('Postkast on täis')).toBe('Postkast täis');
    });

    it('должен возвращать "Muud vead" для всех прочих сбоев', () => {
      expect(categorizeMailError('', 'Connection refused')).toBe('Muud vead');
      expect(categorizeMailError('554 5.7.1 Service unavailable')).toBe('Muud vead');
      expect(categorizeMailError('Connection timed out')).toBe('Muud vead');
    });
  });

  describe('parseDeliveryFailureText (Парсер ошибок)', () => {
    it('должен извлечь объект с регламентными полями из примера пользователя', () => {
      const result = parseDeliveryFailureText(SAMPLE_BOUNCE_EMAIL);

      expect(result).not.toBeNull();
      expect(result).toEqual(
        expect.objectContaining({
          status: 'Domeeni viga',
          reason: 'Domain lookup error',
          doc_number: '101-10772',
          invoice_number: '101-10772',
          recipient_email: 'jekaterinabazutova@gmail.ru',
          reference_number: '1010177139',
        })
      );
    });

    it('должен распознавать "User unknown" со статусом "Aadressi viga"', () => {
      const email = `
From: MAILER-DAEMON@mail.narva.ee
Subject: Undelivered Mail Returned to Sender
To: oppetasu@narva.ee

<ivan.ivanov@mail.ee>: 550 5.1.1 User unknown; rejecting
Original message subject: Saadan dokument nr. 202-54321
`;
      const result = parseDeliveryFailureText(email);

      expect(result).not.toBeNull();
      expect(result!.status).toBe('Aadressi viga');
      expect(result!.reason).toContain('User unknown');
      expect(result!.doc_number).toBe('202-54321');
      expect(result!.recipient_email).toBe('ivan.ivanov@mail.ee');
    });

    it('должен извлечь ошибку "Postkast täis" из примера пользователя (100-11324, gkucheruk@gmail.com)', () => {
      const result = parseDeliveryFailureText(SAMPLE_BOUNCE_EMAIL_OVERQUOTA);

      expect(result).not.toBeNull();
      expect(result).toEqual(
        expect.objectContaining({
          status: 'Postkast täis',
          reason: expect.stringContaining("inbox is out of storage space"),
          doc_number: '100-11324',
          invoice_number: '100-11324',
          recipient_email: 'gkucheruk@gmail.com',
          reference_number: '1000164479',
        })
      );
    });

    it('должен извлечь ошибку "Aadressi viga" из примера пользователя (098-10566, tleera651@gmail.com)', () => {
      const result = parseDeliveryFailureText(SAMPLE_BOUNCE_EMAIL_NOSUCHUSER);

      expect(result).not.toBeNull();
      expect(result).toEqual(
        expect.objectContaining({
          status: 'Aadressi viga',
          reason: expect.stringContaining('5.1.1 The email account that you tried to reach does not exist'),
          doc_number: '098-10566',
          invoice_number: '098-10566',
          recipient_email: 'tleera651@gmail.com',
          reference_number: '0980169799',
        })
      );
    });
  });

  describe('filterNewEmails (Фильтрация с 01.10.2026 и инкрементальность)', () => {
    it('должен отсекать письма старше 01.10.2026', () => {
      const state: ReadMailState = {
        sinceDate: '2026-10-01T00:00:00.000Z',
        lastReadDate: null,
        totalProcessedCount: 0,
      };

      const testEmails: RawIncomingEmail[] = [
        {
          uid: 1,
          date: new Date('2026-09-28T10:00:00.000Z'), // до 01.10.2026 -> пропускаем
          text: 'Old email September',
        },
        {
          uid: 2,
          date: new Date('2026-10-02T12:00:00.000Z'), // после 01.10.2026 -> берем
          text: 'Email October 2',
        },
      ];

      const filtered = filterNewEmails(testEmails, state);
      expect(filtered).toHaveLength(1);
      expect(filtered[0].uid).toBe(2);
    });

    it('должен читать только "новые" письма, новее lastReadDate', () => {
      const state: ReadMailState = {
        sinceDate: '2026-10-01T00:00:00.000Z',
        lastReadDate: '2026-10-05T15:00:00.000Z',
        lastReadUid: 10,
        totalProcessedCount: 5,
      };

      const testEmails: RawIncomingEmail[] = [
        {
          uid: 9,
          date: new Date('2026-10-03T10:00:00.000Z'), // старое -> пропускаем
          text: 'Already processed 1',
        },
        {
          uid: 10,
          date: new Date('2026-10-05T15:00:00.000Z'), // совпадает с lastReadDate и uid -> пропускаем
          text: 'Already processed 2',
        },
        {
          uid: 11,
          date: new Date('2026-10-10T12:00:00.000Z'), // новое -> берем
          text: 'New email October 10',
        },
      ];

      const filtered = filterNewEmails(testEmails, state);
      expect(filtered).toHaveLength(1);
      expect(filtered[0].uid).toBe(11);
    });
  });

  describe('runReadMailSubagent (Инкрементальный запуск и формат результата)', () => {
    it('1-й вызов: читает письма с 01.10.2026, возвращает массив объектов и сохраняет state', async () => {
      const emailOld = {
        uid: 1,
        date: new Date('2026-09-25T10:00:00.000Z'), // до 01.10.2026
        text: 'Old message',
      };
      const emailBounce1 = {
        uid: 2,
        date: new Date('2026-10-05T11:00:00.000Z'),
        text: `Teema: Saadan dokument nr. 201-1122
Saaja: user1@example.ee
MAILER-DAEMON: 550 User unknown`,
      };
      const emailBounce2 = {
        uid: 3,
        date: new Date('2026-10-12T14:18:00.000Z'),
        text: SAMPLE_BOUNCE_EMAIL,
      };

      // 1-й запуск
      const result1 = await runReadMailSubagent({
        stateFilePath: testStateFile,
        rawEmails: [emailOld, emailBounce1, emailBounce2],
      });

      // Итог работы агента - массив из объектов вида {...}
      expect(Array.isArray(result1)).toBe(true);
      expect(result1).toHaveLength(2);

      // Проверяем формат первого объекта
      expect(result1[0]).toEqual(
        expect.objectContaining({
          status: 'Aadressi viga',
          doc_number: '201-1122',
          invoice_number: '201-1122',
          recipient_email: 'user1@example.ee',
        })
      );

      // Проверяем формат второго объекта (из примера пользователя)
      expect(result1[1]).toEqual(
        expect.objectContaining({
          status: 'Domeeni viga',
          reason: 'Domain lookup error',
          doc_number: '101-10772',
          invoice_number: '101-10772',
          recipient_email: 'jekaterinabazutova@gmail.ru',
          reference_number: '1010177139',
        })
      );

      // Проверяем, что state зафиксирован на дату последнего письма (12.10.2026)
      const savedState = loadReadMailState(testStateFile);
      expect(savedState.lastReadDate).toBe(new Date('2026-10-12T14:18:00.000Z').toISOString());
      expect(savedState.lastReadUid).toBe(3);
      expect(savedState.totalProcessedCount).toBe(2);

      // 2-й запуск: те же письма + одно новое
      const emailBounce3 = {
        uid: 4,
        date: new Date('2026-10-14T10:00:00.000Z'), // новее 12.10.2026
        text: `Teema: Saadan dokument nr. 301-9999
Saaja: quota.exceeded@example.ee
Delivery Status: Quota exceeded`,
      };

      const result2 = await runReadMailSubagent({
        stateFilePath: testStateFile,
        rawEmails: [emailOld, emailBounce1, emailBounce2, emailBounce3],
      });

      // Должно прочитаться ТОЛЬКО новое письмо
      expect(result2).toHaveLength(1);
      expect(result2[0]).toEqual(
        expect.objectContaining({
          status: 'Postkast täis',
          doc_number: '301-9999',
          invoice_number: '301-9999',
          recipient_email: 'quota.exceeded@example.ee',
        })
      );

      // 3-й запуск: нет новых писем
      const result3 = await runReadMailSubagent({
        stateFilePath: testStateFile,
        rawEmails: [emailOld, emailBounce1, emailBounce2, emailBounce3],
      });

      expect(result3).toHaveLength(0);
      expect(result3).toEqual([]);
    });

    it('должен использовать переданный mock mailFetcher при чтении из сервера', async () => {
      const mockFetcher = jest.fn().mockResolvedValue([
        {
          uid: 100,
          date: new Date('2026-10-10T10:00:00.000Z'),
          text: SAMPLE_BOUNCE_EMAIL,
        },
      ]);

      const result = await runReadMailSubagent(
        { stateFilePath: testStateFile },
        { mailFetcher: mockFetcher }
      );

      expect(mockFetcher).toHaveBeenCalled();
      expect(result).toHaveLength(1);
      expect(result[0].status).toBe('Domeeni viga');
      expect(result[0].doc_number).toBe('101-10772');
    });
  });

  describe('manifest.dispatch', () => {
    it('должен возвращать число найденных ошибок при вызове из оркестратора', async () => {
      const res = await manifest.dispatch({
        key: 'read_mail',
        userId: 2477,
        rekvId: 63,
        kond: 1,
        params: {
          emailContent: SAMPLE_BOUNCE_EMAIL,
          stateFilePath: testStateFile,
        },
        apiClient: new ApiClient(),
      });

      expect(typeof res).toBe('number');
      expect(Number(res)).toBeGreaterThan(0);
    });
  });

  describe('Логгирование работы агента (createLog / endLog по аналогии с getEarvedFromFinBit.js)', () => {
    it('должен вызывать createLog, endLog и docs.tuhista_arve_saatmise_staatus при выявлении ошибок', async () => {
      const mockCreateLog = jest.fn().mockResolvedValue({
        error_code: 0,
        result: 1,
        data: [{ id: 98765 }],
      });
      const mockEndLog = jest.fn().mockResolvedValue(undefined);
      const mockTuhista = jest.fn().mockResolvedValue({ error_code: 0, result: 1, data: [] });

      const result = await runReadMailSubagent(
        {
          userId: 2477,
          rekvId: 63,
          emailContent: SAMPLE_BOUNCE_EMAIL,
          stateFilePath: testStateFile,
        },
        {
          createLogFn: mockCreateLog,
          endLogFn: mockEndLog,
          tuhistaStaatusFn: mockTuhista,
        }
      );

      // Проверяем вызов createLog перед началом работы
      expect(mockCreateLog).toHaveBeenCalledTimes(1);
      expect(mockCreateLog).toHaveBeenCalledWith(63, 2477, TASK_FLOW_READ_MAIL);

      // Проверяем вызов endLog по завершению работы
      expect(mockEndLog).toHaveBeenCalledTimes(1);
      expect(mockEndLog).toHaveBeenCalledWith(
        98765,
        'success',
        null,
        expect.arrayContaining([
          expect.objectContaining({
            status: 'Domeeni viga',
            doc_number: '101-10772',
          }),
        ])
      );

      // Проверяем вызов процедуры аннулирования статуса отправки счетов
      expect(mockTuhista).toHaveBeenCalledTimes(1);
      expect(mockTuhista).toHaveBeenCalledWith(98765);

      expect(result).toHaveLength(1);
    });

    it('НЕ должен вызывать docs.tuhista_arve_saatmise_staatus и должен игнорировать письма без номера счета', async () => {
      const mockCreateLog = jest.fn().mockResolvedValue({
        error_code: 0,
        result: 1,
        data: [{ id: 98766 }],
      });
      const mockEndLog = jest.fn().mockResolvedValue(undefined);
      const mockTuhista = jest.fn().mockResolvedValue({ error_code: 0, result: 1, data: [] });
      const mockSendAlert = jest.fn().mockResolvedValue(null);

      const result = await runReadMailSubagent(
        {
          userId: 2477,
          rekvId: 63,
          emailContent: 'Normal incoming letter without bounce errors',
          stateFilePath: testStateFile,
        },
        {
          createLogFn: mockCreateLog,
          endLogFn: mockEndLog,
          tuhistaStaatusFn: mockTuhista,
          sendAlertFn: mockSendAlert as any,
        }
      );

      expect(mockCreateLog).toHaveBeenCalled();
      // Письма без номера счета игнорируются
      expect(result).toHaveLength(0);
      expect(mockEndLog).toHaveBeenCalledWith(98766, 'success', null, []);
      expect(mockTuhista).not.toHaveBeenCalled();
      expect(mockSendAlert).not.toHaveBeenCalled();
    });

    it('должен вызывать endLog со статусом failed и сообщением об ошибке в случае сбоя', async () => {
      const mockCreateLog = jest.fn().mockResolvedValue({
        error_code: 0,
        result: 1,
        data: [{ id: 112233 }],
      });
      const mockEndLog = jest.fn().mockResolvedValue(undefined);
      const failingFetcher = jest.fn().mockRejectedValue(new Error('IMAP connection timed out'));

      await expect(
        runReadMailSubagent(
          {
            userId: 2477,
            rekvId: 63,
            stateFilePath: testStateFile,
          },
          {
            createLogFn: mockCreateLog,
            endLogFn: mockEndLog,
            mailFetcher: failingFetcher,
          }
        )
      ).rejects.toThrow('IMAP connection timed out');

      expect(mockCreateLog).toHaveBeenCalledWith(63, 2477, TASK_FLOW_READ_MAIL);
      expect(mockEndLog).toHaveBeenCalledWith(
        112233,
        'failed',
        'IMAP connection timed out'
      );
    });
  });

  describe('Декодирование MIME и обработка всех типов писем (MIME / Base64 / Ответы клиентов)', () => {
    it('decodeMimeWords должен расшифровывать RFC 2047 encoded words (Base64 и Quoted-Printable)', () => {
      const subjectB64 = '=?UTF-8?B?UmU6IFNhYWRhbiBkb2t1bWVudCBuci4gMDczLTc3NDUsIDA3MzAxNzgyMDI=?=';
      expect(decodeMimeWords(subjectB64)).toBe('Re: Saadan dokument nr. 073-7745, 0730178202');

      const subjectQP = '=?UTF-8?Q?Tere_=C3=95ppetasu?=';
      expect(decodeMimeWords(subjectQP)).toBe('Tere Õppetasu');
    });

    it('decodeEmailBody должен распаковывать multipart письмо с base64 содержимым', () => {
      const rawMime = `Content-Type: multipart/alternative; boundary="BOUNDARY123"

--BOUNDARY123
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: base64

0JTQvtCx0YDRi9C5INC00LXQvdGMISDQnNC+0Lkg0L3QvtCy0YvQuSBlbWFpbDogbmV3QGV4YW1wbGUuY29t
--BOUNDARY123--`;

      const decoded = decodeEmailBody(rawMime);
      expect(decoded).toContain('Добрый день! Мой новый email: new@example.com');
    });

    it('parseIncomingEmail должен расшифровывать ответ клиента с запросом смены адреса (UID 3434)', () => {
      const clientEmailRaw = `From: emoldova@yandex.ru
To: oppetasu@narva.ee
Subject: =?UTF-8?B?UmU6IFNhYWRhbiBkb2t1bWVudCBuci4gMDczLTc3NDUsIDA3MzAxNzgyMDI=?=
Date: Thu, 15 Oct 2026 19:47:11 +0300
Content-Type: multipart/alternative; boundary="--ALT--123"

----ALT--123
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: base64

0JTQvtCx0YDRi9C5INC00LXQvdGMIQoK0KXQvtGC0LXQu9CwINCx0Ysg0YPQt9C90LDRgtGMLCDQ
utCw0Log0LzQvtC20L3QviDQuNC30LzQtdC90LjRgtGMINGB0LLQvtC5INGN0LzQsNC50Lsg0LTQ
u9GPINC/0L7Qu9GD0YfQtdC90LjRjyDQstGB0LXRhSDRgdGH0LXRgtC+0LIg0L7RgiDQstCw0YjQ
tdCz0L4g0YPRh9GA0LXQttC00LXQvdC40Y8/INCf0L7Qu9GD0YfQsNGOINGB0YfQtdGC0LAg0L7R
giDQstCw0YEg0LfQsCDQutGA0YPQttC60Lgg0L/QviDQuNC90YLQtdGA0LXRgdCw0Lwg0L3QsCDQ
tNC10YLQtdC5LgrQnNC+0Lkg0L3QvtCy0YvQuSDRjdC80LDQudC7OiBsb290dXNlZXZhQGdtYWls
LmNvbQoK0KEg0YPQstCw0LbQtdC90LjQtdC8LMKgINCV0LLQsCDQnNC+0LvQtNC+0LLQsAo=
----ALT--123--`;

      const parsed = parseIncomingEmail(clientEmailRaw);

      expect(parsed).toEqual(
        expect.objectContaining({
          status: 'Aadressi viga',
          doc_number: '073-7745',
          invoice_number: '073-7745',
          recipient_email: 'emoldova@yandex.ru',
          reference_number: '0730178202',
          source_subject: 'Re: Saadan dokument nr. 073-7745, 0730178202',
        })
      );
      expect(parsed.reason).toContain('lootuseeva@gmail.com');
    });

    it('runReadMailSubagent должен включать ВСЕ поступившие письма с номерами счетов в результат', async () => {
      const emailClientReply = {
        uid: 10,
        date: new Date('2026-10-15T16:47:11.000Z'),
        subject: 'Re: Saadan dokument nr. 073-7745, 0730178202',
        text: `From: emoldova@yandex.ru
Subject: Re: Saadan dokument nr. 073-7745, 0730178202
Добрый день! Мой новый эмайл: lootuseeva@gmail.com`,
      };

      const emailBounce = {
        uid: 11,
        date: new Date('2026-10-17T09:28:48.000Z'),
        subject: 'Fwd: Permanent failure notice',
        text: SAMPLE_BOUNCE_EMAIL,
      };

      const results = await runReadMailSubagent({
        stateFilePath: testStateFile,
        rawEmails: [emailClientReply, emailBounce],
      });

      // Оба письма должны быть расшифрованы и присутствовать в результате
      expect(results).toHaveLength(2);

      // Первое письмо (ответ клиента)
      expect(results[0]).toEqual(
        expect.objectContaining({
          status: 'Aadressi viga',
          doc_number: '073-7745',
          recipient_email: 'emoldova@yandex.ru',
        })
      );
      expect(results[0].reason).toContain('lootuseeva@gmail.com');

      // Второе письмо (bounce notice)
      expect(results[1]).toEqual(
        expect.objectContaining({
          status: 'Domeeni viga',
          doc_number: '101-10772',
          recipient_email: 'jekaterinabazutova@gmail.ru',
        })
      );
    });
  });

  describe('Оповещение об ошибках со статусом "Muud vead"', () => {
    it('ALERT_EMAILS должен содержать регламентные адреса vladislav.gordin@gmail.com и andrei.vargunin@narva.ee', () => {
      expect(ALERT_EMAILS).toContain('vladislav.gordin@gmail.com');
      expect(ALERT_EMAILS).toContain('andrei.vargunin@narva.ee');
    });

    it('sendOtherErrorsAlertEmail должен отправлять email с номером счета, адресом получателя и причиной ошибки', async () => {
      const mockSendMail = jest.fn().mockResolvedValue({
        messageId: '<test-alert-123@buh70.ee>',
      });

      const mockTransporter: any = {
        sendMail: mockSendMail,
      };

      const otherErrors = [
        {
          status: 'Muud vead' as const,
          reason: 'Unrecognized SMTP handshake failure 421',
          doc_number: '077-5544',
          invoice_number: '077-5544',
          recipient_email: 'client.unknown@hot.ee',
        },
      ];

      const res = await sendOtherErrorsAlertEmail(otherErrors, {
        transporter: mockTransporter,
        logId: 12345,
      });

      expect(mockSendMail).toHaveBeenCalledTimes(1);
      const callArgs = mockSendMail.mock.calls[0][0];

      // Проверка адресатов
      expect(callArgs.to).toContain('vladislav.gordin@gmail.com');
      expect(callArgs.to).toContain('andrei.vargunin@narva.ee');

      // Проверка содержания (номер счета, адрес, причина)
      expect(callArgs.text).toContain('077-5544');
      expect(callArgs.text).toContain('client.unknown@hot.ee');
      expect(callArgs.text).toContain('Unrecognized SMTP handshake failure 421');
      expect(callArgs.html).toContain('077-5544');
      expect(callArgs.html).toContain('client.unknown@hot.ee');
      expect(callArgs.html).toContain('Unrecognized SMTP handshake failure 421');
      expect(res.messageId).toBe('<test-alert-123@buh70.ee>');
    });

    it('sendOtherErrorsAlertEmail НЕ должен отправлять email, если у ошибок нет номера счета (N/A или UNKNOWN)', async () => {
      const mockSendMail = jest.fn();
      const mockTransporter: any = {
        sendMail: mockSendMail,
      };

      const res = await sendOtherErrorsAlertEmail(
        [
          {
            status: 'Muud vead',
            reason: 'Normal incoming letter without bounce errors',
            doc_number: 'N/A',
            invoice_number: 'N/A',
            recipient_email: 'unknown@client.ee',
          },
          {
            status: 'Muud vead',
            reason: 'Another general message',
            doc_number: 'UNKNOWN',
            invoice_number: 'UNKNOWN',
            recipient_email: 'info@client.ee',
          },
        ],
        { transporter: mockTransporter }
      );

      expect(res).toBeNull();
      expect(mockSendMail).not.toHaveBeenCalled();
    });

    it('runReadMailSubagent должен автоматически отправлять оповещение при обнаружении ошибки Muud vead с номером счета', async () => {
      const mockSendAlert = jest.fn().mockResolvedValue({ messageId: 'alert-ok' });

      const emailMuudVead = {
        uid: 99,
        date: new Date('2026-10-16T12:00:00.000Z'),
        text: `From: MAILER-DAEMON@narva.ee
Date: Fri, 16 Oct 2026 12:00:00 +0300
Subject: Delivery failure notice
To: oppetasu@narva.ee

Teema: Saadan dokument nr. 099-1234
Saaja: strange.error@mail.ru
Error: Unexpected custom MTA error 554 Transaction failed`,
      };

      const results = await runReadMailSubagent(
        {
          stateFilePath: testStateFile,
          rawEmails: [emailMuudVead],
        },
        {
          sendAlertFn: mockSendAlert as any,
        }
      );

      expect(results).toHaveLength(1);
      expect(results[0].status).toBe('Muud vead');
      expect(mockSendAlert).toHaveBeenCalledTimes(1);
      const passedErrors = mockSendAlert.mock.calls[0][0];
      expect(passedErrors[0].doc_number).toBe('099-1234');
      expect(passedErrors[0].recipient_email).toBe('strange.error@mail.ru');
    });
  });
});

