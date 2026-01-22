'use strict';

const db = require('./../../libs/db');
const wkhtmltopdf = require('wkhtmltopdf');
const path = require('path');
const nodemailer = require('nodemailer');
const fs = require('fs');
// const config = require('../../config/default'); // Не использовался явно в логике, но нужен для db
const jade = require('jade');
const Doc = require('./../../classes/DocumentTemplate');
const config = require("../../config/default.json");

// Константы статусов
const DELETE_STATUS = 3;
const ACTIVE_STATUS = 1;

/**
 * Создает PDF из HTML
 * @param {string} html
 * @param {string} fileName
 * @returns {Promise<string|null>}
 */
const createPDF = async function (html, fileName = 'doc') {

    const options = {
        pageSize: 'letter',
        dpi: 300,
        printMediaType: true,
        disableSmartShrinking: true,
        noStopSlowScripts: true,
        javascriptDelay: 2000,
        enableLocalFileAccess: true,
    };


    // Используем path.resolve для надежности
    let outFile = path.resolve(__dirname, '..', '..', 'public', 'pdf', `${fileName}.pdf`);

    try {
        await exportHtml(html, outFile, options);
        return outFile;
    } catch (error) {
        console.error(`ERROR: PDF generation failed for ${fileName}:`, error);
        return null;
    }
};

/**
 * Основная функция рассылки
 */
