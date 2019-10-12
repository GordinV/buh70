'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./asutus-register-styles');
const DOC_TYPE_ID = 'ASUTUSED';


/**
 * Класс реализует документ справочника признаков.
 */
class Asutused extends React.PureComponent {
    constructor(props) {
        super(props);
    }

    render() {
        return <Documents initData={this.props.initData}
                          history = {this.props.history ? this.props.history: null}
                          module={this.props.module}
                          ref = 'register'
                          docTypeId={DOC_TYPE_ID}
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>ASUTUSED register special render</div>
    }

}

module.exports = (Asutused);


