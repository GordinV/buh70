module.exports = async (file, mimeType, user) => {
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('LAPSE_KAART', null, user.userId, user.asutusId, 'lapsed');

    let rows = [];

    try {
        rows = await readCSV(file);
    } catch
        (e) {
        console.error('Viga:', e);
        return `Tekkis viga, vale formaat`;
    }
    let saved = 0;
    if (rows.length) {
        // сохраняем

        const params = [JSON.stringify(rows), user.id, user.asutusId];
        const result = await Document.executeTask('importTeenused', params);
        
        saved = result.result ? result.result : 0;

        return `Kokku leidsin ${rows.length} teenused, salvestatud kokku: ${saved}`;

    } else {
        return `Kokku leidsin 0 teenused, salvestatud kokku: 0`;

    }
}
;

const readCSV = (csvContent) => {
    const parse = require('csv-parse');
    const rows = [];
    return new Promise(function (resolve, reject) {
        // Create the parser
        const fileContent = parse(csvContent, {headers: false, delimiter: ';', columns: false}, (err, output) => {
            if (err) {
                console.error(err);
                return null;
            }

            output.forEach(row => {
                // проверим на заголовок
                if (isNumber(row[0])) {
                    rows.push({
                        isikukood: row[0],
                        yksus: row[1],
                        kood: row[3],
                        hind: row[4],
                        kogus: row[5],
                        kuu: row[6],
                        aasta: row[7],
                        lopp_kpv: row[8],
                        kas_ettemaks: row[9],
                        ettemaksu_period: row[10],
                        kas_eraldi: row[11],
                        kas_inf3: row[12],
                        soodus: row[13],
                        sooduse_alg: row[14],
                        sooduse_lopp: row[15],
                        kas_protsent: row[16]
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

