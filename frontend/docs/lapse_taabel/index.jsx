'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./styles');
const DOC_TYPE_ID = 'LAPSE_TAABEL';

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
    }

    render() {
        return (
            <DocumentRegister initData={this.props.initData}
                              userData={this.props.userData}
                              history={this.props.history ? this.props.history : null}
                              module={this.props.module}
                              ref='register'
                              docTypeId={DOC_TYPE_ID}
                              style={styles}
                              render={this.renderer}/>);
    }

    renderer() {
        return <div>Lapse taabel register special render</div>
    }
}


module.exports = (Documents);


