'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'VANEM';
const ButtonUpload = require('./../../components/upload_button/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');


const toolbarParams = {
    btnAdd: {
        show: false,
        disabled: false
    },
    btnEdit: {
        show: true,
        disabled: false
    },
    btnDelete: {
        show: true,
        disabled: false
    },
    btnPrint: {
        show: true,
        disabled: false
    }
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
                                 userData={this.props.userData}
                                 history={this.props.history ? this.props.history : null}
                                 module={this.props.module}
                                 ref='register'
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 toolbarParams={toolbarParams}
                                 render={this.renderer}/>;
    }

    renderer() {
        return (
            <ToolbarContainer>
                <ButtonUpload
                    ref='btnUpload'
                    docTypeId={DOC_TYPE_ID}
                    onClick={this.handleClick}
                    show={true}
                    mimeTypes={'.csv'}
                />

            </ToolbarContainer>
        )
    }

}


module.exports = (Documents);


