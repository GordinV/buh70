module.exports = async (file, mimeType) => {
    console.log('mimeType', mimeType);

    let reply;
    if (mimeType === 'text/xml') {
        reply = await readXML(file);
    } else if (mimeType === 'application/octet-stream') {
        reply = await readCSV(file);
    }
    console.log('reply', reply);
    return reply

};

const readXML = async (xmlContent) => {
    const xml2js = require('xml2js');
    const parser = new xml2js.Parser({ignoreAttrs: true});
    const fileContent = await parser.parseString(xmlContent, (err, result) => {
        console.log('err -> ', err);
        console.log('result -> ', JSON.stringify(result));
        return result
    });

    return 'Ok, xml';

};

const readCSV = async (csvContent) => {
    const parse = require('csv-parse');
    let result = [];
    // Create the parser
    const fileContent = await parse(csvContent,{delimiter:';'}, (err, output) => {
        console.log('err, output', err, output);
        result = output;
        return output;
    });
    console.log('fileContent',result);
    return `Ok, csv, Result: ${result.length}`
};