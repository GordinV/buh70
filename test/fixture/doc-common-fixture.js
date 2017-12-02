module.exports = {
    id: 1,
    number: '0001',
    type: 'DOK1',
    doc_type_id:'ARV',
    created: '2017-01-01',
    lastupdate: '2017-01-01',
    status: 'ok',
    doklausid: 1,
    dokprop: 'Deebet / Kreedit',
    asutusid: 1,
    asutus: 'Asutus',
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
        nomid: 1,
        kood:'kood1',
        name: 'nimetu1',
        hind: 10,
        kogus: 1,
        kbm: 2,
        summa: 12
    },{
        id: 2,
        nomid: 2,
        kood:'kood2',
        name: 'nimetu2',
        hind: 20,
        kogus: 2,
        kbm: 4,
        summa: 44

    }],
    doc_status: 0
};
