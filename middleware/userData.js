const _ = require('lodash');
const Userid = require('../models/userid');
const log = require('./../libs/log');


const userData = async function (req, _uuid) {
    let userId = req.body.userId,
        uuid = _uuid ? _uuid : req.body.uuid;

    if (!req.session.users) {
        // logs
        let message = `userData, !req.session.users userId -> ${userId},uuid -> ${uuid}`;
        log(message,'Error');

        return null;
    }
    let userIndex = _.findIndex(req.session.users, {uuid: uuid});

    if (!uuid && req.session.users) {
        // for get
        userIndex = 0;
    }

    let sqlUser = {
        userId: null,
        asutusId: null,
        kasutaja: null
    };

    if (userIndex < 0) {
        // потеряли хеш
        let uuidUser = await Userid.getUserByUuid(uuid);
        if (uuidUser && uuidUser.data) {
            sqlUser.userId = uuidUser.data[0].userid;
            sqlUser.asutusId = uuidUser.data[0].asutusid;
            sqlUser.kasutaja = uuidUser.data[0].kasutaja;
        }

        // logs
        let message = `userData, userIndex < 0 userId -> ${sqlUser.userId},asutusId -> ${sqlUser.asutusId}`;
        log(message,'info');

    }

    const user = Object.assign({
        userId: userIndex > -1 ? req.session.users[userIndex].id : sqlUser.userId,
        userName: userIndex > -1 ? req.session.users[userIndex].ametnik : sqlUser.kasutaja,
        asutus: userIndex > -1 ? req.session.users[userIndex].asutus : null,
        asutusTais: userIndex > -1 ? req.session.users[userIndex].asutus_tais : null,
        regkood: userIndex > -1 ? req.session.users[userIndex].regkood : null,
        asutusId: userIndex > -1 ? req.session.users[userIndex].rekvid : sqlUser.asutusId,
        lastLogin: userIndex > -1 ? req.session.users[userIndex].last_login : null,
        userAccessList: userIndex > -1 ? req.session.users[userIndex].userAllowedAsutused : [],
        userLibraryList: [],
        parentid: userIndex > -1 && req.session.users[userIndex].parentid ? req.session.users[userIndex].parentid : 0,
        parent_asutus: userIndex > -1 && req.session.users[userIndex].parent_asutus,
        login: userIndex > -1 ? req.session.users[userIndex].kasutaja : sqlUser.kasutaja,
        roles: userIndex > -1 && req.session.users[userIndex].roles
    }, userIndex > -1 ? req.session.users[userIndex] : {});

    return user;
};

module.exports = userData;