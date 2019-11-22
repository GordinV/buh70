//const getXml = require('./../lapsed/get_e-arve');
const axios = require('axios');
axios.defaults.baseURL = '/';

/*
const asutusConfig = {
    url: 'https://finance.omniva.eu/finance/erp/',
    secret: '106549:elbevswsackajyafdoupavfwewuiafbeeiqatgvyqcqdqxairz',
    asutus: 'RAHANDUSAMET',
    regkood: '75008427',
    user: 'Vladislav Gordin'

};
*/

//const xml = getXml([getData()], asutusConfig).replace('<?xml version="1.0" encoding="utf-8"?>','');
//const xml = getTestXml();

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

//const result = send_xml_omniva(xml, asutusConfig);


function getData() {
    return [{
        "row": [{
            "id": 1616587,
            "userid": 70,
            "created": "21.11.2019 09:11:03",
            "lastupdate": "21.11.2019 09:11:03",
            "bpm": null,
            "doc_status": 1,
            "number": "48",
            "rekvid": 63,
            "liik": 0,
            "operid": null,
            "kpv": "2019-11-30",
            "kpv_print": "30.11.2019",
            "asutusid": 4113,
            "arvid": 0,
            "lisa": null,
            "tahtaeg": "2019-12-15",
            "tahtaeg_print": "15.12.2019",
            "kbmta": "22.0000",
            "kbm": "4.4000",
            "summa": "26.4000",
            "tasud": null,
            "tasudok": null,
            "muud": "Arve, taabeli alus 11/2019 kuu eest",
            "jaak": "26.4000",
            "regkood": "37303023721         ",
            "asutus": "Gordin Vladislav",
            "aadress": "Vaivara vald",
            "email": "vladislav.gordin@gmail.com",
            "kmkr": "",
            "doklausid": 2360,
            "journalid": 1616588,
            "laus_nr": 6065,
            "konto": "103000",
            "kbmkonto": "",
            "dokprop": "tarnija",
            "is_show_journal": 0,
            "koostaja": "temp",
            "aa": "EE051010562011276005",
            "lapsid": 41,
            "isikukood": "99125254555",
            "lapse_nimi": "laps for test",
            "viitenr": "0630000412",
            "tyyp": null
        }],
        "details": [{
            "id": 172991,
            "userid": 70,
            "nomid": 2738,
            "kogus": "1.000",
            "hind": "22.0000",
            "kbm": "4.4000",
            "kbmta": "22.0000",
            "summa": "26.4000",
            "kood": "inventaar",
            "nimetus": "inventaar",
            "soodus": 0,
            "kood1": "01112",
            "kood2": "LE-P",
            "kood3": "",
            "kood4": "",
            "kood5": "5515",
            "tunnus": "OSAK                ",
            "proj": "",
            "konto": "551500",
            "tp": "800699",
            "vastisik": null,
            "formula": null,
            "valuuta": "EUR",
            "kuurs": "1",
            "km": "",
            "uhik": "                    ",
            "muud": "grupp 2(3)"
        }],
    }
    ]
}

function getTestXml() {
    return `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:erp="http://e-arvetekeskus.eu/erp">
<soapenv:Header/>
<soapenv:Body>
<erp:EInvoiceRequest authPhrase="106549:elbevswsackajyafdoupavfwewuiafbeeiqatgvyqcqdqxairz">
<E_Invoice>
<Header>
<Date>2019-11-22</Date>
<FileId>1</FileId>
<AppId>EARVE</AppId>
<Version>1.1</Version>
</Header>
<Invoice invoiceId="28" regNumber="11534064">
<InvoiceParties>
<SellerParty>
<Name>Narva Linnavalitsuse Rahandusamet</Name>
<RegNumber>75008427</RegNumber>
<ContactData>
<PhoneNumber>3599190</PhoneNumber>
<LegalAddress>
<PostalAddress1>Peetri 5</PostalAddress1>
<City>Narva</City>
</LegalAddress>
</ContactData>
</SellerParty>
<BuyerParty>
<Name>Vladislav Gordin</Name>
<RegNumber>37303023721</RegNumber>
<ContactData>
<E-mailAddress></E-mailAddress>
</ContactData>
</BuyerParty>
</InvoiceParties>
<InvoiceInformation>
<Type type="DEB"/>
<ContractNumber></ContractNumber>
<DocumentName>Arve</DocumentName>
<InvoiceNumber>28</InvoiceNumber><InvoiceDate>2018-11-30</InvoiceDate>
<DueDate>2018-11-30</DueDate>
<InvoiceDeliverer>
<ContactName>Vlad Gordin</ContactName>
</InvoiceDeliverer>
</InvoiceInformation>
<InvoiceSumGroup>
<InvoiceSum>9.06</InvoiceSum>
<VAT>
<VATRate>20</VATRate>
<VATSum>0.00</VATSum>
</VAT>
<TotalSum>9.06</TotalSum>
<Currency>EUR</Currency>
</InvoiceSumGroup>
<InvoiceItem>
<InvoiceItemGroup>
<ItemEntry>
<Description>test</Description>
<ItemDetailInfo>
<ItemUnit></ItemUnit>
<ItemAmount>1.0000</ItemAmount>
<ItemPrice>0.00</ItemPrice>
</ItemDetailInfo>
<ItemSum>9.06</ItemSum>
<VAT>
<SumBeforeVAT>9.06</SumBeforeVAT>
<VATRate>20</VATRate>
<VATSum>0.00</VATSum>
<Currency>EUR</Currency>
</VAT>
<ItemTotal>9.06</ItemTotal>
</ItemEntry>
</InvoiceItemGroup>
</InvoiceItem>
<PaymentInfo>
<Currency>EUR</Currency>
<PaymentRefId></PaymentRefId>
<PaymentDescription>Arve 28                  </PaymentDescription>
<Payable>YES</Payable>
<PayDueDate>2018-11-30</PayDueDate> 
<PaymentTotalSum>9.06</PaymentTotalSum>
<PayerName>Vladislav Gordin</PayerName>
<PaymentId>28</PaymentId>
<PayToAccount>EE051010562011276005</PayToAccount>
<PayToName>Narva Linnavalitsuse Rahandusamet</PayToName>
</PaymentInfo>
</Invoice>
<Footer>
<TotalNumberInvoices>1</TotalNumberInvoices>
<TotalAmount>9.06</TotalAmount>
</Footer>
</E_Invoice>
</erp:EInvoiceRequest>  
</soapenv:Body>
</soapenv:Envelope>`
}
