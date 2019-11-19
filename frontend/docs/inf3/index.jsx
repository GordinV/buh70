'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnGetXml = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'INF3';
const DocContext = require('./../../doc-context.js');

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.renderer = this.renderer.bind(this);
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 history={this.props.history ? this.props.history : null}
                                 module={this.props.module}
                                 ref='register'
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer(self) {
        return (<ToolbarContainer>
                <BtnGetXml
                    value={'Saama XML fail'}
                    onClick={this.onClickHandler}
                    ref={`btn-getXml`}
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
            let url = `/reports/inf3/${DocContext.userData.uuid}`;
            let params = encodeURIComponent(`${sqlWhere}`);
            window.open(`${url}/${params}`);
        } else {
            Doc.setState({
                warning: 'Mitte ühtegi INF teenused leidnum', // строка извещений
                warningType: 'notValid',

            });
        }
    }

}


module.exports = (Documents);


