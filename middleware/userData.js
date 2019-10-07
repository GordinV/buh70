const _ = require('lodash');

const userData = function (req) {
    let userId = req.body.userId,
        uuid = req.body.uuid;

    if (!req.session.users) {
        return null;
    }
//    let userIndex = _.findIndex(req.session.users, {id: userId});
    let userIndex = _.findIndex(req.session.users, {uuid: uuid});

    if (!uuid && req.session.users) {
        // for get
        userIndex = 0;
    }

    const user = Object.assign({
        userId: userIndex > -1 ? req.session.users[userIndex].id: null,
        userName: userIndex > -1 ? req.session.users[userIndex].ametnik: null,
        asutus: userIndex > -1 ? req.session.users[userIndex].asutus: null,
        asutusId: userIndex > -1 ? req.session.users[userIndex].rekvid: null,
        lastLogin: userIndex > -1 ? req.session.users[userIndex].last_login: null,
        userAccessList: userIndex > -1 ? req.session.users[userIndex].userAllowedAsutused: [],
        userLibraryList: [],
        login: userIndex > -1 ? req.session.users[userIndex].kasutaja: null
    }, userIndex > -1 ? req.session.users[userIndex] : {});

    return user;
};

module.exports = userData;