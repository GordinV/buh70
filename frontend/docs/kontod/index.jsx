'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./kontod-register.styles');
const DOC_TYPE_ID = 'kontod';

/**
 * Класс реализует документ справочника признаков.
 */
class Kontod extends React.PureComponent {
    constructor(props) {
        super(props);
    }

    render() {
        return <Documents initData={this.props.initData}
                          history = {this.props.history ? this.props.history: null}
                          ref = 'register'
                          docTypeId={DOC_TYPE_ID}
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return null
    }

}

module.exports = (Kontod);


