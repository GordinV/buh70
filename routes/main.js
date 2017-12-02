exports.get = function(req, res) {
    const user = require('middleware/userData')(req);
    res.render('frontpage', {"user":user});
};
