const axios = require('axios');
axios.defaults.baseURL = '/';

const send_xml_omniva = async (xml, asutusConfig) => {
    // validate config
    if (!asutusConfig || !asutusConfig.url) {
        console.error('Puudub url või salasõna');
        return {status: 400, error_message: 'Puudub url või salasõna'};
    }

    const params = {
        headers: {
            'content-type': 'text/xml;charset=UTF-8',
            'user-agent': 'sampleTest',
            'soapAction': ''
        }
    };

    let tulemus;
    const result = await axios.post(asutusConfig.url, xml, params).then((result) => {
        tulemus = result.status;
    })
        .catch(error => {
            console.error('fetch status, error', error.response.status, error);
            return ({
                result: 'error',
                status: error.response.status,
                error_message: error.message ? error.message : 'Error'
            });
        });
    return tulemus;
};


module.exports = send_xml_omniva;


