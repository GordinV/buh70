'use strict';

exports.post = async (req, res) => {
    const user = require('../middleware/userData')(req); // данные пользователя
        const db = require('./../libs/db');
        const menuModel = require('./../models/start-menu');

        const sqlString = menuModel.sqlString,
            params = [1];
    try {

        let data =  await db.queryDb(sqlString,params);
        // вернуть данные
        res.send(data);
    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({result:'Error'});

    }
};