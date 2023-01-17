const _ = require('lodash');
Userid = require('../models/userid');
const UserContext = require('./../frontend/user-context');

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

    if (userId && UserContext.users.length) {
        UserContext.users = _.reject(UserContext.users, (user) => {
            return user.uuid !== uuid;
        });
    }


    // log
    let message = `logout userId ${userId}, uuid ${uuid}`;
    log(message, 'info');

};