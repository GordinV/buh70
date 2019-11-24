'use strict';

exports.post = async (req, res) => {

    let user = require('../middleware/userData')(req); // данные пользователя
    const db = require('./../libs/db');
    const menuModel = require('./../models/ou/start-menu');
    let module = req.params.module;

    const sqlString = menuModel.sqlString,
        params = [module];

    try {
        if (!user) {
            console.error('No user, set status to 401');
            return res.status(401).send('Error');
        }

        let data = await db.queryDb(sqlString, params);
        // вернуть данные
        res.status(200).send(data);
    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }
};