'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'AASTA_NAITAJAD';

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
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
                                  render={this.renderer}/>;
            </div>
        )
    }

    renderer() {
        return null;
    }



}


module.exports = (Documents);


