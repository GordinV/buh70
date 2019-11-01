'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');
const BtnSettings = require('./../../components/button-register/button-settings/index.jsx');

const styles = require('./arv-register-styles');
const DOC_TYPE_ID = 'ARV';
const DocContext = require('./../../doc-context.js');

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this)
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 history = {this.props.history ? this.props.history: null}
                                 module = {this.props.module}
                                 ref = 'register'
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer(self) {
        return (<ToolbarContainer>
            <BtnSettings
                history={self.props.history ? self.props.history : null}
                onClick={this.onClickHandler}
                ref='btnSettings'
                value='Häälestamine'
            />
        </ToolbarContainer>)
    }

    //handler для события клик на кнопках панели
    onClickHandler () {
        //делаем редайрект на конфигурацию
        this.props.history.push(`/${this.props.module}/config/${DocContext.userData.asutusId}`);
    }
}


module.exports = (Documents);


