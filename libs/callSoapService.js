const soapRequest = require('easy-soap-request');
const fs = require('fs');

// example data
//const url = 'https://testfinance.post.ee/finance/erp/';
const url = 'https://finance.omniva.eu/finance/erp/';

const headers = {
    'user-agent': 'sampleTest',
    'Content-Type': 'text/xml;charset=UTF-8',
    'soapAction': '',
};
const xml = fs.readFileSync('C:\\development\\buh70\\temp\\zipCodeEnvelope.xml', 'utf-8');

// usage of module
(async () => {
    const { response } = await soapRequest(url, headers, xml, 5000); // Optional timeout parameter(milliseconds)
    const { body, statusCode } = response;
})();
