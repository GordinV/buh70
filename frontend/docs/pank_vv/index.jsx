'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const InputText = require('../../components/input-text/input-text.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const BtnLoeTasu = require('./../../components/button-register/button-task/index.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'PANK_VV';

const DocRights = require('./../../../config/doc_rights');
const checkRights = require('./../../../libs/checkRights');
const DocContext = require('./../../doc-context.js');

const docRights = DocRights[DOC_TYPE_ID] ? DocRights[DOC_TYPE_ID] : [];
const userRoles = DocContext.userData ? DocContext.userData.roles : [];
const getSum = require('./../../../libs/getSum');


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.Doc = null; //ссылка на страницу
        this.renderer = this.renderer.bind(this);
        this.render = this.render.bind(this);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.state = {
            summa: 0,
            read: 0,
            filtri_read: 0,


        };

        this.makse = {}; // данные на строку

    }

    render() {
        let state;
        if (this.Doc) {
            state = this.Doc && this.Doc.state ? this.Doc.state : null;
        }

        const toolbarParams = {
            btnAdd: {
                show: false
            },
            btnEdit: {
                show: true
            },
            btnDelete: {
                show: true
            },
            btnPrint: {
                show: false
            },
            btnStart: {
                show: false
            }
        };

        return (
            <div>

                <DocumentRegister history={this.props.history ? this.props.history : null}
                                  module={this.props.module}
                                  ref='register'
                                  docTypeId={DOC_TYPE_ID}
                                  style={styles}
                                  toolbarParams={toolbarParams}
                                  render={this.renderer}/>
                <InputText title="Filtri all / read kokku:"
                           name='read_kokku'
                           style={styles.total}
                           ref="input-read"
                           value={String(this.state.filtri_read + '/' + this.state.read)}
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
        if (!self) {
            // не инициализировано
            return null;
        }

        this.Doc = self;
        let kasLoeMakse = false;


        // определим ид строки
        let rowId = this.Doc.state && this.Doc.state.value ? this.Doc.state.value : 0;
        // найдем строку
        if (rowId) {
            this.makse = this.Doc.gridData.find(row => row.id == rowId);
            if (this.makse && !this.makse.doc_id) {
                kasLoeMakse = true;
            }

        }

        // подсчет итогов
        let summa = self.gridData ? getSum(self.gridData, 'summa') : 0;
        this.setState({
            summa: summa,
            read: self.gridData && self.gridData.length && self.gridData[0].rows_total ? self.gridData[0].rows_total : this.state.read,
            filtri_read: self.gridData && self.gridData.length && self.gridData[0].filter_total ? self.gridData[0].filter_total : 0
        });

        return (
            <ToolbarContainer>
                {kasLoeMakse ? <BtnLoeTasu
                    showDate={false}
                    value={'Loe makse'}
                    onClick={this.onClickHandler}
                    ref={`btn-loe_makse`}
                    key={`key-loe_makse`}
                /> : null}

            </ToolbarContainer>
        )

    }

    onClickHandler(event, seisuga) {
        const Doc = this.refs['register'];
        let message = 'Edukalt';

        Doc.fetchData(`calc/loe_makse`, {makse_id: this.makse.id}).then((data) => {
            if (data.result) {
                if (data.result && data.result.error_code) {
                    // error
                    Doc.setState({warning: `Tekkis viga: ${data.result.error_message}`, warningType: 'error'});
                } else {
                    if (data.result.data[0].error_message) {
                        // error
                        Doc.setState({
                            warning: `Tekkis viga: ${data.result.data[0].error_message}`,
                            warningType: 'error'
                        });
                    } else {
                        Doc.setState({warning: `${message}`, warningType: 'ok'}, () =>
                            Doc.fetchData('selectDocs'));
                    }
                }

                // открываем отчет

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


}

module.exports = (Documents);


