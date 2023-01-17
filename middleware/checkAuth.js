const _ = require('lodash');
const log = require('./../libs/log');
const UserContext = require('./../frontend/user-context');

module.exports = async function (req, res, next) {
    const userId = req.body.userId;
    const uuid = req.body.uuid;
    const user = await require('../middleware/userData')(req);
    let result = 0;

    if (!uuid &&  UserContext.users && UserContext.users.length > 0) {
        // logs
        let message = `Auth, !uuid && UserContext.users.length > 0 -> ${userId},uuid -> ${uuid}`;
        log(message,'info');

        // get
        return next();
    }

    if (!user) {
        // logs
        let message = `Auth, !user userId -> ${userId},uuid -> ${uuid}`;
        log(message,'error');

        res.statusCode = 401;
        res.redirect('/login');
    }

    next();

};