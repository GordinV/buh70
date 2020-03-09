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
    if (rows.length) {
        // сохраняем

        const params = [JSON.stringify(rows), user.id, user.asutusId];

        const result = await Document.executeTask('importViitenr', params).then((result) => {
                saved = result.result ? result.result : 0;
            }
        );

        return `Kokku leidsin ${rows.length} laste viitenumbrid, salvestatud kokku: ${saved}`;

    } else {
        return `Kokku leidsin 0 viitenumbrid, salvestatud kokku: 0`;

    }

};

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
            if (row[0] !== 'IK ученика') {

                rows.push({
                    isikukood: row[0],
                    viitenr: row[1],
                    asutus: row[2],
                    nimetus: row[3]
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

