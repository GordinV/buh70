module.exports = async (file, mimeType, user) => {
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('LAPSE_TAABEL', null, user.userId, user.asutusId, 'lapsed');

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
        console.log('save', params);
        const result = await Document.executeTask('importTaabel', params).then((result) => {
                saved = result.result ? result.result : 0;
            }
        );

        return `Kokku leidsin ${rows.length} teenused, salvestatud kokku: ${saved}`;

    } else {
        return `Kokku leidsin 0 teenused, salvestatud kokku: 0`;

    }
}
;

const readCSV = async (csvContent) => {
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
                rows.push({
                    isikukood: row[0],
                    yksus: row[1],
                    kood: row[2],
                    hind: row[3],
                    kogus: row[4],
                    kuu: row[5],
                    aasta: row[6]
                });
            }
        });
    });
    return rows;
};

function isNumber(val) {
    // negative or positive
    return /^[-]?\d+$/.test(val);
}

