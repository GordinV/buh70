exports.get = function(req, res) {
    req.session.destroy();
    res.redirect('/login');

};

exports.post = function(req, res) {
    req.session.destroy();
    res.redirect('/login');
};