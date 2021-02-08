module.exports = async (file, mimeType, user) => {
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('NOMENCLATURE', null, user.userId, user.asutusId, 'lapsed');

    let rows = [];

    try {
        rows = await readCSV(file);


    } catch (e) {
        console.error('Viga:', e);
        return `Tekkis viga, võib olla vale formaat`;
    }

    let saved = 0;
    if (rows.length) {
        // сохраняем

        const params = [JSON.stringify(rows), user.id, user.asutusId];

        const result = await Document.executeTask('importNoms', params).then((result) => {
                saved = result.result ? result.result : 0;
            }
        );

        return `Kokku leidsin ${rows.length} operatsioonid, salvestatud kokku: ${saved}`;

    } else {
        return `Kokku leidsin 0 operatsioonid, salvestatud kokku: 0`;

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
            if (row[0] !== 'Kood') {

                rows.push({
                    kood: row[0],
                    nimetus: row[1],
                    dok: row[2],
                    maksumaar: row[3],
                    hind: row[4],
                    uhik: row[5],
                    koolituse_liik: row[6],
                    konto: row[7],
                    tegev: row[8],
                    allikas: row[9],
                    artikkel: row[10],
                    inf3: row[11],
                    tunnus: row[12],
                    proj: row[13],
                    luno: row[14]

                });
            }

        });
    });
    return rows;
};


