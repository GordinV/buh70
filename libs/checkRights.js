// will check rights for action

const checkRights = (userRoles, docRights, action) => {
    let is_accepted = false;
    if (docRights[action]) {
        docRights[action].forEach(role => {
            // raamatupidajad
            is_accepted = userRoles && userRoles.is_kasutaja && role == 'kasutaja' ? true : is_accepted;

            if (!is_accepted) {
                is_accepted = userRoles && userRoles.is_peakasutaja && role == 'peakasutaja' ? true : is_accepted;
            }

            // arvestajad
            if (!is_accepted) {
                is_accepted = userRoles && userRoles.is_arvestaja && role == 'arvestaja' ? true : is_accepted;
            }

            // adminid
            if (!is_accepted) {
                is_accepted = userRoles && userRoles.is_admin && role == 'admin' ? true : is_accepted;
            }

        });
    } else {
        // если нет ограничений
        is_accepted = true;
    }
    return is_accepted;
};
module.exports = checkRights;