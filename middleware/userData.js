var userData = function(req) {
    var user = {
            userId:null,
            userName: '',
            asutus: '',
            asutusId:null,
            lastLogin:null,
            userAccessList:null,
            userLibraryList:null,
            login:''
        };

    if (req.session.user) {
        user.userId = req.session.user.id;
        user.userName = req.session.user.userName;
        user.asutus = req.session.user.userAsutus;
        user.asutusId = req.session.user.userAsutusId;
        user.lastLogin = req.session.user.userLastLogin;
        user.userAccessList = req.session.user.userAccessList;
        user.userLibraryList = req.session.user.userLibraryList;
        user.login= req.session.user.login;

        global.rekvId = user.asutusId;
        global.userId = user.userId;

    } else {
        user = null;
        global.rekvId = null;
        global.userId = null;
    }
    return user;
}

module.exports = userData;