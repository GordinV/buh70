'use strict';
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');
const template = 'palk_leht';
const DOC_TYPE_ID = 'PALK_LEHT';
const user = 'vlad';
const getGroupedData = require('./../../libs/getGroupedData');
const wkhtmltopdf = require('wkhtmltopdf');
const jade = require('jade');
const path = require('path');
const fs = require('fs');
const nodemailer = require('nodemailer');


exports.get = async (req, res) => {
    let id = (req.params.id || 17248); // параметр id документа
    let data = [];

    const log_data = {
        dokument: DOC_TYPE_ID,
        event: 'print',
        status: 'OK',
        content: 'Trükkitatud',
        isik_id: null
    };

    // список раьотников
    let sql = `SELECT DISTINCT t.rekvid, t.id, r.regkood, r.nimetus AS asutus, r.muud AS asutus_tais, u.id AS user_id
               FROM palk.cur_tootajad t
                        INNER JOIN ou.rekv r ON r.id = t.rekvid
                        INNER JOIN ou.userid u ON u.rekvid = r.id AND kasutaja = '${user}'
               WHERE (lopp IS NULL OR lopp <= current_date)
                 AND t.id = ${id}`;

    try {
        // sql paring

        data = await db.queryDb(sql, null, null, null, null, null, config);
        console.log('data', data);
//        let lResult = await data.data.map( (row) => {
        let row = {
            id: data.data[0].id,
            rekvid: data.data[0].rekvid,
            user_id: data.data[0].user_id
        };

        sql = ` SELECT * ,
                        sum(deebet) OVER(PARTITION BY leping_id)  AS deebet_kokku,
                        sum(kreedit) FILTER ( WHERE palk_liik <> 'TASU' ) OVER(PARTITION BY leping_id)  AS kreedit_kokku,
                        sum(sotsmaks) OVER(PARTITION BY leping_id) AS sotsmaks_kokku       
                    FROM palk.palk_leht(gomonth(make_date(year(current_date), month(current_date),1), -1)::DATE,
                    (make_date(year(current_date), month(current_date),1) -1)::DATE, ${row.rekvid}::INTEGER, 0::INTEGER,0::INTEGER, ${row.id}::INTEGER) qry`;

        let leht = await db.queryDb(sql, null, null, null, null, null, config);

        // groups
        //преобразуем данные по группам
        let group_data = getGroupedData(leht.data, 'leping_id');

        // регистрируем событие

        log_data.isik_id = row.id;

        sql = `select ou.register_events('${JSON.stringify(log_data)}'::json, ${row.user_id})`;
        let log_id = await db.queryDb(sql, null, null, null, null, null, config);

        const User = {
            asutus_tais: data.data[0].asutus_tais,
            regkood: data.data[0].regkood,
            aadress: data.data[0].aadress,
            tel: '',
            email: ''
        };

        res.render(template, {title: 'palk leht', data: leht.data, user: User, groupData: group_data});

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        log_data.isik_id = row.id;
        log_data.status = 'ERROR';
        log_data.content = error;

        sql = `select ou.register_events('${JSON.stringify(log_data)}'::json, ${row.user_id})`;
        db.queryDb(sql, null, null, null, null, null, config);

        res.send({status: 500, result: 'Error'});

    }
};

