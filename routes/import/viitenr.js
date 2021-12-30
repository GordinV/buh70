module.exports = async (file, mimeType, user) => {
    let rows = [];
    try {
        rows = await readCSV(file);
    } catch (e) {
        console.error('Viga:', e);
        return `Viga, salvestatud kokku: 0`;
    }
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('LAPS', null, user.userId, user.asutusId, 'lapsed');

    let saved = 0;
    let returnData = [];
    if (rows.length) {
        // сохраняем

        const params = [JSON.stringify(rows), user.id, user.asutusId];

        const result = await Document.executeTask('importViitenr', params).then((result) => {
                saved = result.result ? result.result : 0;
                if (result && result.data && result.data.length) {
                    result.data = result.data.map(row => {
                        return {
                            kas_vigane: row.id ? false: true,
                            error_message: row.isikukood + ' ' + row.status,
                            viitenr: row.viitenr
                        }
                    })
                }
                returnData = result && result.data && result.data.length ? result : [];
            }
        );
        return {
            error_message: `Kokku leidsin ${rows.length}  laste viitenumbrid, salvestatud kokku: ${saved}`,
            result: saved,
            data: returnData
        };
//        return `Kokku leidsin ${rows.length} laste viitenumbrid, salvestatud kokku: ${saved}`;

    } else {
        return {
            error_message: `Kokku leidsin 0 viitenumbrid, salvestatud kokku: 0`,
            result: saved,
            data: []
        };

    }

};

const readCSV = (csvContent) => {
    const parse = require('csv-parse');
    const rows = [];
    // Create the parser
    return new Promise(function (resolve, reject) {
        const fileContent = parse(csvContent, {headers: false, delimiter: ';', columns: false}, (err, output) => {
            result = output;
            if (err) {
                console.error(err);
                return null;
            }

            output.forEach(row => {
                // проверим на заголовок
                if (row[0] !== 'IK ученика') {

                    rows.push({
                        isikukood: row[0],
                        viitenr: row[1],
                        asutus: row[2],
                        nimetus: row[3]
                    });
                }

            });
            resolve(rows);

        });
    });
};

function isNumber(val) {
    // negative or positive
    return /^[-]?\d+$/.test(val);
}

