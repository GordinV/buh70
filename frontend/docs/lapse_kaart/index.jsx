'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnTask = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const ButtonUpload = require('./../../components/upload_button/index.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'LAPSE_KAART';

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
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this);
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 userData={this.props.userData}
                                 history={this.props.history ? this.props.history : null}
                                 module={this.props.module}
                                 ref='register'
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer() {
        let userRoles = DocContext.userData ? DocContext.userData.roles : [];
        return (
            <ToolbarContainer>
                {checkRights(userRoles, docRights, 'muudaEttemaksuPeriod') ?
                <BtnTask
                    value={'Muuda ettemaksu period'}
                    onClick={this.onClickHandler}
                    showDate={false}
                    showKogus={true}
                    ref={`btn-ettemaksu_period`}
                /> : null }
                {checkRights(userRoles, docRights, 'importTeenused') ?
                <ButtonUpload
                    ref='btnUpload'
                    docTypeId={DOC_TYPE_ID}
                    onClick={this.handleClick}
                    show={true}
                    mimeTypes={'.csv'}
                />: null }

            </ToolbarContainer>
        )
    }

    onClickHandler(event, ettemaksuPeriod) {
        const Doc = this.refs['register'];

        // собираем параметры
        const ids = [];
        Doc.gridData.filter(row => {
            if (row.ettemaks && row.select) {
                return row;
            }
        }).forEach(row => {
            ids.push(row.id);
        });


        // отправляем запрос на выполнение
        Doc.fetchData(`calc/muuda_ettemaksu_period`, {docs: ids, ettemaksuPeriod: ettemaksuPeriod}).then((data) => {

            if (data.result) {
                Doc.setState({warning: `Kokku arvestatud: ${data.result}`, warningType: 'ok'});

            } else {
                Doc.setState({warning: `Tekkis viga: ${data.error_message}`, warningType: 'notValid'});
            }

        });
    }

}


module.exports = (Documents);


