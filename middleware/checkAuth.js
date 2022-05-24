const _ = require('lodash');
const log = require('./../libs/log');

module.exports = async function (req, res, next) {
    const userId = req.body.userId;
    const uuid = req.body.uuid;
    const user = await require('../middleware/userData')(req);
    let result = 0;

    if (!uuid &&  req.session.users && req.session.users.length > 0) {
        // logs
        let message = `Auth, !uuid && req.session.users.length > 0 -> ${userId},uuid -> ${uuid}`;
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