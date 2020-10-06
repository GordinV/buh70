'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const ButtonUpload = require('./../../components/upload_button/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');

const styles = require('./nomenclature-register-styles');
const DOC_TYPE_ID = 'NOMENCLATURE';

const DocRights = require('./../../../config/doc_rights');
const checkRights = require('./../../../libs/checkRights');
const DocContext = require('./../../doc-context.js');
let docRights = DocRights[DOC_TYPE_ID] ? DocRights[DOC_TYPE_ID] : [];


/**
 * Класс реализует документ справочника признаков.
 */
class Nomenclatures extends React.PureComponent {
    constructor(props) {
        super(props);
        this.handleClick = this.handleClick.bind(this);
        this.renderer = this.renderer.bind(this);
    }

    render() {
        return <Documents initData={this.props.initData}
                          history={this.props.history ? this.props.history : null}
                          ref='register'
                          module={this.props.module}
                          docTypeId={DOC_TYPE_ID}
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        let userRoles = DocContext.userData ? DocContext.userData.roles : [];

        return (
            <ToolbarContainer>
                {checkRights(userRoles, docRights, 'import') ?
                    <ButtonUpload
                        ref='btnUpload'
                        docTypeId={DOC_TYPE_ID}
                        onClick={this.handleClick}
                        show={true}
                        mimeTypes={'.csv'}
                    /> : null}

            </ToolbarContainer>
        );
    }

    /**
     * кастомный обработчик события клик на кнопку импорта
     */
    handleClick(result) {

        //обновим данные
        const Doc = this.refs['register'];
        if (!Doc) {
            return null;
        }
        if (result) {
            Doc.setState({warning: `Edukalt:  ${result}: `, warningType: 'ok'});
            setTimeout(() => {
                Doc.fetchData('selectDocs');
            }, 10000);
        }
    }


}

module.exports = (Nomenclatures);


