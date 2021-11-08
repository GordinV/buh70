module.exports = async (file, mimeType, user) => {
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('LAPSE_TAABEL', null, user.userId, user.asutusId, 'lapsed');
    const parse = require('csv-parse');

    let rowsToImport = [];
    try {
        rowsToImport = await readCSV(file);
    } catch
        (e) {
        console.error('Viga:', e);
        return `Tekkis viga, vale formaat`;
    }
    let saved = 0;
    if (rowsToImport.length) {
        // сохраняем
        const params = [JSON.stringify(rowsToImport), user.id, user.asutusId];
        const result = await Document.executeTask('importTaabel', params);
        saved = result.result ? result.result : 0;
        return `Kokku leidsin ${rowsToImport.length} teenused, salvestatud kokku: ${saved}`;

    } else {
        return `Kokku leidsin 0 teenused, salvestatud kokku: 0`;

    }
}
;

const readCSV = (csvContent) => {
    const parse = require('csv-parse');
    const rows = [];
    // Create the parser

    return new Promise(function (resolve, reject) {
        // executor (the producing code, "singer")
        parse(csvContent, {headers: false, delimiter: ';', columns: false}, (err, output) => {
            if (err) {
                console.error(err);
                return null;
            }

            for (let i = 0; i < output.length; i++) {
                if (isNumber(output[i][0])) {
                    rows.push({
                        isikukood: output[i][0],
                        yksus: output[i][1],
                        kood: output[i][2],
                        hind: output[i][3],
                        kogus: output[i][4],
                        kuu: output[i][5],
                        aasta: output[i][6]
                    });
                }
            }
            resolve(rows);
        });


    });
};

function isNumber(val) {
    // negative or positive
    return /^[-]?\d+$/.test(val);
}

