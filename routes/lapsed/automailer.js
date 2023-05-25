'use strict';
const db = require('./../../libs/db');
const wkhtmltopdf = require('wkhtmltopdf');
const path = require('path');
const nodemailer = require('nodemailer');
const fs = require('fs');
const config = require('../../config/default');
const jade = require('jade');

const Doc = require('./../../classes/DocumentTemplate');


const createPDF = async function createFile(html, fileName = 'doc') {

    const options = {
        pageSize: 'letter',
    };
    let outFile = path.join(__dirname, './../..', 'public', 'pdf', `${fileName}.pdf`);

//    let outFile = path.join(__dirname, '..', 'public', 'pdf', `${fileName}.pdf`);

    try {
        await exportHtml(html, outFile, options);
    } catch (error) {
        console.error(`ERROR: Handle rejected promise: '${error}' !!!`);
        outFile = null;
    }
    return outFile;
};

const automailer = async () => {
    const UserConfig = {};
    var l_smtp;
    var l_port = 465;
    var l_user = 'oppetasu';
    var l_user_name = 'Õppetasu';
    var l_user_mail = 'oppetasu@narva.ee';
    var l_pass;
    var l_userId = 11558;
    var l_limit = 25;
    var result = 0;

    try {
        // создать объект
        const emailDoc = new Doc('ARV', null, l_userId, 119, 'lapsed');
        const printTemplates = emailDoc.config.print;
        const emailTemplates = emailDoc.config.email ? emailDoc.config.email : '';

        // sql

        let sql = `WITH doc AS (
    WITH params AS (
        SELECT make_date(year(current_date), month(current_date), 1)              AS kpv2,
               gomonth(make_date(year(current_date), month(current_date), 1), -1) AS kpv1
    ),
         kas_lubatud AS (
             SELECT rekvid, kas_alusta, a.alg_kpv
             FROM ou.arvete_meil a,
                  params
             WHERE a.alg_kpv >= params.kpv1
               AND a.lopp_kpv <= params.kpv2
               AND coalesce(a.kas_alusta, FALSE)
               AND NOT coalesce(a.paus, FALSE)               
             ORDER BY id DESC
         ),
    
         docs AS (
             SELECT d.id
             FROM docs.arv a
                      INNER JOIN docs.doc d ON a.parentid = d.id
                      INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                      INNER JOIN lapsed.laps l ON l.id = ld.parentid
                      LEFT OUTER JOIN lapsed.vanemad v ON l.id = v.parentid AND v.asutusid = a.asutusid
                      LEFT OUTER JOIN lapsed.vanem_arveldus va
                                      ON l.id = va.parentid AND va.asutusid = a.asutusid AND va.rekvid = a.rekvid
                      INNER JOIN kas_lubatud ON kas_lubatud.rekvid = d.rekvid                                      
                     , params
             WHERE a.kpv >= params.kpv1
               AND a.kpv < params.kpv2
               AND d.status <> 3
               AND d.doc_type_id IN (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood = 'ARV')
               AND coalesce((v.properties ->> 'kas_email')::BOOLEAN, FALSE)::BOOLEAN
               AND (v.properties ->> 'email_alates' is null or (v.properties ->> 'email_alates')::date >= current_date)
               and d.history::text not ilike '%email%'
               AND a.rekvid IN (SELECT id FROM ou.rekv WHERE parentid = 119)
               AND kas_lubatud.kas_alusta
             LIMIT ${l_limit}
         ),
         arved AS (
             SELECT min(a.kpv) AS alg_kpv, max(a.kpv) AS lopp_kpv, a.rekvid
             FROM docs.arv a
             WHERE parentid IN (SELECT id from docs)
             GROUP BY a.rekvid
         ),
         aa as (
             SELECT jsonb_agg(jsonb_build_object ('pank', case when left(arve,7) in ('EE47101') then 'SEB Pank IBAN ' WHEN left(arve,7) in ('EE71220') then 'SWEDPANK IBAN ' else '' end, 'arve',arve)) as arved
             FROM ou.aa
             WHERE parentid in (select rekvid from ou.userid where id = ${l_userId}::integer)
               AND kassa = 1
               AND coalesce((properties ->> 'kas_oppetasu')::BOOLEAN, FALSE)
         ),

         kaibed AS (
             WITH lapsed AS (
                 SELECT array_agg(parentid) AS isik_ids
                 FROM lapsed.liidestamine l
                 WHERE docid IN (SELECT id from docs)
             )
             SELECT jsonb_build_object('alg_db', sum(kb.alg_db),
                                       'alg_kr', sum(kb.alg_kr),
                                       'db', sum(kb.db),
                                       'kr', sum(kb.kr),
                                       'lopp_db', sum(kb.lopp_db),
                                       'lopp_kr', sum(kb.lopp_kr)) AS kaibed,
                    kb.isik_id,
                    kb.rekvid
             FROM arved a,
                  lapsed,
                  lapsed.saldo_ja_kaibeandmik(a.rekvid,
                                              make_date(year(a.alg_kpv), month(a.alg_kpv), 01)::DATE,
                                              gomonth(make_date(year(a.lopp_kpv), month(a.lopp_kpv), 01), 1) - 1) kb
             GROUP BY kb.isik_id, kb.rekvid
         ),
         details AS (
             SELECT a.parentid,
                    jsonb_build_object('id', a1.id, 'parentid', a1.parentid,
                                       'nomid', a1.nomid,
                                       'kogus', a1.kogus,
                                       'hind', a1.hind::NUMERIC(12, 4),
                                       'kbm', a1.kbm::NUMERIC(12, 2),
                                       'kbmta', a1.kbmta::NUMERIC(12, 2),
                                       'summa', a1.summa::NUMERIC(12, 2),
                                       'kood', TRIM(n.kood):: VARCHAR(20),
                                       'nimetus', TRIM(n.nimetus) :: VARCHAR(254),
                                       'uhik', n.uhik :: TEXT,
                                       'vahe', (COALESCE((SELECT vahe
                                                          FROM lapsed.cur_lapse_taabel
                                                          WHERE id = (a1.properties ->> 'lapse_taabel_id')::INTEGER
                                                          LIMIT 1)::NUMERIC(12, 4),
                                                         0)::NUMERIC(12, 4)),
                                       'soodustus',
                                       (COALESCE((a1.properties ->> 'soodustus')::NUMERIC(12, 4), 0)::NUMERIC(12, 4)),
                                       'tais_hind', a1.hind::NUMERIC(12, 4),
                                       'soodus', a1.soodus::NUMERIC(12, 4),
                                       'kood1', a1.kood1,
                                       'kood2', a1.kood2,
                                       'kood3', a1.kood3,
                                       'kood4', a1.kood4,
                                       'kood5', a1.kood5,
                                       'tunnus', a1.tunnus,
                                       'proj', a1.proj,
                                       'konto', a1.konto,
                                       'tp', a1.tp,
                                       'km', ((CASE
                                                   WHEN a1.kbm_maar IS NULL
                                                       THEN COALESCE(
                                                           (n.properties :: JSONB ->>
                                                            'vat'),
                                                           '-') :: VARCHAR(20)
                                                   ELSE a1.kbm_maar END)::VARCHAR(20)),
                                       'uhik', n.uhik,
                                       'yksus', (a1.properties ->> 'yksus'),
                                       'muud', a1.muud,
                                       'markused', (TRIM(n.nimetus) || ', ' || a1.muud)) AS details
             FROM docs.arv1 a1
                      INNER JOIN docs.arv a
                                 ON a.id = a1.parentId
                      INNER JOIN libs.nomenklatuur n ON n.id = a1.nomId
             WHERE a.parentid IN (SELECT id from docs)
               AND a1.kogus <> 0
               order by n.nimetus
               )

    SELECT d.id,
           a.id                                                                                 AS doc_id,
           to_char(created, 'DD.MM.YYYY HH:MM:SS') :: TEXT                                      AS created,
           to_char(lastupdate, 'DD.MM.YYYY HH:MM:SS') :: TEXT                                   AS lastupdate,
           d.bpm,
           d.status                                                                             AS doc_status,
           a.number::TEXT                                                                       AS number,
           a.rekvId,
           a.liik,
           a.operid,
           to_char(a.kpv, 'YYYY-MM-DD')::TEXT                                                   AS kpv,
           to_char(a.kpv, 'DD.MM.YYYY')::TEXT                                                   AS kpv_print,
           a.asutusid,
           a.arvId,
           a.lisa:: TEXT                                                                        AS lisa,
           to_char(a.tahtaeg, 'YYYY-MM-DD')::TEXT                                               AS tahtaeg,
           to_char(a.tahtaeg, 'DD.MM.YYYY')::TEXT                                               AS tahtaeg_print,
           a.kbmta,
           a.kbm,
           a.summa,
           a.tasud,
           a.tasudok::TEXT                                                                      AS tasudok,
           a.muud,
           asutus.regkood,
           asutus.nimetus::TEXT                                                                 AS asutus,
           coalesce(asutus.aadress,'') as aadress,
           ltrim(rtrim(asutus.email))::TEXT                                                                   AS email,
           asutus.properties ->> 'kmkr'                                                         AS kmkr,
           asutus.properties::JSONB -> 'asutus_aa' -> 0 ->> 'aa'                                AS asutuse_aa,
           a.doklausid,
           a.journalid,
           d.history -> 0 ->> 'user'                                                            AS koostaja,
           a.properties ->> 'aa'                                                                AS aa,
           l.id                                                                                 AS lapsId,
           l.isikukood::TEXT,
           l.nimi::TEXT                                                                         AS lapse_nimi,
           lapsed.get_viitenumber(d.rekvid, l.id)                                               AS viitenr,
           a.properties ->> 'tyyp'::TEXT                                                        AS tyyp,
           a.jaak::NUMERIC(12, 2)                                                               AS jaak,
           to_char(make_date(year(arved.alg_kpv), month(arved.alg_kpv), 1)::DATE, 'DD.MM.YYYY') AS period_alg_print,
           lpad(month(arved.lopp_kpv)::TEXT, 2, '0') || '.' ||
           year(arved.lopp_kpv)::TEXT                                                           AS laekumise_period,
           a.properties ->> 'ettemaksu_period'                                                  AS ettemaksu_period,
           va.properties ->> 'pank'                                                             AS pank,
           va.properties ->> 'iban'                                                             AS iban,
           to_jsonb(array((SELECT kaibed FROM kaibed WHERE kaibed.isik_id = l.id and kaibed.rekvid = d.rekvid)))             AS kaibed,
           to_jsonb(array((SELECT details FROM details det WHERE det.parentid = d.id)))         AS details,
            u.properties->>'smtp' AS smtp, 
            u.properties->>'port' AS port, 
            u.properties->>'pass' AS pass,
            u.properties->>'user' AS user,
            r.muud as tais_nimetus,
            r.tel as rekv_tel,
            r.email as rekv_email,
            r.aadress as rekv_aadress,
            r.regkood as rekv_regkood,
           aa.arved AS arved
                       
    FROM arved,aa,
         docs.doc d
             INNER JOIN docs.arv a ON a.parentId = d.id
             INNER JOIN libs.asutus AS asutus ON asutus.id = a.asutusId
             INNER JOIN ou.userid u ON u.id = ${l_userId} :: INTEGER
             inner join ou.rekv r on r.id = d.rekvid
             LEFT OUTER JOIN lapsed.liidestamine ll ON ll.docid = d.id
             LEFT OUTER JOIN lapsed.laps l
                             ON l.id = ll.parentid
             LEFT OUTER JOIN lapsed.vanem_arveldus va
                             ON va.asutusid = a.asutusid AND va.rekvid = d.rekvid AND va.parentid = l.id
                                 AND va.parentid = l.id

    WHERE d.id IN (SELECT id from docs)
    and not empty(asutus.email)
    and arved.rekvid = d.rekvid
)
SELECT doc.*,
       coalesce((doc.kaibed -> 0 ->> 'alg_db')::NUMERIC, 0) -
       coalesce((doc.kaibed -> 0 ->> 'alg_kr')::NUMERIC, 0)              AS alg_jaak,
       coalesce((doc.kaibed -> 0 ->> 'lopp_db')::NUMERIC, 0) -
       coalesce((doc.kaibed -> 0 ->> 'lopp_kr')::NUMERIC, 0)             AS tasumisele,
       coalesce((doc.kaibed -> 0 ->> 'lopp_db')::NUMERIC, 0) -
       coalesce((doc.kaibed -> 0 ->> 'lopp_kr')::NUMERIC, 0)             as lopp_jaak,
       coalesce((doc.kaibed -> 0 ->> 'kr')::NUMERIC, 0)                  AS laekumised,
       CASE
           WHEN coalesce((doc.kaibed ->> 'lopp_kr')::NUMERIC, 0) > 0
               THEN coalesce((doc.kaibed ->> 'lopp_kr')::NUMERIC, 0)
           ELSE 0 END                                                    AS ettemaksud
FROM doc`;

        let selectedDocs = await db.queryDb(sql, null, null, null, null, null, config);


        l_smtp = selectedDocs.data[0].smtp;
        l_port = selectedDocs.data[0].port;
        l_pass = selectedDocs.data[0].pass;
        l_user = selectedDocs.data[0].user;

        let template = null,
            emailTemplate = null;

        const templateObject = printTemplates.find(templ => templ.params === 'id');
        template = templateObject.view;

        // create reusable transporter object using the default SMTP transport

        let transporter = nodemailer.createTransport({
            host: l_smtp,
            port: l_port,
            secure: l_port == 465 ? true : false, // true for 465, false for other ports
            auth: {
                user: l_user,
                pass: l_pass
            },
            tls: {
                rejectUnauthorized: false
            }
        });


        // решаем их

        // делаем массив промисов отправки почты
        const emailPromises = selectedDocs.data.map(async arve => {

            let user = {
                id: l_userId,
                userId: l_userId,
                userName: l_user_name,
                asutus: 'Narva Linnavalitsuse Kultuuriosakond',
                parent_asutus: 'Narva Linnavalitsuse Kultuuriosakond',
                asutusTais: 'Narva Linnavalitsuse Kultuuriosakond',
                aadress: 'Peetri plats 1, 20308 Narva',
                tel: '359 9120',
                email: 'kultuur@narva.ee',
                regkood: '75024260',
                asutusId: 119,
                parentid: 63,
            };

            // уточняем данные отправителя
            user.asutus = arve.tais_nimetus;
            user.asutusTais = arve.tais_nimetus;
            user.tel = '';
            user.aadress = arve.rekv_aadress;
            user.email = 'oppetasu@narvakultuur.ee';//arve.rekv_email;
            user.parentid = 119;
            user.regkood = arve.rekv_regkood;

            // вернуть отчет

            let renderForm = 'arve_kaart';

            let file = path.join(__dirname, './../..', 'views', `${renderForm}.jade`);
            let printHtml = await jade.renderFile(file, {
                data: {
                    '0': arve,
                    details: arve.details
                }, user: user
            });

            const emailTemplateObject = emailTemplates.find(templ => templ.params === 'id');
            emailTemplate = emailTemplateObject.view;

            file = path.join(__dirname, './../..', 'views', `${emailTemplate}.jade`);
            let emailHtml = await jade.renderFile(file, {doc: arve, user: user});

            //attachment
            let filePDF = await createPDF(printHtml, `doc_${arve.id}`);
            if (!filePDF) {
                // error in PDF create
                throw new Error('PDF faili viga');
            }

            // sending email
            // send mail with defined transport object
            return new Promise((resolve, reject) => {
                transporter.sendMail({
                        from: `"${l_user_name}" <${l_user_mail}>`, //`${user.userName} <${config['email'].email}>`, // sender address
                        to: `${arve.email}`, // (, baz@example.com) list of receivers (arve.email)
                        subject: `Saadan dokument nr. ${arve.number}`, // Subject line
                        text: 'Automaat e-mail', // plain text body
                        html: emailHtml, // html body
                        attachments: [
                            // String attachment
                            {
                                filename: `doc.pdf`,
                                content: 'Dokument ',
                                path: filePDF
                            }]

                    }, async (err, info) => {
                        if (err) {
                            console.error('email error', arve.email, info, err);
                            if (emailTemplateObject.register_error) {
                                // если есть метод регистрации, отметим email
                                let sql = emailTemplateObject.register_error,
                                    params = [arve.id, user.userId, JSON.stringify(err)];

                                if (sql) {
                                    let tulemus = await db.queryDb(sql, params);
                                }

                                // логгирование ответа почтового сервера

                                sql = emailTemplateObject.log,
                                    params = [arve.id, user.userId, JSON.stringify(err)];

                                if (sql) {
                                    let tulemus_log = await db.queryDb(sql, params);
                                }

                            }
                            return reject(err);
                        } else {
                            result++;

                            // удаляем файл

                            fs.unlink(filePDF, (err, data) => {
                                if (err) {
                                    console.error('PDF delete error', err);
                                }
                            });

                            // register emailing event

                            if (emailTemplateObject.register) {
                                // если есть метод регистрации, отметим email
                                let sql = emailTemplateObject.register,
                                    params = [arve.id, l_userId];

                                if (sql) {
                                    let tulemus = await db.queryDb(sql, params);
                                }
                            }

                            if (emailTemplateObject.log) {
                                let sql = emailTemplateObject.log,
                                    params = [arve.id, user.userId, JSON.stringify(info)];

                                if (sql) {
                                    let tulemus_log = await db.queryDb(sql, params);
                                }
                            }

                            return resolve(arve.id);
                        }

                    }
                );
            });
        });

        // решаем их

        let promiseEmailResult = await Promise.all(emailPromises).catch((err) => {
            console.error(err);
            return 0;
        });

        //ответ
        console.log('Ok')
    } catch (e) {
        console.error('error:', e); // @todo Обработка ошибок
        return 0;
    }


};

return automailer();


const getConfigData = async function (user) {
    const docConfig = new Doc('config', user.asutusId, user.userId, user.asutusId, 'lapsed');
    const configData = await docConfig.select();
    UserConfig.email = {...configData.row[0]};
};

function exportHtml(html, file, options) {
    return new Promise((resolve, reject) => {
        wkhtmltopdf(html, options, (err, stream) => {
            if (err) {
                reject(err);
            } else {
                stream.pipe(fs.createWriteStream(file));
                resolve();
            }
        });
    });
}