exports.pdf = async (req, res) => {
    let id = (req.params.id || 17248); // параметр id документа
    let data = [];

    const log_data = {
        dokument: DOC_TYPE_ID,
        event: 'print',
        status: 'OK',
        content: 'Trükkitatud',
        isik_id: null
    };

    // список раьотников
    let sql = `SELECT DISTINCT t.rekvid, t.id, r.regkood, r.nimetus AS asutus, r.muud AS asutus_tais, u.id AS user_id
               FROM palk.cur_tootajad t
                        INNER JOIN ou.rekv r ON r.id = t.rekvid
                        INNER JOIN ou.userid u ON u.rekvid = r.id AND kasutaja = '${user}'
               WHERE (lopp IS NULL OR lopp <= current_date)
                 AND t.id = ${id}`;

    try {


        // sql paring
        data = await db.queryDb(sql, null, null, null, null, null, config);
        console.log('data', data);
//        let lResult = await data.data.map( (row) => {
        let row = {
            id: data.data[0].id,
            rekvid: data.data[0].rekvid,
            user_id: data.data[0].user_id
        };

        sql = ` SELECT * ,
                        sum(deebet) OVER(PARTITION BY leping_id)  AS deebet_kokku,
                        sum(kreedit) FILTER ( WHERE palk_liik <> 'TASU' ) OVER(PARTITION BY leping_id)  AS kreedit_kokku,
                        sum(sotsmaks) OVER(PARTITION BY leping_id) AS sotsmaks_kokku       
                    FROM palk.palk_leht(gomonth(make_date(year(current_date), month(current_date),1), -1)::DATE,
                    (make_date(year(current_date), month(current_date),1) -1)::DATE, ${row.rekvid}::INTEGER, 0::INTEGER,0::INTEGER, ${row.id}::INTEGER) qry`;

        let leht = await db.queryDb(sql, null, null, null, null, null, config);

        // groups
        //преобразуем данные по группам
        let group_data = getGroupedData(leht.data, 'leping_id');

        // регистрируем событие

        log_data.isik_id = row.id;

        sql = `select ou.register_events('${JSON.stringify(log_data)}'::json, ${row.user_id})`;
        let log_id = await db.queryDb(sql, null, null, null, null, null, config);

        const User = {
            asutus_tais: data.data[0].asutus_tais,
            regkood: data.data[0].regkood,
            aadress: data.data[0].aadress,
            tel: '',
            email: ''
        };

        // вернуть отчет
        let printHtml;

        // вернуть отчет
        res.render(template, {title: 'palk leht', data: leht.data, user: User, groupData: group_data}, (err, html) => {
            printHtml = html;
        });

        //attachment
        let l_file_name = `doc_${row.id}`;

        let filePDF = await createPDF(printHtml, l_file_name);

        if (filePDF) {
            const stream = await fs.createReadStream(filePDF);

            res.setHeader('Content-disposition', 'inline; filename="doc.pdf"');
            res.setHeader('Content-type', 'application/pdf');

            stream.pipe(res);

            // удаляем файл
            await fs.unlink(filePDF, (err, data) => {
                if (err) {
                    return reject(err);
                }
            });
        } else {
            res.send({status: 500, result: 'Puudub fail'});
        }


    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        log_data.isik_id = row.id;
        log_data.status = 'ERROR';
        log_data.content = error;

        sql = `select ou.register_events('${JSON.stringify(log_data)}'::json, ${row.user_id})`;
        db.queryDb(sql, null, null, null, null, null, config);

        res.send({status: 500, result: 'Error'});

    }
};

