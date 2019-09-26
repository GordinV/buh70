const _ = require('lodash');

exports.get = function(req, res) {
    req.session.destroy();
    res.redirect('/login');

};

exports.post = function(req, res) {
    const userId = req.body.userId,
        uuid = req.body.uuid;

    if (userId && req.session.users.length) {
        req.session.users = _.reject(req.session.users, (user) => {
            return user.uuid !== uuid;
        });
    }

    if (!userId || !req.session.users || req.session.users.length < 1) {
        req.session.destroy();
    }

};