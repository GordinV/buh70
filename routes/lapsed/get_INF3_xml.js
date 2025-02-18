const builder = require('xmlbuilder');

module.exports = async (data, user) => {
    // data - sql data got from model
    let aasta = data[0].aasta;
    let asutuseRegkood = data[0].asutuse_regkood;
    const obj = {
        deklaratsioon: {
            '@xmlns': 'http://www.emta.ee/inf3',
            '@xmlns:xsi': "http://www.w3.org/2001/XMLSchema-instance",
            '@tyyp': "inf3",
            '@xsi:schemaLocation': "http://www.emta.ee/inf3 inf3.xsd",
            saatja_regkood: asutuseRegkood,
            periood: {
                aasta: aasta
            },
        }
    };

    const kirje = data.map(kiri => {
        return {
            koolitusmaksja_isikukood: kiri.maksja_isikukood,
            koolitatava_isikukood: kiri.lapse_isikukood,
            makstud_summa: kiri.summa,
            koolituse_liik: kiri.liik
        };

    });

    obj.deklaratsioon.inf3 = {kirje};

    const xml = builder.create(obj).end({pretty: true});
    return xml;
};

