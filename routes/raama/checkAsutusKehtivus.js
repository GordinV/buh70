'use strict';
const service = require('./../../libs/inforegisterService');
const kehtivusService = require('./../../libs/asutusKehtivusService');
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');
const mailer = require('./sendFinBitReport');

const DRY_RUN_EMAILS = ['vladislav.gordin@gmail.com'];
const DEFAULT_EMAILS = [
    'vladislav.gordin@gmail.com',
    'jelena.tsekanina@narva.ee',
    'svetlana.tsaikina@narva.ee'
];
const MAX_CLOSE_LIMIT = 5000;
const EMAIL_PREVIEW_LIMIT = 200;

/**
 * Express handler POST /task/checkAsutusKehtivus/
 * Находит в libs.asutus карточки закрытых/отсутствующих в Äriregister организаций
 * и выставляет properties.kehtivus через libs.set_asutuse_kehtivus (dry_run=true по умолчанию).
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);
    const configRekvId = Number(params.config_rekv_id || params.configRekvId || service.CONFIG_REKV_ID);
    const rawHash = typeof params.hash === 'string' ? params.hash.trim() : '';
    const dryRun = service.parseDryRun(params.dry_run !== undefined ? params.dry_run : params.dryRun);
    const extraEmails = parseEmails(
        params.extra_emails !== undefined
            ? params.extra_emails
            : (params.extraEmails !== undefined
                ? params.extraEmails
                : (params.notify_emails !== undefined ? params.notify_emails : params.notifyEmails))
    );

    let maxClose = kehtivusService.DEFAULT_MAX_CLOSE;
    const rawMaxClose = params.max_close !== undefined ? params.max_close : params.maxClose;
    if (rawMaxClose !== undefined && rawMaxClose !== null && rawMaxClose !== '') {
        maxClose = Number(rawMaxClose);
        if (!isFinite(maxClose) || maxClose < 0 || maxClose > MAX_CLOSE_LIMIT || Math.floor(maxClose) !== maxClose) {
            return res.status(400).send({
                status: 400,
                result: 0,
                log_id: null,
                data: {reason: 'invalid_max_close'},
                error_message: 'max_close peab olema täisarv vahemikus 0..' + MAX_CLOSE_LIMIT
            });
        }
    }

    const auth = await service.resolveInforegisterToken(rawHash, 'sync', configRekvId);
    if (!auth.ok) {
        return res.status(auth.status).send({
            status: auth.status,
            result: 0,
            log_id: null,
            data: {reason: auth.reason},
            error_message: auth.error
        });
    }

    let lockHandle = null;
    try {
        lockHandle = await kehtivusService.tryAcquireLock();
    } catch (lockErr) {
        console.error('[checkAsutusKehtivus] Failed to acquire advisory lock:', lockErr.message);
        return res.status(500).send({
            status: 500,
            result: 0,
            log_id: null,
            data: null,
            error_message: 'Advisory lock error: ' + lockErr.message
        });
    }

    if (!lockHandle) {
        return res.status(409).send({
            status: 409,
            result: 0,
            log_id: null,
            data: {reason: 'already_running'},
            error_message: 'Asutuste kehtivuse kontroll juba töötab'
        });
    }

    let logId = null;

    try {
        const logResult = await service.createLog(auth.rekvId, auth.userId, kehtivusService.FLOW_NAME);
        if (logResult && logResult.data && logResult.data[0]) {
            logId = logResult.data[0].id;
        }
        if (!logId) {
            throw new Error('Лог-запись не создана (не удалось получить log_id)');
        }

        runInBackground(logId, lockHandle, {
            dryRun: dryRun,
            maxClose: maxClose,
            userId: auth.userId,
            extraEmails: extraEmails
        });

        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: kehtivusService.FLOW_NAME,
                status: 'STARTED',
                log_id: logId,
                dry_run: dryRun,
                result: {doc_id: logId, error_code: 0, error_message: null, tulemused: 'STARTED'}
            },
            error_message: null
        });
    } catch (error) {
        console.error('[checkAsutusKehtivus] Error starting task:', error.message);
        if (logId) {
            try {
                await service.endLog(logId, 'failed', error.message);
            } catch (logErr) {
                console.error('[checkAsutusKehtivus] Failed to update log on startup error:', logErr.message);
            }
        }
        await kehtivusService.releaseLock(lockHandle);
        return res.status(500).send({
            status: 500,
            result: 0,
            log_id: logId,
            data: null,
            error_message: 'Start checkAsutusKehtivus failed: ' + error.message
        });
    }
};

function parseEmails(value) {
    if (!value) return [];
    const arr = Array.isArray(value) ? value : String(value).split(/[;,]/);
    const seen = {};
    const out = [];
    for (let i = 0; i < arr.length; i++) {
        const s = String(arr[i] || '').trim();
        if (!s || s.indexOf('@') === -1) continue;
        const low = s.toLowerCase();
        if (!seen[low]) {
            seen[low] = true;
            out.push(s);
        }
    }
    return out;
}

function escapeHtml(val) {
    return String(val == null ? '' : val)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function formatReasonLabel(reason) {
    if (reason === 'deleted_from_registry') return 'Registrist kustutatud (deleted_at)';
    if (reason === 'not_in_registry') return 'Äriregistris puudub';
    return reason || '';
}

function csvCell(val) {
    const s = String(val == null ? '' : val);
    if (/[",\r\n;]/.test(s)) {
        return '"' + s.replace(/"/g, '""') + '"';
    }
    return s;
}

function buildCsvAttachment(items) {
    const header = ['regkood', 'nimetus', 'aadress', 'pohjus', 'old_kehtivus', 'kehtivus'].join(';');
    const rows = [header];
    for (let i = 0; i < items.length; i++) {
        const it = items[i] || {};
        rows.push([
            csvCell(it.regkood),
            csvCell(it.nimetus),
            csvCell(it.aadress),
            csvCell(formatReasonLabel(it.reason)),
            csvCell(it.old_kehtivus),
            csvCell(it.kehtivus)
        ].join(';'));
    }
    return {
        filename: 'asutuste_kehtivus.csv',
        content: '\uFEFF' + rows.join('\r\n'),
        contentType: 'text/csv; charset=utf-8'
    };
}

function formatKehtivusEmail(result) {
    const dryRun = result.dry_run !== false;
    const candidatesTotal = Number(result.candidates_total) || 0;
    const totalClosed = Number(result.totalClosed) || 0;
    const totalErrors = Number(result.totalErrors) || 0;
    const reason = result.reason || null;
    const todayStr = kehtivusService.toTallinnDateStr(new Date());
    const fileDate = result.registry_file_date || '—';

    let subject;
    let lead;
    let items;

    if (result.status === 'failed') {
        if (reason === 'too_many_candidates') {
            subject = `[${todayStr}] Asutuste kehtivus: liiga palju kandidaate (${candidatesTotal}) — peatatud`;
            lead = `Asutuste kehtivuse kontroll peatati enne sulgemist, kuna leiti ${candidatesTotal} kandidaati. Andmebaasis muudatusi ei tehtud.`;
            items = Array.isArray(result.would_close) && result.would_close.length
                ? result.would_close
                : (Array.isArray(result.closed) ? result.closed : []);
        } else {
            subject = `[${todayStr}] Asutuste kehtivus: ebaõnnestus (${reason || 'viga'})`;
            lead = `Asutuste kehtivuse kontroll ebaõnnestus: ${result.error_message || reason || 'tundmatu viga'}.`;
            items = Array.isArray(result.closed) ? result.closed : [];
        }
    } else if (dryRun) {
        subject = `[DRY RUN] [${todayStr}] Asutuste kehtivus: leitud ${candidatesTotal} kandidaati`;
        lead = `Proovikäivitus (DRY RUN): leitud ${candidatesTotal} kandidaati, mis suletakse reaalsel käivitusel (muudatusi andmebaasis ei tehtud).`;
        items = Array.isArray(result.would_close) ? result.would_close : [];
    } else {
        subject = `[${todayStr}] Asutuste kehtivus: suletud ${totalClosed} kaarti` + (totalErrors > 0 ? ` (vigu: ${totalErrors})` : '');
        lead = `Reaalne sulgemine: suletud ${totalClosed} kaarti.` + (totalErrors > 0 ? ` Vigu: ${totalErrors}.` : '');
        items = Array.isArray(result.closed) ? result.closed : [];
    }

    const preview = items.slice(0, EMAIL_PREVIEW_LIMIT);
    const errors = Array.isArray(result.errors) ? result.errors : [];
    const lines = [
        lead,
        `Kuupäev: ${todayStr} | Äriregistri faili kuupäev: ${fileDate}`,
        ''
    ];
    for (let i = 0; i < preview.length; i++) {
        const it = preview[i] || {};
        lines.push(
            `${i + 1}. ${it.regkood || ''} | ${it.nimetus || ''} | ${it.aadress || ''} | ` +
            `${formatReasonLabel(it.reason)} | vana: ${it.old_kehtivus || '—'} -> uus: ${it.kehtivus || ''}`
        );
    }
    if (items.length > EMAIL_PREVIEW_LIMIT) {
        lines.push(`... näidatud esimesed ${EMAIL_PREVIEW_LIMIT} / ${items.length} kirjest (täisnimekiri CSV-manuses).`);
    }
    if (errors.length > 0) {
        lines.push('', `Vead (${errors.length}):`);
        for (let i = 0; i < errors.length; i++) {
            const er = errors[i] || {};
            lines.push(`- ${er.regkood || ''} (id ${er.asutus_id || ''}): ${er.error || ''}`);
        }
    }

    let html = `<p><strong>${escapeHtml(lead)}</strong></p>`;
    html += `<p style="font-size:13px;color:#555;">Kuupäev: ${escapeHtml(todayStr)} | Äriregistri faili kuupäev: ${escapeHtml(fileDate)}</p>`;
    if (preview.length > 0) {
        html += '<table border="1" cellpadding="4" cellspacing="0" style="border-collapse:collapse;font-size:13px;">' +
            '<thead><tr><th>Reg.kood</th><th>Nimetus</th><th>Aadress</th><th>Põhjus</th><th>Vana kehtivus</th><th>Uus kehtivus</th></tr></thead><tbody>';
        for (let i = 0; i < preview.length; i++) {
            const it = preview[i] || {};
            html += `<tr><td>${escapeHtml(it.regkood)}</td><td>${escapeHtml(it.nimetus)}</td>` +
                `<td>${escapeHtml(it.aadress || '')}</td><td>${escapeHtml(formatReasonLabel(it.reason))}</td>` +
                `<td>${escapeHtml(it.old_kehtivus || '—')}</td><td>${escapeHtml(it.kehtivus)}</td></tr>`;
        }
        html += '</tbody></table>';
        if (items.length > EMAIL_PREVIEW_LIMIT) {
            html += `<p>... näidatud esimesed ${EMAIL_PREVIEW_LIMIT} / ${items.length} kirjest (täisnimekiri on lisatud CSV-failina).</p>`;
        }
    }
    if (errors.length > 0) {
        html += `<p style="color:#c62828;font-weight:bold;">Vead (${errors.length}):</p><ul>`;
        for (let i = 0; i < errors.length; i++) {
            const er = errors[i] || {};
            html += `<li>${escapeHtml(er.regkood)} (id ${escapeHtml(er.asutus_id)}): ${escapeHtml(er.error)}</li>`;
        }
        html += '</ul>';
    }

    const attachments = items.length > EMAIL_PREVIEW_LIMIT ? [buildCsvAttachment(items)] : [];
    return {subject: subject, text: lines.join('\n'), html: html, attachments: attachments};
}

async function notifyKehtivusResult(result, userId, extraEmails, transporter, logId) {
    if (!result) {
        return null;
    }
    if (result.status === 'skipped' || result.reason === 'registry_stale') {
        return {sent: false, skipped: 'registry_stale', recipients: [], sent_at: null, message_id: null, error: null};
    }
    const dryRun = result.dry_run !== false;
    const candidatesTotal = Number(result.candidates_total) || 0;
    const totalClosed = Number(result.totalClosed) || 0;
    const totalErrors = Number(result.totalErrors) || 0;

    if ((dryRun && candidatesTotal === 0) || (!dryRun && result.status !== 'failed' && totalClosed === 0 && totalErrors === 0)) {
        return {sent: false, skipped: 'nothing_to_report', recipients: [], sent_at: null, message_id: null, error: null};
    }

    const defaultList = dryRun ? DRY_RUN_EMAILS : DEFAULT_EMAILS;
    const recipients = extraEmails && extraEmails.length ? extraEmails : defaultList;
    const mailInfo = {
        sent: false,
        skipped: null,
        recipients: recipients,
        sent_at: null,
        message_id: null,
        error: null
    };

    if (recipients.length === 0) {
        mailInfo.skipped = 'no_recipients';
        return mailInfo;
    }

    try {
        if (logId) {
            const prev = await db.queryDb(
                "select propertis -> 'mail' as mail from ou.logs where id = $1",
                [logId], null, null, null, null, config
            );
            const prevRow = prev && Array.isArray(prev.data) && prev.data[0] ? prev.data[0] : null;
            if (prevRow && prevRow.mail && prevRow.mail.sent) {
                mailInfo.skipped = 'duplicate';
                return mailInfo;
            }
        }

        const msg = formatKehtivusEmail(result);
        const smtpConfig = await mailer.getSmtpConfig(userId);
        const info = await mailer.sendHtmlEmail(
            recipients,
            msg.subject,
            msg.text,
            msg.html,
            smtpConfig,
            transporter,
            msg.attachments
        );
        mailInfo.sent = true;
        mailInfo.sent_at = new Date().toISOString();
        mailInfo.message_id = info && info.messageId ? info.messageId : null;

        if (logId) {
            await db.queryDb(
                "update ou.logs set propertis = coalesce(propertis, '{}'::jsonb) || jsonb_build_object('mail', $1::jsonb) where id = $2",
                [JSON.stringify(mailInfo), logId], null, null, null, null, config
            );
        }
    } catch (err) {
        console.error('[checkAsutusKehtivus] Email notification failed:', err.message);
        mailInfo.error = err.message;
    }
    return mailInfo;
}

async function runInBackground(logId, lockHandle, options) {
    try {
        const result = await kehtivusService.runKehtivusCheck({
            dryRun: options.dryRun,
            maxClose: options.maxClose,
            userId: options.userId
        });
        const mailInfo = await notifyKehtivusResult(result, options.userId, options.extraEmails, null, logId);
        if (mailInfo) {
            result.mail = mailInfo;
        }
        if (result.status === 'failed') {
            await service.endLog(logId, 'failed', result.error_message || 'Failed', result);
        } else {
            await service.endLog(logId, 'success', null, result);
        }
    } catch (error) {
        console.error('[checkAsutusKehtivus] Background task failed. log_id:', logId, error.message);
        try {
            await service.endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error('[checkAsutusKehtivus] Failed to update error log for log_id:', logId, logErr.message);
        }
    } finally {
        await kehtivusService.releaseLock(lockHandle);
    }
}

exports.DRY_RUN_EMAILS = DRY_RUN_EMAILS;
exports.DEFAULT_EMAILS = DEFAULT_EMAILS;
exports.MAX_CLOSE_LIMIT = MAX_CLOSE_LIMIT;
exports.parseEmails = parseEmails;
exports.formatKehtivusEmail = formatKehtivusEmail;
exports.notifyKehtivusResult = notifyKehtivusResult;
exports.runInBackground = runInBackground;
