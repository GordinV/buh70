'use strict';
const db = require('./../libs/db');
const pdf = require('html-pdf');
const jade = require('jade');
const nodemailer = require('nodemailer');
const util = require('util');

const Doc = require('./../classes/DocumentTemplate');

const UserConfig = {};

const createPDF = async function createFile(html) {
    let options = {
        filename: './public/pdf/doc.pdf',
        format: 'Legal',
        "base": "http://localhost:3000"
    };

    let create = util.promisify(pdf.create);
    let creator = await create(html, options);
};

const getConfigData = async function (user) {
    const docConfig = new Doc('config', user.asutusId, user.userId, user.asutusId, 'lapsed');
    const configData = await docConfig.select();
    UserConfig.email = {...configData.row[0]};

};

exports.get = async (req, res) => {
    const id = Number(req.params.id || 0); // параметр id документа
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const docTypeId = req.params.documentType || ''; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../middleware/userData')(req, uuid); // данные пользователя


    const limit = 1000;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    if (!UserConfig.email) {
         await getConfigData(user);
    }
/*
    const docConfig = new Doc('config', user.asutusId, user.userId, user.asutusId, 'lapsed');
    const configData = await docConfig.select();
    config.email = {...configData.row[0]};
*/
    //for test

    UserConfig.email = {
        smtp: 'smtp.gmail.com',
        port: 465,
        user: 'vladislav.gordin@gmail.com',
        pass: 'Vlad490710A',
        email: 'vladislav.gordin@gmail.com'
    };

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


    // создаем вложение
    // создать объект
    const doc = new Doc(docTypeId, (id ? id : null), user.userId, user.asutusId, 'lapsed');

    const printTemplates = doc.config.print;
    const emailTemplates = doc.config.email;

    let template = null,
        emailHtml = null,
        attachment,
        docNumber = '',
        receiverEmail,
        emailTemplate = null;
    let printHtml = null;


    if (printTemplates) {

        const templateObject = printTemplates.find(templ => templ.params === (id ? 'id' : 'sqlWhere'));
        template = templateObject.view;

        // вызвать метод
        const method = id ? 'select' : 'selectDocs';
        let result = await doc[method]('', sqlWhere, limit);
        const data = id ? {...result.row, ...result} : result.data;
        // вернуть отчет
        docNumber = data[0].number ? data[0].number : null;
        receiverEmail = data[0].email ? data[0].email : null;

        res.render(template, {data: data, user: user}, (err, html) => {
            printHtml = html;
        });

    }

    if (emailTemplates) {
        const emailTemplateObject = emailTemplates.find(templ => templ.params === (id ? 'id' : 'sqlWhere'));
        emailTemplate = emailTemplateObject.view;

        // register emailing event
        if (id && emailTemplateObject.register) {
            // если есть метод регистрации, отметим email
            let sql = emailTemplateObject.register,
                params = [id, user.userId];

            if (sql) {
                db.queryDb(sql, params);
            }
        }
        res.render(emailTemplate, {user: user}, (err, html) => {
            emailHtml = html;
        });
    }


    //attachment
    let filePDF = await createPDF(printHtml);

    if (!receiverEmail) {
        return res.send({status: 500, error_message: 'No email address'})
    }

    // sending email

    // send mail with defined transport object
    transporter.sendMail({
        from: `"${user.userName}" <${UserConfig['email'].email}>`, //`${user.userName} <${config['email'].email}>`, // sender address
        to: `${receiverEmail}`, // (, baz@example.com) list of receivers
        subject: `Saadan dokument nr. ${docNumber}`, // Subject line
        text: 'Automaat e-mail', // plain text body
        html: emailHtml, // html body
        attachments: [
            // String attachment
            {
                filename: 'doc.pdf',
                content: 'Dokument ',
                path: './public/pdf/doc.pdf'
            }]

    }, (err, data) => {
        if (err) {
            console.error(err);
            res.send({status: 401, result: err});
            return err;
        }
        res.send({status: 200, result: 'Ok'});
    });


};

exports.post = async (req, res) => {
    const params = req.body;
    const id = Number(params.docId || 0); // параметр id документа
    const user = require('../middleware/userData')(req); // данные пользователя
    const module = req.body.module;
    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
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


    // создаем вложение
    // создать объект
    const emailDoc = new Doc(params.docTypeId, params.docId, user.userId, user.asutusId, module);

    const printTemplates = emailDoc.config.print;
    const emailTemplates = emailDoc.config.email;

    let template = null,
        emailHtml = null,
        attachment,
        docNumber = '',
        receiverEmail,
        emailTemplate = null;
    let printHtml = null;


    if (printTemplates) {

        const templateObject = printTemplates.find(templ => templ.params === (id ? 'id' : 'sqlWhere'));
        template = templateObject.view;

        // вызвать метод
        let docConfig =  emailDoc.config;
        let result = await emailDoc['select'](docConfig);

        const data = {...result.row, ...result};

        // вернуть отчет
        docNumber = data[0].number ? data[0].number : null;
        receiverEmail = data[0].email ? data[0].email : null;

        res.render(template, {data: data, user: user}, (err, html) => {
            printHtml = html;
        });

    }

    if (emailTemplates) {
        const emailTemplateObject = emailTemplates.find(templ => templ.params === (id ? 'id' : 'sqlWhere'));
        emailTemplate = emailTemplateObject.view;

        // register emailing event
        if (id && emailTemplateObject.register) {
            // если есть метод регистрации, отметим email
            let sql = emailTemplateObject.register,
                params = [id, user.userId];

            if (sql) {
                db.queryDb(sql, params);
            }
        }
        res.render(emailTemplate, {user: user}, (err, html) => {
            emailHtml = html;
        });
    }


    //attachment
    let filePDF = await createPDF(printHtml);

    if (!receiverEmail) {
        return res.send({status: 500, error_message: 'No email address'})
    }

    // sending email

    // send mail with defined transport object
    transporter.sendMail({
        from: `"${user.userName}" <${UserConfig['email'].email}>`, //`${user.userName} <${config['email'].email}>`, // sender address
        to: `${receiverEmail}`, // (, baz@example.com) list of receivers
        subject: `Saadan dokument nr. ${docNumber}`, // Subject line
        text: 'Automaat e-mail', // plain text body
        html: emailHtml, // html body
        attachments: [
            // String attachment
            {
                filename: 'doc.pdf',
                content: 'Dokument ',
                path: './public/pdf/doc.pdf'
            }]

    }, (err, data) => {
        if (err) {
            console.error(err);
            res.send({status: 401, result: err});
            return err;
        }
        res.send({status: 200, result: 'Ok'});
    });


};
