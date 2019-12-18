'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./project-register-styles');
const DOC_TYPE_ID = 'project';
/**
 * Класс реализует документ справочника признаков.
 */
class Project extends React.PureComponent {
    constructor(props) {
        super(props);
    }

    render() {
        return <Documents initData={this.props.initData}
                          userData={this.props.userData}
                          history = {this.props.history ? this.props.history: null}
                          ref = 'register'
                          btnEditClick = {this.btnEditClick}
                          docTypeId={DOC_TYPE_ID}
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return null;
    }

}

module.exports = (Project);


