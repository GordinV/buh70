
module.exports = function(req, res, next) {
    if (!req.session.user) {
        console.error('checAuth. ', 401, 'Autoriseeerimise viga', req.session);
        new Error(401,'Autoriseeerimise viga');
        res.status(401).redirect('/login');
    }
    next();
};