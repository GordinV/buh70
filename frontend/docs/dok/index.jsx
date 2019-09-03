'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./docs-register-styles');
const DOC_TYPE_ID = 'document';

/**
 * Класс реализует справочник документов пользователя.
 */
class Docs extends React.PureComponent {
    constructor(props) {
        super(props);
        this.gridData = props.initData.result.data;
    }

    render() {
        return <Documents initData={this.props.initData}
                          userData={this.props.userData}
                          history = {this.props.history ? this.props.history: null}

                          docTypeId='DOCUMENT'
                          ref = 'register'
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>Docs types register special render</div>
    }

}

module.exports = (Docs);


