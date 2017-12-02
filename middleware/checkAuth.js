
module.exports = function(req, res, next) {
    if (!req.session.user) {
        console.error('checAuth', 401, 'Autoriseeerimise viga');
        return next(new Error(401,'Autoriseeerimise viga'));
    }
    next();
};