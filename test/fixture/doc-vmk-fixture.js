module.exports = {
    id: 1,
    type: 'DOK1',
    created: '2017-01-01',
    lastupdate: '2017-01-01',
    kpv: '2017-07-01',
    number:'001',
    status: 'ok',
    doklausid: 1,
    dokprop: 'Deebet / Kreedit',
    asutusid: 1,
    asutus: 'Asutus',
    aadress: 'Aadress',
    relations: [],
    bpm:[
        {
            step: 0,
            name: 'Регистация документа',
            action: 'start',
            nextStep: 1,
            task: 'human',
            data: [],
            actors: [],
            status: null,
            actualStep: false
        },
        {
            step: 1,
            name: 'Контировка',
            action: 'generateJournal',
            nextStep: 2,
            task: 'human',
            data: [],
            status: null,
            actualStep: false
        },
//        {step:2, name:'Оплата', action: 'tasumine', nextStep:3, task:'human', data:[], status:null, actualStep:false},
        {
            step: 2,
            name: 'Конец',
            action: 'endProcess',
            nextStep: null,
            task: 'automat',
            data: [],
            actors: [],
            status: null,
            actualStep: false
        }
    ],
    details: [{
        id: 1,
        konto:'113',
        summa: 44,
        tunnus:'tunnus',
        proj: 'proj'
    },
        {
            id: 2,
            konto:'221',
            summa: 55,
            tunnus:'tunnus',
            proj: 'proj'

        }],
    doc_status: 0
};
