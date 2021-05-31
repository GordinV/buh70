'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./smk-register-styles');
const DOC_TYPE_ID = 'SMK';
const ButtonUpload = require('./../../components/upload_button/index.jsx');
const BtnLogs = require('./../../components/button-register/button_logs/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');

const getSum = require('./../../../libs/getSum');


const checkRights = require('./../../../libs/checkRights');
const DocContext = require('./../../doc-context.js');

const DocRights = require('./../../../config/doc_rights');

/**
 * Класс реализует документ приходного платежного ордера.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.renderer = this.renderer.bind(this);
        this.handleClick = this.handleClick.bind(this);
        this.state = {
            summa: 0,
            read: 0,
            isReport: false,
            txtReport:[]

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
            </div>
        )
    }

    renderer(self) {
        if (!self) {
            return null;
        }

        const docRights = DocRights[DOC_TYPE_ID] ? DocRights[DOC_TYPE_ID] : [];
        const userRoles = DocContext.userData ? DocContext.userData.roles : [];

        let deebet = self.gridData && self.gridData.length ? self.gridData[0].deebet_total : 0;
        this.setState({summa: deebet, read: self.gridData.length});

        return (
            <ToolbarContainer>
                {checkRights(userRoles, docRights, 'import') ?
                    <ButtonUpload
                        ref='btnUpload'
                        docTypeId={DOC_TYPE_ID}
                        onClick={this.handleClick}
                        show={true}
                        mimeTypes={'.csv,.xml'}
                    /> : null}
                <BtnLogs
                    history={self.props.history ? self.props.history : null}
                    ref='btnLogs'
                    value='Panga VV logid'
                />
            </ToolbarContainer>
        )
    }

    /**
     * кастомный обработчик события клик на кнопку импорта
     */
    handleClick() {

        //обновим данные
        const Doc = this.refs['register'];

        setTimeout(() => {
            Doc.fetchData('selectDocs');
        }, 1000);
    }
}

module.exports = (Documents);


