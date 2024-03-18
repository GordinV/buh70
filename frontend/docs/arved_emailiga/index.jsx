'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./styles');
const DOC_TYPE_ID = 'ARVED_EMAILIGA';
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
class Arved_emailiga extends React.PureComponent {
    constructor(props) {
        super(props);
    }

    render() {
        return <Documents initData={this.props.initData}
                          history={this.props.history ? this.props.history : null}
                          module={this.props.module}
                          ref='register'
                          docTypeId={DOC_TYPE_ID}
                          toolbarProps={TOOLBAR_PROPS}
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return null;
    }
}


module.exports = (Arved_emailiga);


