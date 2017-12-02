module.exports = function(req, res, next) {
//    console.log('sendHttpError', arguments);

 res.sendHttpError = function(error) {
        res.status(error.status);
        if (res.req.headers['x-requested-with'] == 'XMLHttpRequest') {
            res.json(error);
        } else {
            res.render('error', {"message": error.message});
        }
    };
    next();

};
