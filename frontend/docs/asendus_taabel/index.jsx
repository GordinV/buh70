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
const DOC_TYPE_ID = 'ASENDUS_TAABEL';
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
            vahe: 0,
            kor_summa: 0
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
            </div>
        );

    }

    // custom render
    renderer(self) {
        let userRoles = DocContext.userData ? DocContext.userData.roles : [];

        let summa = self.gridData && self.gridData.length ? self.gridData[0].summa_kokku : 0;
        this.setState({summa: summa, read: self.gridData.length});

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
        }

    }
}


module.exports = (Documents);


