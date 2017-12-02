'use strict';
exports.get = (req, res) => {
    // check for userid in session
    const user = require('middleware/userData')(req);
    res.render('frontpage', {"user":user});
};