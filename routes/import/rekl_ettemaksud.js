import_ettemaksud();

async function import_ettemaksud() {
    const fs = require('fs');
    const path = 'c:/temp/csv/ettemaks_2.csv';
    const util = require('util');

// Convert fs.readFile into Promise version of same
    const readFile = util.promisify(fs.readFile);

    let l_file = await readFile(path, {encoding: 'utf8'});
    await readCSV(l_file);

}
const readCSV = async (csvContent, cb) => {
    const db = require('./../../libs/db');

    const parse = require('csv-parse');
    const rows = [];
    // Create the parser
    const fileContent = await parse(csvContent, {headers: false, delimiter: ';', columns: false}, (err, output) => {
        result = output;
        if (err) {
            console.error(err);
            return null;
        }

        output.forEach(row => {
            // проверим на заголовок
            if (isNumber(row[0]) && Number(row[2]) !== 0) {
                rows.push({
                    konto: row[0],
                    regkood: row[1],
                    summa: row[2]
                });
            }

        });
        if (rows.length) {
            // сохраняем

            const params = [JSON.stringify(rows)];
            console.log('params', params);
            let sql = `SELECT *
                   FROM import_ettemaksud_from_data($1::JSONB, '2020-09-30'::date)`;

            db.queryDb(sql, params).then(returnValue => {
                console.log('tulemus->', returnValue);

            });
        }

    });
//    return rows;
};

function isNumber(val) {
    // negative or positive
    return /^[-]?\d+$/.test(val);
}

