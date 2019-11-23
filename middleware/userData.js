const _ = require('lodash');

const userData = function (req, _uuid) {
    let userId = req.body.userId,
        uuid = _uuid ? _uuid : req.body.uuid;

    if (!req.session.users) {
        return null;
    }
    let userIndex = _.findIndex(req.session.users, {uuid: uuid});

    if (!uuid && req.session.users) {
        // for get
        userIndex = 0;
    }

    const user = Object.assign({
        userId: userIndex > -1 ? req.session.users[userIndex].id : null,
        userName: userIndex > -1 ? req.session.users[userIndex].ametnik : null,
        asutus: userIndex > -1 ? req.session.users[userIndex].asutus : null,
        asutusTais: userIndex > -1 ? req.session.users[userIndex].asutus_tais : null,
        regkood: userIndex > -1 ? req.session.users[userIndex].regkood : null,
        asutusId: userIndex > -1 ? req.session.users[userIndex].rekvid : null,
        lastLogin: userIndex > -1 ? req.session.users[userIndex].last_login : null,
        userAccessList: userIndex > -1 ? req.session.users[userIndex].userAllowedAsutused : [],
        userLibraryList: [],
        parentid: req.session.users[userIndex].parentid,
        parent_asutus: req.session.users[userIndex].parent_asutus,
        login: userIndex > -1 ? req.session.users[userIndex].kasutaja : null
    }, userIndex > -1 ? req.session.users[userIndex] : {});

    return user;
};

module.exports = userData;