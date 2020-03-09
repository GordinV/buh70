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
console.log(params, user.id, user.asutusId);
        const result = await Document.executeTask('importVanemateRegister', params).then((result) => {
                saved = result.result ? result.result : 0;
            }
        );

        return `Kokku leidsin ${rows.length} isikud, salvestatud kokku: ${saved}`;

    } else {
        return `Kokku leidsin 0 isikud, salvestatud kokku: 0`;

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
                    lapse_ik: row[0],
                    vanem_ik: row[1],
                    sugulus: row[2],
                    arveldus: row[3],
                    paper: row[4],
                    earve: row[5],
                    email: row[6],
                    esindaja: row[7],
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

