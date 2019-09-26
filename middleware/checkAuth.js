const _ = require('lodash');

module.exports = function(req, res, next) {
    const userId = req.body.userId;
    let result = 0;

    if (!userId && req.session.users.length > 0) {
        // get
        return next();
    }

    if (userId && req.session.users) {
        let users = req.session.users;
        result = _.findIndex(users,{id:userId});
        if (!result || !req.session.users.length ) {
            res.status(401);
        }
    }
    next();

};