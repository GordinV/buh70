const _ = require('lodash');

module.exports = function(req, res, next) {
    const userId = req.body.userId;
    const uuid = req.body.uuid;
    let result = 0;

    if (!uuid && req.session.users.length > 0) {
        // get
        return next();
    }

    if (uuid && req.session.users) {
        let users = req.session.users;
        result = _.findIndex(users,{uuid:uuid});
        if (result < 0 || !req.session.users.length ) {
            let uuids = req.session.users.map((user) => {
                return {uuid: user.uuid, ametnik: user.ametnik }
            });
            console.error('No users in session object found', uuid,  uuids, req.session.users.length, result);
            res.status(401);
        }
    }
    next();

};