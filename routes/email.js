'use strict';
const db = require('./../libs/db');
const wkhtmltopdf = require('wkhtmltopdf');
const path = require('path');
const nodemailer = require('nodemailer');
const fs = require('fs');
const config = require('../config/default');

const Doc = require('./../classes/DocumentTemplate');
const UserConfig = {};
const getParameterFromFilter = require('./../libs/getParameterFromFilter');
const getGroupedData = require('./../libs/getGroupedData');


const createPDF = async function createFile(html, fileName = 'doc') {

    const options = {
        pageSize: 'letter',
    };
    let outFile = path.join(__dirname, '..', 'public', 'pdf', `${fileName}.pdf`);

    try {
        await exportHtml(html, outFile, options);
    } catch (error) {
        console.error(`ERROR: Handle rejected promise: '${error}' !!!`);
        outFile = null;
    }
    return outFile;
};

const getConfigData = async function (user) {
    const docConfig = new Doc('config', user.asutusId, user.userId, user.asutusId, 'lapsed');
    const configData = await docConfig.select();
    UserConfig.email = {...configData.row[0]};
};

exports.post = async (req, res) => {
    const params = req.body;
    const id = Number(params.docId || 0); // параметр id документа
    let ids = params.data || []; // параметр ids документов

    const user = require('../middleware/userData')(req); // данные пользователя
    const module = req.body.module;
    let result = 0;

    // проверка ка пользователя
    if (!user) {
        console.error('error 401, no user');
        return res.status(401).end();
    }

    // если передан отдлельный id
    if (!ids.length && id) {
        // передан ид документа
        ids.push(id);
    } else {
        // проверка на уникальность
        ids = [...new Set(ids)];
    }

    // проверим на наличие типа документа
    if (!params.docTypeId) {
        // нет документов для отправки
        return res.send({status: 200, result: null, error_message: `Dokument tüüp puudub või vale`});
    }

    if (!ids || ids.length === 0) {
        // нет документов для отправки
        return res.send({status: 200, result: null, error_message: `Valitud lapsed ei leidnud`});
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
    let printHtml = null;

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


};

exports.sendTeatis = async (req, res) => {
    const params = req.body;
    const id = Number(params.docId || 0); // параметр id документа
    let ids = params.data || []; // параметр ids документов

    const user = require('../middleware/userData')(req); // данные пользователя
    const module = req.body.module;
    let result = 0;

    if (!user) {
        console.error('error 401, no user');
        return res.status(401).end();
    }

    if (!ids.length && id) {
        // передан ид документа
        ids.push(id);
    } else {
        // проверка на уникальность
        ids = [...new Set(ids)];
    }

    if (!params.docTypeId) {
        // нет документов для отправки
        return res.send({status: 200, result: null, error_message: `Dokument tüüp puudub või vale`});
    }

    if (!ids || ids.length === 0) {
        // нет документов для отправки
        return res.send({status: 200, result: null, error_message: `Valitud dokumendid ei leidnud`});
    }

    // создать объект
    const emailDoc = new Doc(params.docTypeId, null, user.userId, user.asutusId, module);

    if (!UserConfig.email) {
        await getConfigData(user);
    }

    const printTemplates = emailDoc.config.print;
    const emailTemplates = emailDoc.config.email;

    if (!printTemplates || !emailTemplates) {
        // нет документов для отправки
        return res.send({status: 500, result: null, error_message: `Templates ei leidnud`});
    }
    let template = null,
        emailHtml = null,
        attachment,
        docNumber = '',
        receiverEmail,
        emailTemplate = null;
    let printHtml = null;

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
        result.forEach(doc => {
            if (doc.row[0].email) {
                selectedDocs.push({...doc.row[0]});
            }
        })

    }).catch((err) => {
        console.error('catched error->', err);
        return res.send({status: 500, result: null, error_message: err});
    });

    // делаем массив промисов отправки почты
    const emailPromises = selectedDocs.map(async doc => {
        // вернуть отчет
        docNumber = doc.number ? doc.number : null;
        receiverEmail = doc.email ? doc.email : null;

        res.render('teatis_kaart', {data: [doc], user: user}, (err, html) => {
            printHtml = html;
        });

        const emailTemplateObject = emailTemplates.find(templ => templ.params === 'id');
        emailTemplate = emailTemplateObject.view;

        res.render(emailTemplate, {user: user}, (err, html) => {
            emailHtml = html;
        });

        //attachment
        let filePDF = await createPDF(printHtml, `doc_${doc.id}`);
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
                    subject: `Saadan dokument nr. ${doc.number}`, // Subject line
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
                                params = [doc.id, user.userId];

                            if (sql) {
                                db.queryDb(sql, params);
                            }
                        }


                        return resolve(doc.id);
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


};

