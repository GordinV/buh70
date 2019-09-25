
module.exports = function(req, res, next) {
    if (!req.session.user) {
        const error = new Error(401,'Autoriseeerimise viga');
        res.status(401);
    }
    next();
};