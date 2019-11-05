'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./smk-register-styles');
const DOC_TYPE_ID = 'smk';
const ButtonUpload = require('./../../components/upload_button/index.jsx');
const BtnLogs = require('./../../components/button-register/button_logs/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');


/**
 * Класс реализует документ приходного платежного ордера.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.renderer = this.renderer.bind(this);
        this.handleClick = this.handleClick.bind(this);
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 history={this.props.history ? this.props.history : null}
                                 module={this.props.module}
                                 ref='register'
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer(self) {

        return (
            <ToolbarContainer>
                <ButtonUpload
                    ref='btnUpload'
                    docTypeId={DOC_TYPE_ID}
                    onClick={this.handleClick}
                    show={true}
                />
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
            Doc.fetchData('selectDocs').then((data) => {
                this.forceUpdate();
            },()=> {
                console.error('rejected');
            });

        },1000);
    }
}

module.exports = (Documents);


