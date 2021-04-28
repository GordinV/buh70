'use strict';
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');
const template = 'palk_leht';
const emailTemplate = 'palk_leht_email';

const DOC_TYPE_ID = 'PALK_LEHT';
const user = 'vlad';
const getGroupedData = require('./../../libs/getGroupedData');
const wkhtmltopdf = require('wkhtmltopdf');
const jade = require('jade');
const path = require('path');
const fs = require('fs');
const nodemailer = require('nodemailer');
const Doc = require('./../../classes/DocumentTemplate');
const async = require('async');
const doc_id = 213041; // palk_leht dok.tyyp


const getConfigData = async function (user) {
    const docConfig = new Doc('config', user.asutusId, user.userId, user.asutusId, 'lapsed');
    const configData = await docConfig.select(null, config);
    UserConfig.email = {...configData.row[0]};
};
const UserConfig = {};

let promise = new Promise((resolve, reject) => {

// получить список работников
    let sql = `SELECT DISTINCT t.rekvid, t.id, r.regkood, r.nimetus AS asutus, r.muud AS asutus_tais, u.id AS user_id,
                t.nimetus AS nimi, t.email
               FROM palk.cur_tootajad t
                        INNER JOIN ou.rekv r ON r.id = t.rekvid
                        INNER JOIN ou.userid u ON u.rekvid = r.id AND kasutaja = '${user}'
               WHERE (lopp IS NULL OR lopp >= current_date)
               AND (t.email IS NOT NULL AND NOT empty(t.email) AND t.email LIKE '%@%')
                AND t.id NOT IN (
                    SELECT (propertis ->> 'isik_id')::INTEGER
                    FROM ou.logs
                    WHERE doc_id = ${doc_id}
                      AND propertis ->> 'event' = 'email'
                      AND month((timestamp)::DATE) = month(current_date)
                      AND year(timestamp::DATE) = year(current_date)
                      )
                      LIMIT 100`;

    let data = db.queryDb(sql, null, null, null, null, null, config);
    resolve(data);
}).then((data) => {
    // отправить всем квитанции
    // массив задач
    let tasks = [];
    data.data.map(row => {
        tasks.push(function (callback) {
                saada_palga_kvitung_mailiga(row.id);
                callback();
            }
        )
    });
    return tasks;
}).then((tasks) => {
    // выполнить последовательно задачи
    async.series(tasks, (tulemus) => {
    }, (err, results) => {
        console.log(err, results);
        // results is now equal to: { 1: 'one', 2: 'two', 3:'three' }
    })
});


//saada_palga_kvitung_mailiga(30752);

