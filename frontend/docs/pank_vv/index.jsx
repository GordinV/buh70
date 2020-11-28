'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const InputText = require('../../components/input-text/input-text.jsx');

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
        this.btnEditClick = this.btnEditClick.bind(this);
        this.Doc = null; //ссылка на страницу
        this.renderer = this.renderer.bind(this);
        this.render = this.render.bind(this);
        this.state = {
            summa: 0,
            read: 0,
            filtri_read: 0,

        };

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
                show: state && state.value && checkRights(userRoles, docRights, 'edit')
            },
            btnDelete: {
                show: checkRights(userRoles, docRights, 'delete')
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
                                  btnEditClick={this.btnEditClick}
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

        // подсчет итогов
        let summa = self.gridData ? getSum(self.gridData, 'summa') : 0;
        this.setState({
            summa: summa,
            read: self.gridData && self.gridData.length && self.gridData[0].rows_total ? self.gridData[0].rows_total: this.state.read,
            filtri_read: self.gridData && self.gridData.length && self.gridData[0].filter_total ? self.gridData[0].filter_total : 0
        });

    }

    btnEditClick() {
        // кастомный обработчик события
        if (this.Doc && this.Doc.state) {
            const value = this.Doc.state.value;
            const gridData = this.Doc.gridData;
            let doc_id = gridData.find(row => row.id = value).doc_id;
            if (doc_id) {
                return this.props.history.push({
                    pathname: `/${this.props.module}/SMK/${doc_id}`,
                    state: {module: this.props.module}
                });

            } else {
                this.Doc.setState({
                    warning: 'Maksekorraldus ei leidnud',
                    warningType: 'error'
                });

            }

        }

    }

}

module.exports = (Documents);


