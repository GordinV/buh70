'use strict';
const db = require('./../libs/db');
const pdf = require('html-pdf');
const jade = require('jade');
const nodemailer = require('nodemailer');
const util = require('util');
const fs = require('fs');
const config = require('../config/default');


const PATH_TO_PDF = './public/pdf/doc.pdf';

const Doc = require('./../classes/DocumentTemplate');

const UserConfig = {};

const createPDF = async function createFile(html, fileName='doc') {
    let options = {
        filename: `./public/pdf/${fileName}.pdf`,
        format: 'Legal',
        "base": `http://localhost:${config.port}`
    };

    let create = util.promisify(pdf.create);
    let filename = options.filename;

    try {
        let creator = await create(html, options);
    } catch (e) {
        console.error ('create pdf error', e);
        filename = null;
    }
    return filename;
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
        return res.send({status: 200, result: null, error_message: `Valitud lapsed ei leidnud`});
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

        res.render('arve_kaartid', {data: [arve], user: user}, (err, html) => {
            printHtml = html;
        });

        const emailTemplateObject = emailTemplates.find(templ => templ.params === 'id' );
        emailTemplate = emailTemplateObject.view;

        res.render(emailTemplate, {user: user}, (err, html) => {
            emailHtml = html;
        });

        //attachment
        let filePDF = await createPDF(printHtml,`${arve.id}`);
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
                        await fs.unlink(filePDF,(err,data) => {
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
        console.error('promiseEmailResult',err);
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