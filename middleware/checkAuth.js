
module.exports = function(req, res, next) {
    if (!req.session.user) {
        console.error('checAuth. ', 401, 'Autoriseeerimise viga', req.session);
//        res.render('error', {"message": 'Autoriseeerimise viga'});
//        res.redirect('./login');
//        new Error(401,'Autoriseeerimise viga');

        res.writeHead(401 , {
            'Location' : './login' // This is your url which you want
        });
        res.end();
    }
    next();
};