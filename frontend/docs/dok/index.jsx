'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./docs-register-styles');

/**
 * Класс реализует справочник документов пользователя.
 */
class Docs extends React.PureComponent {
    constructor(props) {
        super(props);
        this.gridData = props.initData.result.data;
    }

    render() {
        const docTypeId = this.props.initData.docTypeId;

        return <Documents initData={this.props.initData}
                          userData={this.props.userData}
                          history={this.props.history ? this.props.history : null}
                          module={this.props.module}
                          docTypeId={docTypeId}
                          ref='register'
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div> register special render</div>
    }

}

module.exports = (Docs);


