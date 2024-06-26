'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');

const styles = require('./styles');
const ButtonUpload = require('./../../components/upload_button/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const InputText = require('../../components/input-text/input-text.jsx');

const DOC_TYPE_ID = 'VANEM';
const DocRights = require('./../../../config/doc_rights');
const checkRights = require('./../../../libs/checkRights');
const DocContext = require('./../../doc-context.js');
const docRights = DocRights[DOC_TYPE_ID] ? DocRights[DOC_TYPE_ID] : [];


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.renderer = this.renderer.bind(this);
        this.state = {
            read: 0,
            filtri_read: 0
        };

    }

    render() {
        const userRoles = DocContext.userData ? DocContext.userData.roles : [];

        const toolbarParams = {
            btnAdd: {
                show: false,
                disabled: false
            },
            btnEdit: {
                show: checkRights(userRoles, docRights, 'edit'),
                disabled: false
            },
            btnDelete: {
                show: checkRights(userRoles, docRights, 'delete'),
                disabled: false
            },
            btnPrint: {
                show: true,
                disabled: false
            }
        };

        return (
            <div>
                <DocumentRegister initData={this.props.initData}
                                  userData={this.props.userData}
                                  history={this.props.history ? this.props.history : null}
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

            </div>
        )
    }

    renderer(self) {
        if (self && self.gridData )  {
            let rows_total = self.gridData.length && self.gridData[0].rows_total ? self.gridData[0].rows_total: 0;
            this.setState({
                read: rows_total,
                filtri_read: self.gridData.length && self.gridData[0].filter_total ? self.gridData[0].filter_total : rows_total
            });
        }

        const userRoles = DocContext.userData ? DocContext.userData.roles : [];

        return (
            <ToolbarContainer>
                {checkRights(userRoles, docRights, 'importLepingud') ?
                    <ButtonUpload
                        ref='btnUploadSwed'
                        docTypeId={'import_leping_swed'}
                        onClick={this.handleClick}
                        show={true}
                        value={'Loe panga lepingud (SWED)'}
                        mimeTypes={'.csv'}
                    /> : null}
                {checkRights(userRoles, docRights, 'importLepingud') ?

                    < ButtonUpload
                        ref='btnUploadSeb'
                        docTypeId={'import_leping_seb'}
                        onClick={this.handleClick}
                        show={true}
                        value={'Loe panga lepingud (SEB)'}
                        mimeTypes={'.csv'}
                    />
                    : null}
                {checkRights(userRoles, docRights, 'importVanemateRegister') ?
                    <ButtonUpload
                        ref='btnUpload'
                        docTypeId={DOC_TYPE_ID}
                        onClick={this.handleClick}
                        show={true}
                        mimeTypes={'.csv'}
                    /> : null}
            </ToolbarContainer>
        )
    }

}


module.exports = (Documents);


