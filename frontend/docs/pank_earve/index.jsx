'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const BtnEarve = require('./../../components/button-register/button-earve/index.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const DocRights = require('./../../../config/doc_rights');
const DOC_TYPE_ID = 'PANK_EARVE';

const getSum = require('./../../../libs/getSum');

const styles = require('./styles');

const DocContext = require('./../../doc-context.js');
const EVENTS = [
    {name: 'Saama XML e-arved (SEB) kõik valitud arved', method: null, docTypeId: null},
    {name: 'Saama XML e-arved (SWED) kõik valitud arved', method: null, docTypeId: null},
];
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
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this);
        this.state = {
            summa: 0,
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
                                  toolbarProps={TOOLBAR_PROPS}
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
        );
    }

    renderer(self) {
        let summa = self.gridData ? getSum(self.gridData, 'summa') : 0;
        if (summa) {
            this.setState({summa: summa, read: self.gridData.length});
        }

        return (<ToolbarContainer>
            <BtnEarve
                onClick={this.onClickHandler}
                docTypeId={DOC_TYPE_ID}
                phrase={`Kas laadida XML (SWED) fail?`}
                ref='btnEarveSwedXML'
                value={'Saama XML e-arved (SWED) kõik valitud arved'}
            />
            <BtnEarve
                onClick={this.onClickHandler}
                docTypeId={DOC_TYPE_ID}
                phrase={`Kas laadida XML (SEB) fail?`}
                ref='btnEarveSebXML'
                value={'Saama XML e-arved (SEB) kõik valitud arved'}
            />
        </ToolbarContainer>)
    }

    //handler для события клик на кнопках панели
    onClickHandler(event, seisuga) {
        let ids = new Set; // сюда пишем ид счетом, которые под обработку

        const Doc = this.refs['register'];
        switch (event) {
            case 'Saama XML e-arved (SEB) kõik valitud arved':
                //e-arved SEB (XML)

                // будет сформирован файл для отправки в банк СЕБ
                Doc.gridData.forEach(row => {
                    if (row.select && row.pank && row.pank == 'SEB' ) {
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
            case 'Saama XML e-arved (SWED) kõik valitud arved':
                //e-arved Swed (XML)

                // будет сформирован файл для отправки в банк SWED
                Doc.gridData.forEach(row => {
                    if (row.select && row.pank && row.pank == 'SWED') {
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
        }
    }
}


module.exports = (Documents);