async function saada_palga_kvitung_mailiga(tootajaId) {
//    let id = (req.params.id || 17248); // параметр id документа
    let data = [];

    const log_data = {
        dokument: DOC_TYPE_ID,
        event: 'email',
        status: 'OK',
        content: 'Saadetud',
        isik_id: null,
        mail_info: null
    };
    var row;
    var filePDF;
    // Пользователь
    var User = {};

    // параметры почты (временно)
    let l_smtp = 'smtp.gmail.com';
    let l_port = 465;
    let l_user = 'vladislav.gordin@gmail.com';
    let l_pass = 'Vlad490710A';
    var leht = {};
    var group_data = {};
    var html;

    // тело письма
    var emailHtml;


    // обьявляем промис
    let promise = new Promise((resolve, reject) => {
            let file = path.join(__dirname, './../..', 'views', `${emailTemplate}.jade`);
            emailHtml = jade.renderFile(file);
            resolve(emailHtml);
        }
    ).then(async () => {
            // sql paring
            // список раьотников
            let sql = `SELECT DISTINCT t.rekvid, t.id, r.regkood, r.nimetus AS asutus, r.muud AS asutus_tais, u.id AS user_id,
                t.nimetus AS nimi, t.email
               FROM palk.cur_tootajad t
                        INNER JOIN ou.rekv r ON r.id = t.rekvid
                        INNER JOIN ou.userid u ON u.rekvid = r.id AND kasutaja = '${user}'
               WHERE (lopp IS NULL OR lopp >= current_date)
                 AND t.id = ${tootajaId}`;

            return await db.queryDb(sql, null, null, null, null, null, config);

        }
    ).then(async (data) => {
            row = {
                id: data.data[0].id,
                rekvid: data.data[0].rekvid,
                user_id: data.data[0].user_id,
                nimi: data.data[0].nimi,
                email: data.data[0].email
            };
//Заполняем данные на пользователя
            User = {
                asutus_tais: data.data[0].asutus_tais,
                regkood: data.data[0].regkood,
                aadress: data.data[0].aadress,
                tel: ''
            };

            // data for log
            log_data.isik_id = row.id;

            //выборка данных отчета
            let sql = ` SELECT * ,
                        sum(deebet) OVER(PARTITION BY leping_id)  AS deebet_kokku,
                        sum(kreedit) FILTER ( WHERE palk_liik <> 'TASU' ) OVER(PARTITION BY leping_id)  AS kreedit_kokku,
                        sum(sotsmaks) OVER(PARTITION BY leping_id) AS sotsmaks_kokku       
                    FROM palk.palk_leht(gomonth(make_date(year(current_date), month(current_date),1), -1)::DATE,
                    (make_date(year(current_date), month(current_date),1) -1)::DATE, ${row.rekvid}::INTEGER, 0::INTEGER,0::INTEGER, ${row.id}::INTEGER) qry`;

            leht = await (db.queryDb(sql, null, null, null, null, null, config));
            console.log('leht', leht, row.rekvid, row.id);

        }
    ).then(() => {
            // groups
            //преобразуем данные по группам
            group_data = getGroupedData(leht.data, 'leping_id');
            return true;
        }
    ).then(async () => {
            // вернуть отчет
            let printHtml;
            let file = path.join(__dirname, './../..', 'views', `${template}.jade`);
            html = jade.renderFile(file, {
                title: 'palk leht',
                data: leht.data,
                user: User,
                groupData: group_data
            });

        }
    ).then(async () => {
            //attachment
            let l_file_name = `doc_${row.id}`;

            filePDF = await createPDF(html, l_file_name);

        }
    ).then(async () => {

            // create reusable transporter object using the default SMTP transport
            const transporter = await nodemailer.createTransport({
                host: l_smtp ? l_smtp : UserConfig['email'].smtp,
                port: l_port ? l_port : UserConfig['email'].port,
                secure: l_port ? true : UserConfig['email'].port === 465, // true for 465, false for other ports
                auth: {
                    user: l_user ? l_user : UserConfig['email'].user,
                    pass: l_pass ? l_pass : UserConfig['email'].pass
                }
            });

            let now = new Date();
            let kuu = now.getMonth();
            let aasta = now.getFullYear();
            let period = (kuu < 9 ? '0' : '') + kuu.toString() + '.' + aasta;

            // sending email
            // send mail with defined transport object
            return transporter.sendMail({
                from: `"${user.userName}" <${l_user ? l_user : UserConfig['email'].email}>`, //`${user.userName} <${config['email'].email}>`, // sender address
                to: `${row.email}`, // (, baz@example.com) list of receivers
                subject: `Palgakviitung ${period}`, // Subject line
                text: 'Automaat e-mail', // plain text body
                html: emailHtml, // html body
                attachments: [
                    // String attachment
                    {
                        filename: `doc.pdf`,
                        content: 'Dokument ',
                        path: filePDF
                    }]

            });
        }
    ).then((info, err) => {
            if (err) {
                console.error('mail.error', err);
            } else {
                log_data.mail_info = info;
                result++;

                // удаляем файл
                return fs.unlink(filePDF, (data, err) => {
                    if (err) {
                        console.error('unlink: ', err);
                    }
                });
            }

        }
    ).then(async () => {
            // register emailing event

            // регистрируем событие
            let sql = `select ou.register_events('${JSON.stringify(log_data)}'::json, ${row.user_id})`;
            let tulemus = await db.queryDb(sql, null, null, null, null, null, config);

            return;
            return ('Ok')
        }
    ).catch((error) => {
        // rejection
        console.error('rejected', error);

    });

}
const createPDF = async function createFile(html, fileName = 'doc') {
    const options = {
        pageSize: 'letter',
    };
    let outFile = path.join(__dirname, './../..', 'public', 'pdf', `${fileName}.pdf`);

    try {
        await exportHtml(html, outFile, options);
        return outFile;
    } catch (error) {
        console.error(`ERROR: Handle rejected promise: '${error}' !!!`);
        return null;
    }
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


