const _ = require('lodash');
const log = require('./../libs/log');
const UserContext = require('./../frontend/user-context');

module.exports = async function (req, res, next) {
    const userId = req.body.userId;
    const uuid = req.body.uuid;
    const user = await require('../middleware/userData')(req);
    let result = 0;

    if (userId && user && user.userId && userId !== user.userId) {

        console.error('Auth, parametrid puuduvad', userId, uuid, user);
        // ошибка
        res.statusCode = 401;
        return res.redirect('/login');
    }

    if (!uuid && (user && user.userId || UserContext.users && UserContext.users.length > 0)) {
        // logs
        let message = `Auth, !uuid && UserContext.users.length > 0 -> ${userId},uuid -> ${uuid} user.userId->> ${user.userId}`;
        log(message,'info');

        // get
        return next();
    }

    if (!user || !user.userId) {
        // logs
        let message = `Auth, !user userId -> ${user.userId},uuid -> ${uuid}`;
        log(message,'error');

        res.statusCode = 401;
        return res.redirect('/login');
    }

    next();

};