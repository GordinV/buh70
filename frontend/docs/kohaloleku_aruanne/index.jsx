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
        this.onClickHandler = this.onClickHandler.bind(this);

    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 history={this.props.history ? this.props.history : null}
                                 gridConfig = {this.props.gridConfig}
                                 module={this.props.module}
                                 ref='register'
                                 toolbarProps={TOOLBAR_PROPS}
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer(self) {
        return (<ToolbarContainer>
                <BtnGetXml
                    value={'Saama CSV fail'}
                    onClick={this.onClickHandler}
                    ref={`btn-getXml`}
                    showDate={false}
                />
            </ToolbarContainer>
        )
    }

    //handler для события клик на кнопках панели
    onClickHandler(event) {
        const Doc = this.refs['register'];

        if (Doc.gridData && Doc.gridData.length) {
            //делаем редайрект на конфигурацию
            let sqlWhere = Doc.state.sqlWhere;
            let url = `/reports/kohaoleku_aruanne/${DocContext.userData.uuid}`;
            let params = encodeURIComponent(`${sqlWhere}`);
            let filter = encodeURIComponent(`${(JSON.stringify(Doc.filterData))}`);
            let fullUrl = sqlWhere ? `${url}/${filter}/${params}`: `${url}/${filter}`;
            window.open(fullUrl);

        } else {
            Doc.setState({
                warning: 'Tulemus 0', // строка извещений
                warningType: 'notValid',

            });
        }
    }


}


module.exports = (Documents);


