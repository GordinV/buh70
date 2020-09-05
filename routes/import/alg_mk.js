import_algsaldo();

async function import_algsaldo() {
    const fs = require('fs');
    const path = 'c:/temp/csv/Alg_kr_5.csv';
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
            if (isNumber(row[0])) {
                console.log('insert', row[0]);
                rows.push({
                    yksus: row[0],
                    laps_ik: row[1],
                    vanem_ik: row[2],
                    summa: row[3],
                    kr: row[5],
                    kood: row[6],
                    konto: row[8]
                });
            }

        });
        if (rows.length) {
            // сохраняем

            const params = [JSON.stringify(rows), 70, 1];
            let sql = `SELECT error_code, result, error_message
                   FROM lapsed.import_alg_saldo_kreedit($1::JSONB, $2::INTEGER, $3::INTEGER)`;

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