exports.sendPrintForm = async (req, res) => {
    const params = req.body;
    let id = params.id || null; // параметр id документа

    const sqlWhere = params.sqlWhere || '';// параметр sqlWhere документа
    let filterData = []; // параметр filter документов;

    if (id && !sqlWhere) {
        // only 1 id
        id = Number(id);
    } else {
        try {
            if (id) {
                filterData = JSON.parse(id).filter(row => {
                    if (row.value) {
                        return row;
                    }
                });

            }

        } catch (e) {
            console.error('error', e);
        }
        id = null;
    }


    let subject = params.subject ? params.subject : null;
    let context = params.context ? params.context : null;
    let email = params.email ? params.email : null;

    const user = require('../middleware/userData')(req); // данные пользователя
    const module = params.module;
    let result = 0;

    // проверка ка пользователя
    if (!user) {
        console.error('error 401, no user');
        return res.status(401).end();
    }

    // проверим на наличие типа документа
    if (!email) {
        // нет документов для отправки
        return res.send({status: 200, result: null, error_message: `Puudub email aadress`});
    }

    if (!UserConfig.email) {
        await getConfigData(user);
    }

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

    // обрабатываем параметры

    let filePDF;
    let templateObject;
    if (params.docTypeId) {
        // передан тип документа , значит есть вложение, готовим файл
        // создать объект
        const doc = new Doc(params.docTypeId, id, user.userId, user.asutusId, module);

        const printTemplates = doc.config.print;

        let renderForm;

        if (printTemplates) {
            templateObject = printTemplates.find(templ => templ.params === (id ? 'id' : 'sqlWhere'));
            renderForm = templateObject.view;

            if (id && templateObject.register) {
                // если есть метод регистрации, отметим печать
                let sql = templateObject.register,
                    params = [id, user.userId];

                if (sql) {
                    db.queryDb(sql, params);
                }
            }
        }

        // вызвать метод
        const method = id ? 'select' : 'selectDocs';
        let gridParams;
        let limit = id ? 1 : 10000;

        if (method === 'selectDocs' && doc.config.grid.params && typeof doc.config.grid.params !== 'string') {
            gridParams = getParameterFromFilter(user.asutusId, user.userId, doc.config.grid.params, filterData);
        }

        let result = await doc[method]('', sqlWhere, limit, gridParams);

        let data = id ? {...result.row, ...result} : result.data;

        // groups
        if (templateObject.group) {
            //преобразуем данные по группам
            data = getGroupedData(data, templateObject.group);
        }

        let printHtml;

        // вернуть отчет
        res.render(renderForm, {data: data, user: user, filter: filterData}, (err, html) => {
            printHtml = html;
        });

        //attachment
        filePDF = await createPDF(printHtml, `doc_${Math.floor(Math.random() * 1000000)}`);
    }

    // sending email
    // send mail with defined transport object
    const attachment = filePDF ? [{
        filename: `doc.pdf`,
        content: 'Dokument ',
        path: filePDF
    }] : null;

    await transporter.sendMail({
        from: `"${user.userName}" <${UserConfig['email'].email}>`, //`${user.userName} <${config['email'].email}>`, // sender address
        to: email, // (, baz@example.com) list of receivers
        subject: subject, // Subject line
        text: context, // plain text body
        attachments: attachment

    }, async (err, info) => {
        if (err) {
            return reject(err);
        } else {
            result++;
            if (filePDF) {
                // удаляем файл
                await fs.unlink(filePDF, (err, data) => {
                    if (err) {
                        return reject(err);
                    }
                });
            }

            // register emailing event

            if (id && templateObject.register) {
                // если есть метод регистрации, отметим печать
                let sql = templateObject.register,
                    params = [id, user.userId];

                if (sql) {
                    await db.queryDb(sql, params);
                }
            }

        }
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