exports.email = async (req, res) => {
    let id = (req.params.id || 17248); // параметр id документа
    let data = [];

    const log_data = {
        dokument: DOC_TYPE_ID,
        event: 'email',
        status: 'OK',
        content: 'Saadetud',
        isik_id: null
    };

    // список раьотников
    let sql = `SELECT DISTINCT t.rekvid, t.id, r.regkood, r.nimetus AS asutus, r.muud AS asutus_tais, u.id AS user_id
               FROM palk.cur_tootajad t
                        INNER JOIN ou.rekv r ON r.id = t.rekvid
                        INNER JOIN ou.userid u ON u.rekvid = r.id AND kasutaja = '${user}'
               WHERE (lopp IS NULL OR lopp <= current_date)
                 AND t.id = ${id}`;

    try {


        // sql paring
        data = await db.queryDb(sql, null, null, null, null, null, config);
        let row = {
            id: data.data[0].id,
            rekvid: data.data[0].rekvid,
            user_id: data.data[0].user_id
        };

        sql = ` SELECT * ,
                        sum(deebet) OVER(PARTITION BY leping_id)  AS deebet_kokku,
                        sum(kreedit) FILTER ( WHERE palk_liik <> 'TASU' ) OVER(PARTITION BY leping_id)  AS kreedit_kokku,
                        sum(sotsmaks) OVER(PARTITION BY leping_id) AS sotsmaks_kokku       
                    FROM palk.palk_leht(gomonth(make_date(year(current_date), month(current_date),1), -1)::DATE,
                    (make_date(year(current_date), month(current_date),1) -1)::DATE, ${row.rekvid}::INTEGER, 0::INTEGER,0::INTEGER, ${row.id}::INTEGER) qry`;

        let leht = await db.queryDb(sql, null, null, null, null, null, config);

        // groups
        //преобразуем данные по группам
        let group_data = getGroupedData(leht.data, 'leping_id');

        // регистрируем событие

        log_data.isik_id = row.id;

        sql = `select ou.register_events('${JSON.stringify(log_data)}'::json, ${row.user_id})`;
        let log_id = await db.queryDb(sql, null, null, null, null, null, config);

        const User = {
            asutus_tais: data.data[0].asutus_tais,
            regkood: data.data[0].regkood,
            aadress: data.data[0].aadress,
            tel: '',
            email: ''
        };

        // вернуть отчет
        let printHtml;

        // вернуть отчет
        res.render(template, {title: 'palk leht', data: leht.data, user: User, groupData: group_data}, (err, html) => {
            printHtml = html;
        });

        //attachment
        let l_file_name = `doc_${row.id}`;

        let filePDF = await createPDF(printHtml, l_file_name);

        if (filePDF) {
            const stream = await fs.createReadStream(filePDF);

            res.setHeader('Content-disposition', 'inline; filename="doc.pdf"');
            res.setHeader('Content-type', 'application/pdf');

            stream.pipe(res);

            // удаляем файл
            await fs.unlink(filePDF, (err, data) => {
                if (err) {
                    return reject(err);
                }
            });
        } else {
            res.send({status: 500, result: 'Puudub fail'});
        }

        // создать объект
        const emailDoc = new Doc(params.docTypeId, null, user.userId, user.asutusId, module);

        if (!UserConfig.email) {
            await getConfigData(user);
        }

        const printTemplates = emailDoc.config.print;
        const emailTemplates = emailDoc.config.email ? emailDoc.config.email: '';

        if (!printTemplates) {
            // нет документов для отправки
            return res.send({status: 500, result: null, error_message: `Templates ei leidnud`});
        }
        let template = null,
            emailHtml = null,
            attachment,
            docNumber = '',
            receiverEmail,
            emailTemplate = null;

        const templateObject = printTemplates.find(templ => templ.params === (id ? 'id' : 'sqlWhere'));
        template = templateObject.view;

        // create reusable transporter object using the default SMTP transport
        let transporter = nodemailer.createTransport({
            host: UserConfig['email'].smtp,
            port: UserConfig['email'].port,
            secure: UserConfig['email'].port == 465 ? true : false, // true for 465, false for other ports
            auth: {
                user: UserConfig['email'].user,
                pass: UserConfig['email'].pass
            }
        });

        // выборка данных
        // делаем массив промисов
        const dataPromises = ids.map(id => {
            return new Promise(resolve => {
                emailDoc.setDocumentId(id);
                resolve(emailDoc['select'](emailDoc.config));
            })
        });

        // решаем их
        const selectedDocs = [];
        let promiseSelectResult = await Promise.all(dataPromises).then((result) => {

            // убираем из получателей тех, у кого нет адреса
            result.forEach(arve => {
                if (arve.row[0].email) {
                    selectedDocs.push({...arve.row[0], details: result[0].details});
                }
            })

        }).catch((err) => {
            console.error('catched error->', err);
            return res.send({status: 500, result: null, error_message: err});
        });

        // делаем массив промисов отправки почты
        const emailPromises = selectedDocs.map(async arve => {
            // вернуть отчет
            docNumber = arve.number ? arve.number : null;
            receiverEmail = arve.email ? arve.email : null;

            let renderForm = 'arve_kaartid';
            switch (params.docTypeId) {
                case 'ARV':
                    renderForm = 'arve_kaartid';
                    break;
                case 'TEATIS':
                    renderForm = 'teatis_kaartid';
                    break;
            }
            res.render(renderForm, {data: [arve], user: user}, (err, html) => {
                printHtml = html;
            });

            const emailTemplateObject = emailTemplates.find(templ => templ.params === 'id');
            emailTemplate = emailTemplateObject.view;

            if (emailTemplate) {
                res.render(emailTemplate, {user: user}, (err, html) => {
                    emailHtml = html;
                });
            }

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
                        from: `"${user.userName}" <${UserConfig['email'].email}>`, //`${user.userName} <${config['email'].email}>`, // sender address
                        to: `${receiverEmail}`, // (, baz@example.com) list of receivers
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
                            return reject(err);
                        } else {
                            result++;

                            // удаляем файл

                            await fs.unlink(filePDF, (err, data) => {
                                if (err) {
                                    return reject(err);
                                }
                            });

                            // register emailing event

                            if (emailTemplateObject.register) {
                                // если есть метод регистрации, отметим email
                                let sql = emailTemplateObject.register,
                                    params = [arve.id, user.userId];

                                if (sql) {
                                    db.queryDb(sql, params);
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
            console.error('promiseEmailResult', err);
            return res.send({status: 500, result: null, error_message: err});
        });

        //ответ
        res.send({
            status: 200, result: result, data: {
                action: 'email',
                result: {
                    error_code: 0,
                    error_message: null,
                },
                data: result
            }
        });



    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        log_data.isik_id = row.id;
        log_data.status = 'ERROR';
        log_data.content = error;

        sql = `select ou.register_events('${JSON.stringify(log_data)}'::json, ${row.user_id})`;
        db.queryDb(sql, null, null, null, null, null, config);

        res.send({status: 500, result: 'Error'});

    }
};

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
