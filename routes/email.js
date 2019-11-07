'use strict';
const db = require('./../libs/db');
const pdf = require('html-pdf');
const jade = require('jade');
const nodemailer = require('nodemailer');
const Doc = require('./../classes/DocumentTemplate');

const config = {};

exports.get = async (req, res) => {
    const id = Number(req.params.id || 0); // параметр id документа
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const docTypeId = req.params.documentType || ''; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../middleware/userData')(req, uuid); // данные пользователя

    let template = docTypeId; // jade template
    const limit = 1000;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    if (!config) {
        const docConfig = new Doc('config', user.asutusId, user.userId, user.asutusId, 'lapsed');
        const configData = await docConfig.select();
        config.email = {...configData.row[0]};
        console.log('config',config);
    }

 /*   if (!config.user) {
        let testAccount = await nodemailer.createTestAccount();
        console.log('testAccount',testAccount);
    }
*/
    // create reusable transporter object using the default SMTP transport
    let transporter = nodemailer.createTransport({
        host: config['email'].smtp,
        port: config['email'].port,
        secure: config['email'].port == 465 ? true: false, // true for 465, false for other ports
        auth: {
            user: config['email'].user,
            pass: config['email'].pass
        }
    });


    // создаем вложение
    try {
        // создать объект
        const doc = new Doc(docTypeId, (id ? id : null), user.userId, user.asutusId, 'lapsed');

        const printTemplates = doc.config.print;

        if (printTemplates) {
            const templateObject = printTemplates.find(templ => templ.params === (id ? 'id' : 'sqlWhere'));
            template = templateObject.view;

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
        let result = await doc[method]('', sqlWhere, limit);
        const data = id ? {...result.row, ...result} : result.data;
        // вернуть отчет

        const html = jade.render(template, {title: 'Tunnused', data: data, user: user});


        res.render(template, {title: 'PDF print', data: data, user: user}, (err, html) => {
                pdf.create(html, {format: 'Legal', "base": "http://localhost:3000" }).toFile('./public/pdf/doc.pdf',(err, data) => {
                    if (err) return res.end(err.stack);
                // sending email

                    // send mail with defined transport object
                    transporter.sendMail({
                        from: '"VG" <vladislav.gordin@bs2.ee>', // sender address
                        to: 'vladislav.gordin@gmail.com', // (, baz@example.com) list of receivers
                        subject: 'Test', // Subject line
                        text: 'Hello world with test account?', // plain text body
                        html: '<b>Hello world?</b>' // html body
                    },(err, data) => {
                        if (err) {
                            console.error(err);
                            res.send({status: 401, result: err});
                            return err;
                        }
                        console.log('sent', data);
                        res.send({status: 200, result: 'Ok'});
                    });


                });

            }
        );

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }
};
