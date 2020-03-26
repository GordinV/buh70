'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnGetXml = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'KOHALOLEKU_ARUANNE';
const DocContext = require('./../../doc-context.js');
const TOOLBAR_PROPS = {
    add: false,
    edit: false,
    delete: false,
    start: false,
    print: true,
    email: true
};

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.renderer = this.renderer.bind(this);
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 history={this.props.history ? this.props.history : null}
                                 module={this.props.module}
                                 ref='register'
                                 toolbarProps={TOOLBAR_PROPS}
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer(self) {
        return null
    }

}


module.exports = (Documents);


