// doc library model
'use strict';

module.exports = {
    documentLibrary: [
    {
     id: 1,
     name: 'Arved'
    },
    {
    id: 2,
    name: 'Palk'
    },
    {
    id:3,
    name: 'Lausendid'
    }
    ],
    connectDb: function() {
        const pg = require('pg'),
            config = require('../config/config');
        return new pg.Client(config.pg.connection);
    }

/*
    getLibrary: function(rekvId, lib, callback) {
        // возвращает список библиотек заданого типа
        const db = this.connectDb();

        db.connect(function (err) {
            if (err) {
                return console.error('could not connect to postgres', err);
            }
            db.query(`select * from library l where $1 = 0 or l.rekvid = $1 dok = $2 order by l.kood`,
                [rekvId, lib],  (err, result) => {
                if (err) {
                    console.error(err);
                    return callback(err);

                }
                db.end();
                callback(err, result);
            });
        });

    }

*/
};