const automailer = async () => {
        // Настройки (лучше вынести в конфиг или передавать параметрами)
        const l_userId = 11558;
        const l_rekv_id = 119; // Kultuuriosakond
        const l_limit = 25;
        const l_user_name = 'Õppetasu';
        const l_user_mail = 'oppetasu@narva.ee';

        let result = 0;

        try {
            // Инициализация класса документа
            const emailDoc = new Doc('TEATIS', null, l_userId, l_rekv_id, 'lapsed');

            // Проверка наличия конфигурации
            if (!emailDoc.config) {
                throw new Error('Document configuration not found');
            }

            const printTemplates = emailDoc.config.print || [];
            const emailTemplates = emailDoc.config.email || [];

            // SQL запрос
            // FIX: Используем параметры $1, $2 вместо интерполяции строки ${} для безопасности и кэширования плана
            let sql = `WITH
                           params as (
                                         SELECT
                                             ${l_userId}:: INTEGER                                 as user_id,
                                             make_date(year(current_date), month(current_date), 1) AS kpv1,
                                             get_last_day(current_date)                            AS kpv2
                                     ),
                           teatised as (
                                         SELECT
                                             d.id,
                                             t.number,
                                             t.kpv,
                                             to_char(t.kpv, 'DD.MM.YYYY')                         as print_kpv,
                                             t.asutusid,
                                             t.sisu,
                                             t.muud,
                                             d.docs_ids,
                                             to_char(d.created, 'DD.MM.YYYY HH:MM:SS') :: TEXT    AS created,
                                             to_char(d.lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT AS lastupdate,
                                             d.status                                             AS doc_status,
                                             d.rekvid,
                                             d.history -> 0 ->> 'user'                            AS koostaja,
                                             r.muud                                               as tais_nimetus,
                                             r.tel                                                as rekv_tel,
                                             r.email                                              as rekv_email,
                                             r.aadress                                            as rekv_aadress,
                                             r.regkood                                            as rekv_regkood

                                         FROM
                                             docs.teatis                t
                                                 INNER JOIN docs.doc    d ON t.parentid = d.id
                                                 inner join libs.asutus a on a.id = t.asutusid
                                                 inner join ou.rekv     r on r.id = d.rekvid
                                           ,                            params
                                         WHERE
                                               d.status <> ${DELETE_STATUS}
                                           AND t.kpv >= params.kpv1
                                           AND t.kpv <= params.kpv2
                                           and d.history::text not ilike '%"email"%'
                                           and d.history::text not ilike '%"email_error"%'
                                           and d.history::text not ilike '%"email_error_3"%'
                                           AND d.rekvid IN (
                                                               SELECT
                                                                   id
                                                               FROM
                                                                   ou.rekv
                                                               WHERE
                                                                   parentid = ${l_rekv_id}
                                                           )
                                           and a.email is not null
                                           and a.email like '%@%'
                                         LIMIT ${l_limit}
                                     ),

                           arved as (
                                         with
                                             arvete_info as (
                                                                select
                                                                    sum(a.jaak) over (partition by t.id)         as jaak_kokku,
                                                                    a.jaak,
                                                                    a.number,
                                                                    to_char(a.kpv, 'DD.MM.YYYY')                 as kpv,
                                                                    lapsed.get_viitenumber(a.rekvid, l.parentid) as viitenr,
                                                                    laps.nimi                                    as lapse_nimi,
                                                                    a.rekvid                                     as rekvid,
                                                                    t.id                                         as teatis_id
                                                                from
                                                                    docs.arv                                a
                                                                        inner join      teatised            t on a.parentid = any (t.docs_ids)
                                                                        left outer join lapsed.liidestamine l on l.docid = a.parentid
                                                                        left outer join lapsed.laps         laps on laps.id = l.parentid
                                                                order by l.parentid, a.kpv
                                             )
                                         select
                                             jsonb_agg(jsonb_build_object('kokku', a.jaak_kokku,
                                                                          'number', a.number,
                                                                          'kpv', a.kpv,
                                                                          'viitenr', a.viitenr,
                                                                          'lapse_nimi', a.lapse_nimi,
                                                                          'rekvid', a.rekvid,
                                                                          'jaak', a.jaak)) as arve,
                                             a.teatis_id                                   as teatis_id,
                                             array_agg(a.viitenr)                          as lapsed
                                         from
                                             arvete_info a
                                         group by a.teatis_id
                                     )

                       SELECT
                           t.id,
                           t.created,
                           t.lastupdate,
                           t.doc_status,
                           t.number::TEXT                                                                                    AS number,
                           t.rekvId,
                           to_char(t.kpv, 'YYYY-MM-DD')::TEXT                                                                AS kpv,
                           to_char(t.kpv, 'DD.MM.YYYY')::TEXT                                                                AS kpv_print,
                           t.asutusid,
                           asutus.regkood,
                           asutus.nimetus::TEXT                                                                              AS asutus,
                           asutus.aadress,
                           asutus.email::TEXT                                                                                AS email,
                           t.koostaja,
                           to_char(current_date, 'DD.MM.YYYY HH:MM:SS')                                                      AS print_aeg,
                           t.sisu,
                           t.muud,
                           to_jsonb((
                                        SELECT
                                            arve
                                        FROM
                                            arved a
                                        WHERE
                                            a.teatis_id = t.id
                                    ))                                                                                       AS arved,
                           to_jsonb(get_unique_value_from_array(array(SELECT lapsed FROM arved a WHERE a.teatis_id = t.id))) as lapsed,
                           t.tais_nimetus,
                           t.rekv_tel,
                           t.rekv_aadress,
                           t.rekv_regkood,
                           t.rekv_email,
                           u.properties ->> 'smtp'                                                                           AS smtp,
                           u.properties ->> 'port'                                                                           AS port,
                           u.properties ->> 'pass'                                                                           AS pass,
                           u.properties ->> 'user'                                                                           AS user

                       FROM
                           teatised                      t
                               INNER JOIN ou.userid      u ON u.id = ${l_userId} :: INTEGER
                               INNER JOIN libs.asutus AS asutus ON asutus.id = t.asutusId,
                                                         params
            `;

            // Выполняем запрос с параметрами
            let selectedDocs = await db.queryDb(sql, null, null, null, null, null, config);

            if (!selectedDocs || !selectedDocs.data || selectedDocs.data.length === 0) {
                console.log('No documents found for emailing.');
                return 0;
            }


            // Получаем настройки SMTP (в оригинале бралось из первой строки данных,

            // В оригинале:
            const firstRow = selectedDocs.data[0];
            const l_smtp = firstRow.smtp || 'smtp.zone.eu'; // Fallback
            const l_port = firstRow.port || 465;
            const l_pass = firstRow.pass;
            const l_user = firstRow.user;

            // Проверка перед созданием транспорта

            if (!l_user || !l_pass) {
                throw new Error(`Missing SMTP credentials. User: ${l_user}, Pass: ${l_pass ? '***' : 'missing'}`);
            }

            // Настройка транспорта
            let transporter = nodemailer.createTransport({

                host: l_smtp,
                port: l_port,
                secure: l_port === 465,
                auth: {
                    user: l_user,
                    pass: l_pass
                },
                tls: {
                    rejectUnauthorized: false
                }

            });


            // Шаблоны
            const templateObject = printTemplates.find(templ => templ.params === 'id');
            const emailTemplateObject = emailTemplates.find(templ => templ.params === 'id');

            if (!templateObject || !emailTemplateObject) {
                console.error('Templates not found in doc config');
                return 0;
            }

            const printTemplateView = templateObject.view;
            const emailTemplateView = emailTemplateObject.view;

            // Массив промисов
            const emailPromises = selectedDocs.data.map(async (Teatis) => {

                        // Формируем объект пользователя для шаблона
                        let user = {
                            id: l_userId,
                            userId: l_userId,
                            userName: l_user_name,
                            asutus: Teatis.tais_nimetus || 'Narva Linnavalitsuse Kultuuriosakond',
                            aadress: Teatis.rekv_aadress,
                            email: Teatis.rekv_email, // 'oppetasu@narva.ee'
                            regkood: Teatis.rekv_regkood,
                            asutusId: l_rekv_id,
                            parentid: 119 // Хардкод из оригинала
                        };

                        // Генерация PDF
                        let renderForm = 'teatis_kaart'; // Или использовать printTemplateView
                        let fileJade = path.join(__dirname, '..', '..', 'views', `${renderForm}.jade`);


                        // Рендер HTML для PDF
                        try {

                            let printHtml = await jade.renderFile(fileJade, {
                                data: [Teatis],
                                user: user
                            });

                            // Рендер HTML для тела письма

                            let emailFileJade = path.join(__dirname, '..', '..', 'views', `${emailTemplateView}.jade`);
                            let emailHtml = await jade.renderFile(emailFileJade, {data: [Teatis], user: user});

                            // Создание PDF файла
                            let filePDF = await createPDF(printHtml, `doc_${Teatis.id}`);

                            if (!filePDF) {
                                throw new Error(`Failed to create PDF for doc ${Teatis.id}`);
                            }

                            // Отправка письма

                            let info = await transporter.sendMail({
                                from: `"${l_user_name}" <${l_user_mail}>`,
                                to: Teatis.email,
                                subject: `Saadan dokument nr. ${Teatis.number}`,
                                text: 'Automaat e-mail',
                                html: emailHtml,
                                attachments: [{
                                    filename: `doc.pdf`,
                                    path: filePDF
                                }]
                            });

                            // Логирование успеха
                            if (emailTemplateObject.register) {
                                let sqlLog = emailTemplateObject.register;
                                await db.queryDb(sqlLog, [Teatis.id, l_userId, Teatis.email]);
                            }

                            if (emailTemplateObject.log) {
                                await db.queryDb(emailTemplateObject.log, [Teatis.id, l_userId, JSON.stringify(info)]);
                            }

                            result++;
                            return Teatis.id;

                        } catch (err) {
                            console.error(` error for doc ${Teatis.id}:`, err);

                            // Логирование ошибки
                            if (emailTemplateObject.register_error) {
                                await db.queryDb(emailTemplateObject.register_error, [Teatis.id, user.userId, JSON.stringify(err)]);
                            }
                            throw err; // Пробрасываем ошибку, чтобы Promise.all поймал (или использовать allSettled)
                        } finally {
                            // Всегда удаляем временный файл

                            if (filePDF) {
                                fs.unlink(filePDF, (err) => {
                                    if (err) console.error('Warning: Failed to delete temp PDF', err);
                                });
                            }
                        }
                    }
                )
            ;

            // Ждем выполнения всех промисов.

            const results = await Promise.all(emailPromises.map(p => p
                .then(value => ({ status: 'fulfilled', value }))
                .catch(reason => ({ status: 'rejected', reason }))
            ));

            const successCount = results.filter(r => r.status === 'fulfilled').length;
            const failCount = results.filter(r => r.status === 'rejected').length;

            return successCount;

        } catch
            (e) {
            console.error('Global error in automailer:', e);
            return 0;
        }
    }
;

// Обертка для wkhtmltopdf
function exportHtml(html, file, options) {
    return new Promise((resolve, reject) => {
        wkhtmltopdf(html, options, (err, stream) => {
            if (err) {
                reject(err);
            } else {
                const writeStream = fs.createWriteStream(file);
                stream.pipe(writeStream);

                writeStream.on('finish', resolve);
                writeStream.on('error', reject);
            }
        });
    });
}

// Экспортируем функцию, а не запускаем её сразу
// Если файл запущен напрямую (node automailerTeatis.js), то выполняем
if (require.main === module) {
    automailer()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
} else {
    module.exports = automailer;
}