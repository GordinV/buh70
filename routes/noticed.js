'use strict';

exports.post = async (req, res) => {
    let user = await require('../middleware/userData')(req); // данные пользователя
    const db = require('./../libs/db');
    const noticeModel = require('./../models/ou/noticed');
    const action = req.body.action || 'select';
    let userId = req.body.userId;

    const sqlString = action === 'select' ?  noticeModel.sqlString: noticeModel.updateString,
        params = [userId];

    console.log('sqlStringv',sqlString, params);

    try {
        if (!user) {
            console.error('No user, set status to 401');
            return res.status(401).send('Error');
        }

        let data = await db.queryDb(sqlString, params);
        // вернуть данные
        console.log('notice data', data);
        res.status(200).send(data);
    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }
};