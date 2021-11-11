const _ = require('lodash');
Userid = require('../models/userid');

const log = require('./../libs/log');

exports.get = function(req, res) {
// удалим  из таблицы данные сессии
    let uuid = req.body.uuid;
    Userid.deleteUserUuid(uuid);

    // log
    let message = `logout uuid${uuid}`;
    log(message, 'info');


    req.session.destroy();
    res.redirect('/login');

};

exports.post = function(req, res) {
    const userId = req.body.userId,
        uuid = req.body.uuid;
// удалим  из таблицы данные сессии

    Userid.deleteUserUuid(uuid);

    if (userId && req.session.users.length) {
        req.session.users = _.reject(req.session.users, (user) => {
            return user.uuid !== uuid;
        });
    }

    if (!userId || !req.session.users || req.session.users.length < 1) {
        req.session.destroy();
    }

    // log
    let message = `logout userId ${userId}, uuid ${uuid}`;
    log(message, 'info');

};