'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const BtnSettings = require('./../../components/button-register/button-settings/index.jsx');
const BtnPrint = require('./../../components/button-register/button-register-print/button-register-print.jsx');
const BtnEmail = require('./../../components/button-register/button-email/index.jsx');
const BtnEarve = require('./../../components/button-register/button-earve/index.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const BtnArvesta = require('./../../components/button-register/button-task/index.jsx');
const checkRights = require('./../../../libs/checkRights');
const DocRights = require('./../../../config/doc_rights');
const DOC_TYPE_ID = 'ARV';

const docRights = DocRights[DOC_TYPE_ID] ? DocRights[DOC_TYPE_ID] : [];

const getSum = require('./../../../libs/getSum');

const styles = require('./arv-register-styles');

const DocContext = require('./../../doc-context.js');
const EVENTS = [
    {name: 'Häälestamine', method: null, docTypeId: null},
    {name: 'Trükk kõik valitud arved', method: null, docTypeId: null},
    {name: 'Email kõik valitud arved', method: null, docTypeId: null},
    {name: 'Saada E-Arved (Omniva) kõik valitud arved', method: null, docTypeId: null},
    {name: 'Saama XML e-arved kõik valitud arved', method: null, docTypeId: null},
    {name: 'Saama XML e-arved (SEB) kõik valitud arved', method: null, docTypeId: null},
    {name: 'Saama XML e-arved (SWED) kõik valitud arved', method: null, docTypeId: null},
    {name: 'Nõuete mahakanne', method: null, docTypeId: null},
];

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this);
        this.state = {
            summa: 0,
            jaak: 0,
            read: 0
        };

    }

    render() {
        return (
            <div>
                <DocumentRegister initData={this.props.initData}
                                  history={this.props.history ? this.props.history : null}
                                  module={this.props.module}
                                  ref='register'
                                  docTypeId={DOC_TYPE_ID}
                                  style={styles}
                                  render={this.renderer}/>
                <InputNumber title="Read kokku:"
                             name='read_kokku'
                             style={styles.total}
                             ref="input-read"
                             value={Number(this.state.read) || 0}
                             disabled={true}/>
                <InputNumber title="Summa kokku:"
                             name='summa_kokku'
                             style={styles.total}
                             ref="input-summa"
                             value={Number(this.state.summa).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Jääk kokku:"
                             name='jaak_kokku'
                             style={styles.total}
                             ref="input-jaak"
                             value={Number(this.state.jaak).toFixed(2) || 0}
                             disabled={true}/>

            </div>
        );
    }

    renderer(self) {
        let summa = self.gridData ? getSum(self.gridData, 'summa') : 0;
        let jaak = self.gridData ? getSum(self.gridData, 'jaak') : 0;
        if (summa) {
            this.setState({summa: summa, read: self.gridData.length, jaak: jaak});
        }
        let userRoles = DocContext.userData ? DocContext.userData.roles : [];


        return (<ToolbarContainer>
            {checkRights(userRoles, docRights, 'delete') ?
                <BtnArvesta
                    ref='btnUpload'
                    docTypeId={DOC_TYPE_ID}
                    onClick={this.onClickHandler}
                    showDate={false}
                    show={true}
                    mimeTypes={'.csv'}
                    value={'Kustuta kõik valitud arved?'}
                /> : null}

            <BtnEarve
                onClick={this.onClickHandler}
                docTypeId={DOC_TYPE_ID}
                phrase={`Kas laadida XML (SWED) fail?`}
                ref='btnEarveSwedXML'
                value={EVENTS[6].name}
            />
            <BtnEarve
                onClick={this.onClickHandler}
                docTypeId={DOC_TYPE_ID}
                phrase={`Kas laadida XML (SEB) fail?`}
                ref='btnEarveSebXML'
                value={EVENTS[5].name}
            />
            <BtnEarve
                onClick={this.onClickHandler}
                docTypeId={DOC_TYPE_ID}
                phrase={`Kas laadida XML fail?`}
                ref='btnEarveXML'
                value={EVENTS[4].name}
            />
{/*
            <BtnEarve
                onClick={this.onClickHandler}
                docTypeId={DOC_TYPE_ID}
                ref='btnEarveOmniva'
                value={EVENTS[3].name}
            />
*/}
{/*
            <BtnEmail
                onClick={this.onClickHandler}
                docTypeId={DOC_TYPE_ID}
                ref='btnEmail'
                value={EVENTS[2].name}
            />
*/}
            <BtnPrint
                onClick={this.onClickHandler}
                docTypeId={DOC_TYPE_ID}
                ref='btnPrint'
                value={EVENTS[1].name}
            />
            <BtnArvesta
                value={EVENTS[7].name}
                onClick={this.onClickHandler}
                ref={`btn-${EVENTS[7].name}`}
                key={`key-${EVENTS[7].name}`}
            />

            <BtnSettings
                history={self.props.history ? self.props.history : null}
                docTypeId={DOC_TYPE_ID}
                onClick={this.onClickHandler}
                ref='btnSettings'
                value={EVENTS[0].name}
            />
        </ToolbarContainer>)
    }

    //handler для события клик на кнопках панели
    onClickHandler(event, seisuga) {
        let ids = new Set; // сюда пишем ид счетом, которые под обработку

        const Doc = this.refs['register'];
        switch (event) {
            case 'Kustuta kõik valitud arved?':
                // будет выведено на печать выбранные и только для печати счета
                Doc.gridData.forEach(row => {
                    if (row.select) {
                        // выбрано для печати
                        ids.add(row.id);
                    }
                });
                // конвертация в массив
                ids = Array.from(ids);

                if (!ids.length) {
                    Doc.setState({
                        warning: 'Mitte ühtegi tabel valitud', // строка извещений
                        warningType: 'notValid',
                    });
                } else {
                    // удаляем выбранные табеля

                    Doc.fetchData('delete', {docs: ids}).then((data) => {
                        if (data && data.data && data.data.result) {
                            message = `Kokku kustutatud ${data.data.result} kirjad`;
                            Doc.setState({warning: `${message}`, warningType: 'ok'});

                            //let tulemused = data.result.tulemused;
                            // открываем отчет
                            //this.setState({isReport: true, txtReport: tulemused});

                        } else {
                            if (data.error_message) {
                                Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'error'});
                            }
                        }
                    });
                    setTimeout(() => {
                        Doc.fetchData('selectDocs')
                    }, 3000);

                }

                break;
            case EVENTS[0].name:
                //делаем редайрект на конфигурацию
                this.props.history.push(`/${this.props.module}/config/${DocContext.getAsutusId}`);
                break;
            case EVENTS[1].name:
                // Print

                // будет выведено на печать выбранные и только для печати счета
                Doc.gridData.forEach(row => {
                    if (row.select && row.kas_paberil) {
                        // выбрано для печати
                        ids.add(row.id);
                    }
                });
                // конвертация в массив
                ids = Array.from(ids);

                if (ids.length > 0) {
                    Doc.setState({
                        warning: `Leidsin ${ids.length} arveid printimiseks`, // строка извещений
                        warningType: 'ok',
                    });

                    let url = `/multiple_print/${DOC_TYPE_ID}/${DocContext.getUuid}/${ids}`;
                    window.open(`${url}`);
                } else {
                    Doc.setState({
                        warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                }

                break;
            case EVENTS[2].name:
                //emails

                // будет отправлено на почту  выбранные и только для эл.почты счета
                Doc.gridData.forEach(row => {
                    if (row.select && row.kas_email) {
                        // выбрано для печати
                        ids.add(row.id);
                    }
                });

                // конвертация в массив
                ids = Array.from(ids);

                if (!ids.length) {
                    Doc.setState({
                        warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                } else {
                    // отправляем запрос на выполнение

                    Doc.fetchData(`email`, ids).then((data) => {
                        if (data.result) {
                            Doc.setState({warning: `Kokku saadetud arveid emailga: ${data.result}`, warningType: 'ok'});

                        } else {
                            console.error('email error', data);
                            Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'error'});
                        }

                    }).catch(error => {
                        console.error('email error', error);
                        Doc.setState({warning: `Tekkis viga: ${error}`, warningType: 'error'});

                    });


                }

                break;

            case EVENTS[3].name:
                //e-arved

                // будет отправлено на почту  выбранные и только для эл.почты счета
                Doc.gridData.forEach(row => {
                    if (row.select && row.kas_earved ) {
                        // выбрано для печати
                        ids.add(row.id);
                    }
                });
                // конвертация в массив
                ids = Array.from(ids);

                if (!ids.length) {
                    Doc.setState({
                        warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                } else {
                    // отправляем запрос на выполнение

                    Doc.fetchData(`e-arved`, ids).then((data) => {
                        if (data && 'result' in data) {
                            Doc.setState({warning: `Kokku saadetud arveid  : ${data.result}`, warningType: 'ok'});

                        } else {
                            let error_message = 'Tekkis viga' + (data && ('error_message' in data.error_message) && data.error_message) ? data.error_message : '';
                            Doc.setState({warning: `${error_message}`, warningType: 'error'});
                        }

                    }).catch(err => {
                        let error_message = 'Tekkis viga' + (err.TypeError) ? err.TypeError : '';
                        Doc.setState({warning: `${error_message}`, warningType: 'error'});
                    });


                }

                break;
            case EVENTS[4].name:
                //e-arved (XML)

                // будет отправлено на почту  выбранные и только для эл.почты счета
                Doc.gridData.forEach(row => {
                    if (row.select && row.kas_earved)   {
                        // выбрано для печати
                        ids.add(row.id);
                    }
                });
                // конвертация в массив
                ids = Array.from(ids);

                if (!ids.length) {
                    Doc.setState({
                        warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                } else {
                    // отправляем запрос на выполнение
                    Doc.setState({
                        warning: `Leidsin ${ids.length} arveid`, // строка извещений
                        warningType: 'ok',
                    });

                    let url = `/e-arved/${DocContext.getUuid}/${ids}`;
                    window.open(`${url}`);

                }

                break;
            case EVENTS[5].name:
                //e-arved SEB (XML)

                // будет сформирован файл для отправки в банк СЕБ
                Doc.gridData.forEach(row => {
                    if (row.kas_earved && row.pank && row.pank == 'SEB' ) {
                        // выбрано для печати
                        ids.add(row.id);
                    }
                });
                // конвертация в массив
                ids = Array.from(ids);

                if (!ids.length) {
                    Doc.setState({
                        warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                } else {
                    // отправляем запрос на выполнение
                    Doc.setState({
                        warning: `Leidsin ${ids.length} arveid`, // строка извещений
                        warningType: 'ok',
                    });

                    let url = `/e-arved/seb/${DocContext.getUuid}/${ids}`;
                    window.open(`${url}`);

                }
                break;
            case EVENTS[6].name:
                //e-arved Swed (XML)

                // будет сформирован файл для отправки в банк SWED
                Doc.gridData.forEach(row => {
                    if (row.kas_earved && row.select && row.pank && row.pank == 'SWED' && Number(row.summa) > 0) {
                        // && row.kas_swed
                        // выбрано для печати
                        ids.add(row.id);
                    }
                });
                // конвертация в массив
                ids = Array.from(ids);

                if (!ids.length) {
                    Doc.setState({
                        warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                } else {
                    // отправляем запрос на выполнение
                    Doc.setState({
                        warning: `Leidsin ${ids.length} arveid`, // строка извещений
                        warningType: 'ok',
                    });

                    let url = `/e-arved/swed/${DocContext.getUuid}/${ids}`;
                    window.open(`${url}`);

                }
                break;
            case EVENTS[7].name:
                //списание маловероятных
                let message = '';
                // будет сформирован файл для отправки в банк SWED
                Doc.gridData.forEach(row => {
                    if (row.ebatoenaolised == 'Jah' && Number(row.jaak) > 0) {
                        // && row.kas_swed
                        // выбрано для печати
                        ids.add(row.id);
                    }
                });
                // конвертация в массив
                ids = Array.from(ids);

                if (!ids.length) {
                    Doc.setState({
                        warning: 'Mitte ühtegi arve leidnum', // строка извещений
                        warningType: 'notValid',
                    });
                } else {
                    Doc.fetchData(`calc/ebatoenaolised`, {docs: ids, seisuga: seisuga}).then((data) => {
                        if (data.result) {
                            message = `task saadetud täitmisele`;
                            Doc.setState({warning: `${message}`, warningType: 'ok'});

                            let tulemused = data.data.result.tulemused;
                            // открываем отчет
                            this.setState({isReport: true, txtReport: tulemused});

                        } else {
                            if (data.error_message) {
                                Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'error'});
                            } else {
                                Doc.setState({
                                    warning: `Kokku arvestatud : ${data.result}, ${message}`,
                                    warningType: 'notValid'
                                });
                            }

                        }

                    });
                }
                break;

        }
    }
}


module.exports = (Documents);


