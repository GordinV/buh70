const fs = require('fs');
const filename = 'c:/temp/viitenr.csv';

fs.readFile(filename, "utf8", function(err, data) {
    if (err) {
        // may be filename does not exists?
        console.error('error', err);
    } else {
        import_viitenr(data);
    }
});


const import_viitenr =  async (file) => {
    let rows = [];

    try {
        rows = await readCSV(file);

    } catch (e) {
        console.error('Viga:', e);
        return `Tekkis viga, võib olla vale formaat`;
    }

    let saved = 0;
    if (rows.length) {
        console.log(`Kokku leidsin ${rows.length} operatsioonid, salvestan..`);
        // сохраняем
        writeJson(rows);

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


const writeJson = (content) => {
    let jsonText = JSON.stringify(content);
    fs.writeFile('c:/temp/viitenr.json', jsonText, (err) => {
        if (err) throw err;
        console.log('The file has been saved!');
    });
};

