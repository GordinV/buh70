'use strict';
const db = require('./../libs/db');
const path = require('path');
const nodemailer = require('nodemailer');
const fs = require('fs');
const l_mail_user = 'Admin';
const DocContext = require('./../frontend/doc-context');

exports.get = async (req, res) => {
    let kasutaja = req.params.kasutaja || ''; // параметр пользователя
    let access_code = req.params.access_code || ''; // параметр код доступа

    if (!kasutaja || !access_code) {
        console.error('error 401');
        return res.status(401).end();
    }

    if (!DocContext.acceptAccessCode(kasutaja, access_code)) {
        return res.status(401).send('Viga, vale kood');
    }

    let l_file = './routes/ssl/cert1.zip';
    if (!l_file) {
        return res.status(500).send('Viga, puudub sertifikaat');
    }

    try {

        const stream = await fs.createReadStream(l_file);

        res.setHeader('Content-disposition', 'inline; filename="cert.zip"');
        res.setHeader('Content-type', 'application/zip');

        stream.pipe(res);
        res.end();

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }

};

exports.post = async (req, res) => {
    const params = req.body;

    if (!params) {
        // error in parameters
        console.error('Viga, puudub kasutaja tunnus');
        return res.status(500).send('Viga: puudub kasutaja tunnus')
    }

    send_access_code(params);

    async function send_access_code(params) {
        if (!params || !params.kasutaja) {
            // параметры не переданы
//        return res.send(`Puudub parameter kasutaja`);
            console.error(`Puudub parameter kasutaja`);
        }

        let l_kasutaja = params.kasutaja;

        // уточняем модуль
        let l_module = 'Eelarve 7.0';

        if (params.module) {
            l_module = params.module;
        }


        // ищем конфигурацию
        if (l_module == 'Eelarve 7.0') {
            var config = require('./../config/narvalv.json');
//            config.pg.connection = "postgres://vlad:Vlad490710@localhost:5432/narvalv"
        } else {
            var config = require('../config/default');
        }

        config = require('../config/default');

        var l_smtp;
        var l_port = 465;
        var l_user;
        var l_user_name;
        var l_user_mail = 'palk@narva.ee';
        var l_pass;
        var l_kasutaja_mail;
        var l_kinnitus_kood = DocContext.getAccessCode(l_kasutaja);

        let l_sql = `SELECT  u.properties ->> 'smtp' AS smtp,
                    u.properties ->> 'port' AS port,
                    u.properties ->> 'pass' AS pass,
                    ltrim(rtrim(u.kasutaja)) AS user_name,       
                    uu.properties->>'email' AS email
                    FROM ou.userid u, ou.userid uu
                    WHERE u.ametnik = '${l_mail_user}'
                      AND uu.kasutaja = '${l_kasutaja}' AND uu.properties->>'email' IS NOT NULL
                    ORDER BY u.id DESC LIMIT 1`;

        let data = await db.queryDb(l_sql, null, null, null, null, null, config);

        if (!data || !data.result || !data.data.length) {
            console.error('Puudub email aadress', config);
            return res.status(500).send('Viag, Puudub email aadress');
        }


        l_smtp = data.data[0].smtp;
        l_port = data.data[0].port;
        l_pass = data.data[0].pass;
        l_user_name = data.data[0].user_name;
        l_kasutaja_mail = data.data[0].email;

        // create reusable transporter object using the default SMTP transport

        let transporter = nodemailer.createTransport({
            host: l_smtp,
            port: l_port,
            secure: l_port == 465, // true for 465, false for other ports
            auth: {
                user: l_user_name,
                pass: l_pass
            }
        });

//  send email
        let message = `Kinnistus kood ${l_kinnitus_kood}`;

        transporter.sendMail({
            from: `"${l_user_name}" <${l_user_mail}>`, //`${user.userName} <${config['email'].email}>`, // sender address
            to: `${l_kasutaja_mail}`, // (, baz@example.com) list of receivers
            subject: `Kinnistus kood, ${l_kasutaja}`, // Subject line
            text: message, // plain text body
        });
        return res.send('Kood saadetud');

    }
};
