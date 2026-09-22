import { formatReportMarkdown, formatReportHtml, sendReportEmail } from './tools';
import { generateAndSendReportSubagent } from './agent';
import { Transporter } from 'nodemailer';

describe('Субагент reporter (Email)', () => {
  const sampleInput = {
    userId: 2477,
    rekvId: 63,
    executionDate: '2026-09-14',
    overallSuccess: true,
    steps: [
      {
        stepName: 'eelarve.sp_koosta_saldoandmik',
        status: 'SUCCESS' as const,
        logId: 10425,
        durationMs: 30000,
      },
      {
        stepName: 'eelarve.salvesta_lisa_1_5_kontrol',
        status: 'SKIPPED' as const,
      },
    ],
    notes: 'Kõik rutiinsed arvestused on edukalt lõpetatud.',
    recipientEmail: 'accountant@buh70.ee',
  };

  it('formatReportMarkdown должен формировать читаемый markdown на эстонском языке без ID пользователя и учреждения', () => {
    const md = formatReportMarkdown(sampleInput);

    expect(md).toContain('# buh70 AI-Orkestraatori rutiinsete arvestuste aruanne');
    expect(md).toContain('**Staatus:** ✅ ÕNNESTUS');
    expect(md).toContain('**Kuupäev:** 2026-09-14');
    expect(md).not.toContain('2477');
    expect(md).not.toContain('63');
    expect(md).not.toContain('Пользователя');
    expect(md).toContain('eelarve.sp_koosta_saldoandmik');
    expect(md).toContain('`ÕNNESTUS`');
    expect(md).toContain('`VAHELE JÄETUD`');
  });

  it('formatReportHtml должен генерировать валидную HTML разметку на эстонском языке без ID пользователя и учреждения', () => {
    const html = formatReportHtml(sampleInput);

    expect(html).toContain('buh70 rutiinsete arvestuste aruanne');
    expect(html).toContain('Üldine staatus');
    expect(html).toContain('Kuupäev');
    expect(html).not.toContain('2477');
    expect(html).not.toContain('63');
    expect(html).toContain('eelarve.sp_koosta_saldoandmik');
    expect(html).toContain('<table');
    expect(html).toContain('ÕNNESTUS');
  });

  it('sendReportEmail должен вызывать sendMail через transporter с эстонской темой письма', () => {
    const mockSendMail = jest.fn().mockResolvedValue({
      messageId: '<test-message-123@buh70.ee>',
    });

    const mockTransporter = {
      sendMail: mockSendMail,
    } as unknown as Transporter;

    process.env.SMTP_HOST = 'smtp.test.com';

    return generateAndSendReportSubagent(sampleInput, {
      transporter: mockTransporter,
    }).then((result) => {
      expect(mockSendMail).toHaveBeenCalledTimes(1);
      const callArgs = mockSendMail.mock.calls[0][0];
      expect(callArgs.to).toBe('accountant@buh70.ee');
      expect(callArgs.subject).toContain('[buh70] Rutiinne arvestus 2026-09-14: ÕNNESTUS');
      expect(result.sent).toBe(true);
      expect(result.deliveryChannel).toBe('email');
      expect(result.messageId).toBe('<test-message-123@buh70.ee>');
    });
  });

  it('sendReportEmail должен делать fallback на локальный вывод, если SMTP не задан', async () => {
    const originalHost = process.env.SMTP_HOST;
    delete process.env.SMTP_HOST;

    const result = await sendReportEmail(sampleInput);

    expect(result.sent).toBe(true);
    expect(result.deliveryChannel).toBe('local_fallback');

    if (originalHost) {
      process.env.SMTP_HOST = originalHost;
    }
  });

  it('formatReportMarkdown и formatReportHtml должны отображать ошибку и resultSummary при сбое sendFinBitReport', () => {
    const errorInput = {
      userId: 2477,
      rekvId: 63,
      executionDate: '2026-09-18',
      overallSuccess: false,
      steps: [
        {
          stepName: 'sendFinBitReport',
          status: 'FAILED' as const,
          logId: 10430,
          durationMs: 4000,
          error: 'vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25',
          resultSummary: 'Kokku: 1, õnnestus: 0, vigu: 1',
        },
      ],
      notes: 'Mõned rutiinsed arvestused lõppesid vigadega.',
    };

    const md = formatReportMarkdown(errorInput);
    expect(md).toContain('**Staatus:** ❌ VIGA');
    expect(md).toContain('`EBAÕNNESTUS`');
    expect(md).toContain('Tulemus:* Kokku: 1, õnnestus: 0, vigu: 1');
    expect(md).toContain('Viga:* vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25');

    const html = formatReportHtml(errorInput);
    expect(html).toContain('Ebaõnnestus');
    expect(html).toContain('Kokku: 1, õnnestus: 0, vigu: 1');
    expect(html).toContain('vladislav.gordin@gmail.com: connect ETIMEDOUT 213.184.47.202:25');
  });

  it('formatReportMarkdown и formatReportHtml должны очищать русские фразы (напр. Регламентная задача calc_arv_jaak) и переводить их в эстонский', () => {
    const russianInput = {
      userId: 2477,
      rekvId: 63,
      executionDate: '2026-09-22',
      overallSuccess: true,
      steps: [
        {
          stepName: 'docs.check_arv_jaak',
          status: 'SUCCESS' as const,
          logId: 8480461,
          durationMs: 889,
          resultSummary:
            'Регламентная задача calc_arv_jaak (docs.check_arv_jaak) выполнена успешно без ошибок за 1 попытку.',
        },
        {
          stepName: 'sendFinBitReport',
          status: 'SUCCESS' as const,
          logId: 8480465,
          durationMs: 1922,
          resultSummary:
            'Процесс отправки отчетов sendFinBitReport успешно завершен. Ошибок SMTP и недоставленных сообщений не зафиксировано.',
        },
      ],
      notes: 'Все регламентные расчеты завершены успешно.',
      recipientEmail: 'accountant@buh70.ee',
    };

    const md = formatReportMarkdown(russianInput);
    expect(md).not.toContain('Регламентная задача');
    expect(md).not.toContain('выполнена успешно');
    expect(md).not.toContain('Все регламентные расчеты');
    expect(md).toContain('Tulemus:* Edukalt täidetud');
    expect(md).toContain('Märkused:** Kõik rutiinsed arvestused on edukalt lõpetatud.');

    const html = formatReportHtml(russianInput);
    expect(html).not.toContain('Регламентная задача');
    expect(html).not.toContain('выполнена успешно');
    expect(html).toContain('Edukalt täidetud');
  });
});
