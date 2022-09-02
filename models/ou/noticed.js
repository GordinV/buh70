module.exports = {
    sqlString: `SELECT DISTINCT task_name, teatis, timestamp
                FROM ou.noticed n
                WHERE status = 1
                  AND userid = $1
                ORDER BY timestamp DESC`,
    params: ['userId'], // $1 userId
    updateString: `UPDATE ou.noticed n
                   SET status = 2
                   WHERE status = 1
                     AND userid = $1`,
    params: ['userId'] // $1 userId

};
