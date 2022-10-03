'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');

const ButtonUpload = require('./../../components/upload_button/index.jsx');
const BtnArvesta = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const DocRights = require('./../../../config/doc_rights');
const checkRights = require('./../../../libs/checkRights');
const BtnGetCsv = require('./../../components/button-register/button-task/index.jsx');


const styles = require('./styles');
const DOC_TYPE_ID = 'LAPSE_TAABEL';
const docRights = DocRights[DOC_TYPE_ID] ? DocRights[DOC_TYPE_ID] : [];
const DocContext = require('./../../doc-context.js');


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            summa: 0,
            soodustus: 0,
            vahe: 0
        };
        this.renderer = this.renderer.bind(this);
        this.onClickHandler = this.onClickHandler.bind(this);

    }

    render() {
        return (
            <div>

                <DocumentRegister history={this.props.history ? this.props.history : null}
                                  module={this.props.module}
                                  ref='register'
                                  docTypeId={DOC_TYPE_ID}
                                  style={styles}
                                  render={this.renderer}/>
                <InputNumber title="Summa kokku:"
                             name='summa_kokku'
                             style={styles.total}
                             ref="input-summa"
                             value={Number(this.state.summa).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Soodustus kokku:"
                             name='soodustus_kokku'
                             style={styles.total}
                             ref="input-soodustus"
                             value={Number(this.state.soodustus).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Vahe kokku:"
                             name='vahe_kokku'
                             style={styles.total}
                             ref="input-vahe"
                             value={Number(this.state.vahe).toFixed(2) || 0}
                             disabled={true}
                />
            </div>
        );

    }

    // custom render
    renderer(self) {
        let userRoles = DocContext.userData ? DocContext.userData.roles : [];

        let summa = self.gridData && self.gridData.length ? self.gridData[0].summa_kokku : 0;
        let soodustus = self.gridData && self.gridData.length ? self.gridData[0].soodustus_kokku : 0;
        let vahe = self.gridData && self.gridData.length ? self.gridData[0].vahe_kokku : 0;

        if (summa || soodustus) {
            this.setState({summa: summa, read: self.gridData.length, soodustus: soodustus, vahe: vahe});
        }

        return (
            <ToolbarContainer>
                {checkRights(userRoles, docRights, 'delete') ?
                    <BtnArvesta
                        ref='btnUpload'
                        docTypeId={DOC_TYPE_ID}
                        onClick={this.onClickHandler}
                        showDate={false}
                        show={true}
                        mimeTypes={'.csv'}
                        value={'Kustuta kõik valitud tabelid?'}
                    /> : null}

                {checkRights(userRoles, docRights, 'importTaabel') ?
                    <ButtonUpload
                        ref='btnUpload'
                        docTypeId={DOC_TYPE_ID}
                        onClick={this.onClickHandler}
                        show={true}
                        mimeTypes={'.csv'}
                    /> : null}
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
        let message = '';

        // ищем выбранные записи
        if (Doc.gridData && Doc.gridData.length) {
            Doc.gridData.forEach(row => {
                if (row.select) {
                    ids.add(row.id);
                }
            });
        }

        // конвертация в массив
        ids = Array.from(ids);

        switch (event) {
            case 'Kustuta kõik valitud tabelid?':
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
            case 'Saama CSV fail':
                //Saama CSV fail
                if (Doc.gridData && Doc.gridData.length) {
                    //делаем редайрект на конфигурацию
                    let sqlWhere = Doc.state.sqlWhere;
                    let url = `/reports/${DOC_TYPE_ID.toLowerCase()}/${DocContext.userData.uuid}`;
                    let params = encodeURIComponent(`${sqlWhere}`);
                    window.open(`${url}/${params}`);
                } else {
                    Doc.setState({
                        warning: 'Mitte ühtegi kirjed leidnud', // строка извещений
                        warningType: 'notValid',

                    });
                }
        }

    }
}


module.exports = (Documents);


