module.exports = async (file, mimeType, user) => {
    const Doc = require('./../../classes/DocumentTemplate');
    const Document = new Doc('VANEM', null, user.userId, user.asutusId, 'lapsed');

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

        const result = await Document.executeTask('importPankLeping', params).then((result) => {
                saved = result.result ? result.result : 0;
                return saved;
            }
        );

        return `Kokku leidsin ${rows.length} lepingud, salvestatud kokku: ${saved}`;

    } else {
        return `Kokku leidsin 0 lepingud, salvestatud kokku: 0`;

    }
}
;

const readCSV = async (csvContent) => {
    const parse = require('csv-parse');
    const rows = [];
    // Create the parser
    const fileContent = await parse(csvContent, {
        escape: '"',
        relax: true,
        headers: true,
        delimiter: ';',
        columns: false
    }, (err, output) => {
        result = output;
        if (err) {
            console.error(err);
            return null;
        }

        output.forEach(row => {
            // проверим на заголовок

            if (!row[0].match(/[A-Z]/g)) {
                rows.push({
                    kpv: row[0],
                    viitenr: row[1],
                    aa: row[2],
                    toiming: row[3],
                    nimi: row[5],
                    isikukood: row[6],
                    kanal: row[9],
                    kehtiv: row[0]
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

