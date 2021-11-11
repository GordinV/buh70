const _ = require('lodash');

module.exports = async function (req, res, next) {
    const userId = req.body.userId;
    const uuid = req.body.uuid;
    const user = await require('../middleware/userData')(req);
    let result = 0;

    if (!uuid && req.session.users.length > 0) {
        // get
        return next();
    }

    if (!user) {
        res.statusCode = 401;
        res.redirect('/login');
    }

    next();

};