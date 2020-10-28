'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnGetCsv = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const BtnEarve = require('./../../components/button-register/button-earve/index.jsx');

const getSum = require('./../../../libs/getSum');

const DocContext = require('./../../doc-context.js');

const styles = require('./styles');
const EVENTS = [
    {name: 'Saama CSV fail', method: null, docTypeId: null},
    {name: 'Saama XML e-arved (SEB) kõik valitud arved', method: null, docTypeId: null},
    {name: 'Saama XML e-arved (SWED) kõik valitud arved', method: null, docTypeId: null},
];


const DOC_TYPE_ID = 'ARVED_KOODI_JARGI';
const TOOLBAR_PROPS = {
    add: false,
    edit: false,
    delete: false,
    start: false,
    print: true,
    email: true
};

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            summa: 0,
            read: 0
        };
        this.renderer = this.renderer.bind(this);
        this.onClickHandler = this.onClickHandler.bind(this);

    }

    render() {
        return (
            <div>
                <DocumentRegister initData={this.props.initData}
                                  history={this.props.history ? this.props.history : null}
                                  module={this.props.module}
                                  ref='register'
                                  toolbarProps={TOOLBAR_PROPS}
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
            </div>
        )
    }

    renderer(self) {
        let summa = self.gridData ? getSum(self.gridData, 'summa') : 0;
        let read = self.gridData ? self.gridData.length : 0;
        if (summa) {
            this.setState({summa: summa, read: read});
        }

        return (<ToolbarContainer>
                <BtnEarve
                    onClick={this.onClickHandler}
                    docTypeId={DOC_TYPE_ID}
                    phrase={`Kas laadida XML (SWED) fail?`}
                    ref='btnEarveSwedXML'
                    value={EVENTS[2].name}
                />
                <BtnEarve
                    onClick={this.onClickHandler}
                    docTypeId={DOC_TYPE_ID}
                    phrase={`Kas laadida XML (SEB) fail?`}
                    ref='btnEarveSebXML'
                    value={EVENTS[1].name}
                />

                <BtnGetCsv
                    value={'Saama CSV fail'}
                    onClick={this.onClickHandler}
                    showDate={false}
                    ref={`btn-getcsv`}
                />
            </ToolbarContainer>
        );
    }

    //handler для события клик на кнопках панели
    onClickHandler(event) {
        const Doc = this.refs['register'];
        let ids = new Set; // сюда пишем ид счетом, которые под обработку
        //Saama CSV fail
        switch (event) {
            case EVENTS[0].name:

                if (Doc.gridData && Doc.gridData.length) {
                    //делаем редайрект на конфигурацию
                    let sqlWhere = Doc.state.sqlWhere;
                    let url = `/reports/arved_koodi_jargi/${DocContext.userData.uuid}`;
                    let params = encodeURIComponent(`${sqlWhere}`);
                    window.open(`${url}/${params}`);
                } else {
                    Doc.setState({
                        warning: 'Mitte ühtegi kirjed leidnud', // строка извещений
                        warningType: 'notValid',

                    });
                }
            case EVENTS[1].name:
                //e-arved SEB (XML)

                // будет сформирован файл для отправки в банк СЕБ
                Doc.gridData.forEach(row => {
                    if (row.pank && row.pank == 'SEB' && row.select && Number(row.summa) > 0) {
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
                    let url = `/e-arved/seb/${DocContext.userData.uuid}/${ids}`;
                    window.open(`${url}`);

                }
                break;
            case EVENTS[2].name:
                //e-arved Swed (XML)

                // будет сформирован файл для отправки в банк SWED
                Doc.gridData.forEach(row => {
                    if (row.select && row.pank && row.pank == 'SWED' && Number(row.summa) > 0) {
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

                    let url = `/e-arved/swed/${DocContext.userData.uuid}/${ids}`;
                    window.open(`${url}`);

                }
                break;
        }


    }


}


module.exports = (Documents);


